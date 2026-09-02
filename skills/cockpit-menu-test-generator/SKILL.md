---
name: "cockpit-menu-test-generator"
description: "从 HAR 录制文件自动解析接口并生成 HttpRunner 测试脚本。当用户说'生成测试脚本'、'从HAR生成测试'、'xxx菜单测试'时触发。"
---

# 驾驶舱菜单测试生成器

从 HAR 录制文件自动解析接口信息，生成 HttpRunner 测试脚本。

## 设计原则

1. **HAR 唯一输入源**：只接受 HAR 文件作为输入，不支持手动输入接口地址和参数
2. **大文件预处理**：HAR 文件过大时先提取摘要，再由模型读取
3. **自动参数化识别**：分析同一接口的多次调用，相同参数取值不同 → 需要参数化
4. **分步生成**：日期 → 趋势图 → 列表明细，每步调试通过后再继续

---

## 执行流程

### 步骤 1：获取 HAR 文件

使用 AskUserQuestion 询问：

```
请提供 HAR 录制文件路径：
- 直接输入文件路径（如 D:\Documents\xxx.har）
```

**只接受 `.har` 文件，不接受接口地址+参数的手动输入。**

### 步骤 2：预处理 HAR 文件

**目的**：HAR 文件通常几 MB，包含大量静态资源和无关请求，需先提取摘要。

**执行方式**：运行预处理脚本生成精简摘要。

```bash
python "~/.trae-cn/skills/cockpit-menu-test-generator/har_parser.py" "<har文件路径>"
```

脚本会：
1. 过滤掉静态资源（.js/.css/.png 等）
2. 过滤掉 OPTIONS/GET 请求，只保留 POST
3. 过滤掉监控类接口（health/actuator 等）
4. 提取每个接口的关键信息（路径、请求体、响应体）
5. **分析同一接口多次调用的参数差异**
6. 输出 `<har文件名>_summary.json`（几 KB）

**输出示例**：
```
总请求数: 38 → 过滤后: 13 → 接口数: 4

接口列表:
  1. [POST] /api-brc/.../queryList (调用6次)
     参数变化: queryType[date/month/year], firstTabType[1/2/3/4]
  2. [POST] /api-expj/.../queryDateByType (调用3次)
     参数变化: sumType[D/M/Y]
  3. [POST] /api-brc/.../queryLine (调用3次)
     参数变化: queryType[date/month/year]
```

### 步骤 3：读取摘要并解析接口

使用 Read 工具读取生成的 `_summary.json` 文件。

摘要文件结构：
```json
{
  "page_title": "页面标题",
  "api_count": 4,
  "apis": [
    {
      "path": "/api-xxx/xxx",
      "method": "POST",
      "call_count": 6,
      "param_variations": {
        "queryType": {"unique_values": ["date", "month", "year"], "count": 3},
        "firstTabType": {"unique_values": ["1", "2", "3", "4"], "count": 4}
      },
      "sample_request": {...},
      "sample_response": {...}
    }
  ]
}
```

#### 3.1 智能识别接口类型

| 接口类型 | 识别特征 |
|----------|----------|
| 日期查询 | 路径含 `date/latestDate/queryDate`，或参数含 `queryDate` 且无分页参数 |
| 趋势图 | 路径含 `line/trend/chart/echarts`，或参数含 `trendType` |
| 明细列表 | 参数含 `pageNo/pageNum/pageSize/limit`，或路径含 `list/page/query` |
| 其他 | 标记为"未知"，询问用户处理方式 |

#### 3.2 自动参数化识别（核心）

**识别规则**：从摘要的 `param_variations` 字段直接获取。

- `param_variations` 中列出的字段 = 需要参数化的字段
- `unique_values` = 该字段的枚举值
- 未列出的字段 = 固定值，不需要参数化

**业务约束自动配对**：

| 约束规则 | 说明 |
|----------|------|
| sumType=D → queryType=date | 日汇总搭配日维度 |
| sumType=M → queryType=month | 月汇总搭配月维度 |
| sumType=Y → queryType=year | 年度汇总搭配年维度 |

#### 3.3 推断菜单名

- 从 `page_title` 中的 `menuName` 参数提取
- 提取失败时询问用户输入菜单名（中文名 + 英文目录名）

### 步骤 4：展示解析结果

```
已解析 HAR 文件，识别到以下信息：

📁 菜单名称：重复上报率
   英文目录：repeat_report_rate

📡 接口列表（3个）：

| # | 接口类型 | 接口路径 | 调用次数 | 参数化字段 |
|---|----------|----------|----------|------------|
| 1 | 日期查询 | /api-expj/.../queryDateByType | 3 | sumType[D/M/Y] |
| 2 | 趋势图 | /api-brc/.../queryLine | 3 | queryType[date/month/year] |
| 3 | 明细列表 | /api-brc/.../queryList | 6 | queryType, firstTabType[1/2/3/4] |

🔄 参数化策略：
- sumType 与 queryType 自动配对（D→date, M→month, Y→year）
- firstTabType 取全部值 [1, 2, 3, 4]
- 预计生成：日期 3 个 + 趋势图 3 个 + 列表 12 个 = 18 个用例
```

### 步骤 5：确认参数化策略

使用 AskUserQuestion 让用户选择：

```
【方案一：自动模式】（推荐）
- 根据 HAR 自动识别所有参数化字段及其枚举值
- 日/月/年维度自动配对
- 其他字段取全部值的笛卡尔积
- 预计生成 18 个测试组合

【方案二：手动模式】
- 自定义需要参数化的字段和值

【方案三：仅默认值】
- 不参数化，每个接口只生成1个用例
```

### 步骤 6：分步生成（核心流程）

**按顺序逐步生成，每步调试通过后再继续下一步：**

#### 第一轮：日期接口

1. **生成文件**：
   - `api_<菜单名>_date.py` — 日期接口封装
   - `test_<菜单名>_date.py` — 日期测试脚本
   - `<菜单名>_date_params.csv` — 参数化文件

2. **立即调试**：
   ```bash
   pytest testcases/cockpit/<菜单名>/test_<菜单名>_date.py --alluredir=reports/allure-results -v
   ```

3. **修复问题**（最多 3 轮）：
   - 第 1 轮：语法错误、导入错误、路径错误
   - 第 2 轮：变量未定义、接口路径错误、参数缺失
   - 第 3 轮：断言逻辑、数据提取路径

4. **确认通过**后进入下一轮

#### 第二轮：趋势图接口

1. 生成 `test_<菜单名>_trend.py` + 参数化文件
2. 立即调试（同上）
3. 确认通过后进入下一轮

#### 第三轮：列表明细接口

1. 生成 `test_<菜单名>_list.py` + 参数化文件
2. 立即调试（同上）
3. 确认通过后输出最终结果

### 步骤 7：输出最终结果

- 生成的文件列表
- 每轮测试执行结果
- Allure 报告路径
- 运行命令

---

## 断言规则

### 日期接口
```python
.assert_equal("body.data.object2json.date", "$expected_date")
```

### 趋势图接口
```python
.assert_equal("${check_no_zero_values($ydata)}", True, "响应列表不应包含0值")
```

### 明细列表接口

**注意：HttpRunner 表达式解析器无法处理带引号的字符串参数，必须使用变量引用方式。**

```python
# config 中定义断言变量
.variables(**{
    "assert_field": "orgName",
    "metrics_field": ["problemNum"]
})

# validate 中使用变量引用
.assert_equal("${check_org_unique($tbody, $assert_field)}", True, "orgName存在重复")
.assert_equal("${check_global_sum($tbody, $assert_field, $metrics_field)}", True, "全国指标不等于省区合计")
```

**debugtalk.py 中的通用断言函数：**

| 函数 | 功能 |
|------|------|
| `check_org_unique(tbody, assert_field)` | 检查组织名称不重复 |
| `check_global_sum(tbody, org_field, metrics_field)` | 检查全国指标等于省区合计 |
| `check_no_zero_values(data)` | 检查列表不包含0值 |

---

## 公共变量

token 通过 `debugtalk.py` 中的 `get_token()` 函数统一获取：

```python
"token": "${get_token()}",
"orgCode": "999999",
"orgName": "国内事业部",
"orgType": "REGION_MANAGE",
"dataType": "HEAD",
"userOrgCode": "999999",
"userOrgType": "HEAD"
```

---

## 模板文件

模板文件存放在 skill 目录下的 `template/` 文件夹中：

| 模板文件 | 生成文件 |
|----------|----------|
| `template/__init__.py` | `__init__.py` |
| `template/api_date.py` | `api_<菜单名>_date.py` |
| `template/test_date.py` | `test_<菜单名>_date.py` |
| `template/test_trend.py` | `test_<菜单名>_trend.py` |
| `template/test_list.py` | `test_<菜单名>_list.py` |
| `template/date_params.csv` | `<菜单名>_date_params.csv` |
| `template/trend_params.csv` | `<菜单名>_trend_params.csv` |
| `template/list_params.csv` | `<菜单名>_list_params.csv` |

---

## 触发条件

**中文：**
- "生成测试脚本"
- "从HAR生成测试"
- "xxx菜单测试"
- "生成驾驶舱测试"

**英文：**
- "generate test from har"
- "create menu test"
