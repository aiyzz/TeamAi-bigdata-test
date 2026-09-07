---
name: eolinker-case-creator
description: eolinker 驾驶舱自动化用例创建技能。输入 HAR 抓包文件 + 用例名称，自动解析识别三个驾驶舱接口（日期/趋势图/明细列表），调用 addTestCase + addSingleCase 生成含默认断言的用例，再通过「测试任务」统一触发运行、下载报告解析结果并分析，断言修复必须经用户确认后才执行。
triggers:
  - eolinker 创建用例
  - 驾驶舱用例
  - HAR 转用例
  - 创建自动化用例
  - 菜单巡检用例
---

# eolinker 驾驶舱用例创建技能


## 一、已定决策（必须遵守）

| 项 | 决策 | 确认日期 |
|---|---|---|
| 明细列表接口识别 | URL 含 `list`（不区分大小写，正则 `(?i)list`）； | 2026-09-07 |
| 用例 groupID | 默认 **394**（出港运能成本菜单分组），不逐次询问，用户可改 | 2026-09-07 |
| 调试任务 groupID | 固定 **119**（驾驶舱APP 分组，394 建任务报 `200301 no permission`） | 2026-09-07 |
| 调试方式 | **统一走「测试任务」**：addTask({菜单名}-自动调试) → testTask → 轮询结果 → 下载报告 zip 分析 | 2026-09-07 |
| 任务命名 | `{菜单名}-自动调试` | 2026-09-07 |
| 断言修复 | **先分析结果呈现给用户 → 用户确认修复方案 → 才改后置脚本；未确认则不动**（禁止自动删/改断言） | 2026-09-07 |
| 日期断言口径 | **默认严格 T-1，除非用户明确要求否则不擅自放宽**（数据延迟导致的标红是巡检应捕捉的真实信号） | 2026-09-07 |
| 用例位置提示 | 生成后必须告知用户：用例位于「**出港运能成本**」菜单 | 2026-09-07 |
| addSingleCase 语义 | **新增**——每次调用新增一个单用例，返回新 connID；即使带 connID 也会新增（不会覆盖）。⚠️ 无 deleteSingleCase 端点，改断言只能 `deleteTestCase` 整条重建 | 2026-09-07 |
| 请求路径前缀 | 后端用 `/index.php/automatedTest/...`（前端源码写 `/api/automatedTest/...` 但直接调会报 class not found，必须用 index.php 前缀） | 2026-09-07 |

## 三、前置输入

| 输入项 | 必填 | 默认值 |
|---|---|---|
| HAR 文件路径 | 是 | 无 |
| 用例名称 caseName | 是 | Step 3 询问用户 |
| 用例 groupID | 否 | 394 |
| 断言开关 | 否 | 三条默认断言全开 |

## 四、六步工作流

### Step 1：登录拿鉴权信息（必做第一步）

登录接口 `POST /userCenter/common/sso/login`（content-type: application/json），从响应 `data.jwt` 取 Authorization。

请求体（已实测可用，凭据内置）：

```json
{"keepLogin":1,"username":"02004619","type":1,"password":"MAksLAvvCZ7M1fxSaTQtzg==","client":0,"appType":0}
```

附带 header：`Cookie: uvId=<任意uuid>`、`Pragma: no-cache`、`Origin/Referer` 指向 `http://eolinker-tst-inter.yto.net.cn`。

成功响应：`{"success":true,"code":0,"data":{"jwt":"eyJ0eXAi...三段JWT","rjwt":"...","userId":195}}`。

**后续所有 `/index.php/...` 请求统一携带三个 header**：
- `Authorization: <data.jwt>`
- `Pragma: no-cache`
- `Cookie: uvId=<登录时用的 uvId>`

⚠️ Authorization 必须是完整三段 JWT，只给第一段会报 `200001 Wrong number of segments`。

### Step 2：解析 HAR + 识别三个接口 + 预判断言路径

运行脚本：`scripts/parse_har.py <har路径> -o 输出.json`

识别优先级（避免多规则同时命中）：
1. **明细列表**：URL 含 `list`（不区分大小写）
2. **日期接口**：URL 含 `date` / `queryDate` / `latestDate`
3. **趋势图接口**：URL 含 `trend` / `chart` / `series`；不命中时用 `queryLine`（折线）候选取 `data.object2json.ydata[0]`

匹配失败 → 展示候选清单让用户手工指认。

从 HAR 响应体预判三条断言取值路径：
- 日期接口：最新日期字段（如 `data.object2json.date`，可能是单值非数组）。**并解析日期接口 body 的 `sumType`**：`D`=日数据（断言最新日期=T-1）、`M`=月数据（断言最新月份=当月，返回 `"yyyy-MM"`）
- 趋势图接口：`data.object2json.xdata` + `data.object2json.ydata[0]`（数值数组，非对象数组，注意与模板不同）
- 明细列表接口：列表路径 + `orgName` 字段（如 `data.object2json.tbody`）

### Step 2.5：参数化识别与变量引用（参考 cockpit-menu-test-generator）

HAR 内容 = **所有 tab 组合之后的接口**：同一接口会被多次调用，每次携带不同 tab 参数。据此识别参数化字段。

**识别规则**（对比同一接口多次调用的 body 参数差异）：
- 取值**不同**的字段 → 参数化字段，枚举值 = 各次调用的取值（`param_variations`）
- 取值**相同**的字段 → 固定值，保持原样
- 业务约束自动配对：

| 约束 | 说明 |
|---|---|
| sumType=D → queryType=date | 日汇总搭配日维度 |
| sumType=M → queryType=month | 月汇总搭配月维度 |
| sumType=Y → queryType=year | 年度汇总搭配年维度 |

**参数化变量引用规则（关键，写进 caseData.raw）**：

| 字段 | 引用方式 | 说明 |
|---|---|---|
| `queryDate` | **`{{date}}`**（唯一特例） | eolinker 平台内置动态日期变量，巡检时自动取最新日期 |
| 其他参数化字段（`sumType`/`queryType`/`firstTabType`/`trendType`…） | **`$dc{变量名}`** | eolinker 数据集（data collection）变量，变量名取字段名 |

> 示例：HAR 里日期接口被调用 3 次（sumType=D/M/Y），则 caseData.raw 中 `"sumType":"D"` → `"sumType":"$dc{sumType}"`，`"queryDate":"2026-09-05"` → `"queryDate":"{{date}}"`。脚本 `scripts/parse_har.py` 自动输出 `param_variations`，`scripts/create_case.py` 建案时按上述规则替换。

**参数化文件（数据集 CSV）需保留**：建案时同步生成 `<caseName>_dataset.csv`，供导入 eolinker 数据集。格式：

- 表头：`数据集名称,数据集标签,` + 各变化字段 `$dc{字段名}`（字段按 `sumType`/`queryType`/`secondTabType`/`sortColumn` 优先，其余变化字段追加）
- 数据行：每个唯一参数组合一行，`数据集名称 = {维度中文}--{菜单名}`（维度映射 D→日 / M→月 / Y→年，或 date→日 / month→月 / year→年）

```
数据集名称,数据集标签,$dc{sumType},$dc{queryType},$dc{secondTabType},$dc{sortColumn}
日--出港成本,,D,date,1,totalCost
月--出港成本,,M,month,1,totalCost
年--出港成本,,Y,year,1,totalCost
```

> 脚本 `scripts/create_case.py` 用 UTF-8 BOM 写 CSV（Excel 可直接打开不乱码），并打印生成的数据集数量。

### Step 3：addTestCase 取 caseID

`POST /index.php/automatedTest/AutomatedTestCase/addTestCase`（form-data，含三个鉴权 header）。参数模板见 `references/api-templates.md`。caseName 询问用户，groupID 默认 394。

**从返回体 `{"type":"automatedTestCase","statusCode":"000000","caseID":"16446"}` 提取 `caseID`**。

### Step 4：addSingleCase × 3（按序，一次性带断言）

顺序固定：① 日期接口 → ② 趋势图接口 → ③ 明细列表接口。

`POST /index.php/automatedTest/AutomatedTestCaseSingle/addSingleCase`（form-data）。外层参数固定模板见 `references/api-templates.md`，caseData 构造见 `references/har-mapping.md`。

> ⚠️ 每个单用例只调一次（新增语义，返回 connID）。afterScriptList 首次创建即注入（脚本见 `references/assert-scripts.md`，路径按 Step 2 预判替换，注意趋势图 ydata 是「数组套数组」需取 `[0]`）。

### Step 5：统一测试任务调试 + 结果分析

**5.1 建调试任务**（`POST /index.php/automatedTest/AutomatedTestTask/addTask`，form-data）：

| 字段 | 取值 |
|---|---|
| taskName | `{菜单名}-自动调试` |
| groupID | `119`（394 无权限） |
| envID | `80`（生产 GPT预生产） |
| caseFilter | `3`（指定用例） |
| caseID | `caseID[0][caseID]=<caseID>` + `caseID[0][retries]=1`（**对象数组**，否则 `100012` 类型错误） |
| taskTime | `taskTime[]=10:00`（HH:MM 格式） |
| retrySetting | JSON 串 `{"enable":false,"times":3,"interval":10000}` |

成功返回 `{"type":"automatedTestTaskGroup","statusCode":"000000","taskID":255}`。

**5.2 触发运行**：`POST /index.php/automatedTest/AutomatedTestTask/testTask`（spaceKey + projectHashKey + taskID）。

**5.3 轮询结果**：`POST /index.php/automatedTest/AutomatedTestTask/getTaskList`（pageNo/limit），找对应 taskID 的 `testStatus`（success/error）与 `testResult`（1/2）。约 5~30s 出结果。

**5.4 定位报告**：V2 open API（header `eo-secret-key` + `Authorization: Basic aGFjOkYqWENIQ3dW`）：
- `POST /v2/api_studio/automated_test/report/search`（form-data：project_id、space_id、report_type=timed_task、start_time/end_time）→ 找本任务时间的 `report_id`
- `POST /v2/api_studio/automated_test/report/get`（report_id、report_type）→ `failure_case_list`、`single_case_num`/`success_single_case_num`/`failure_single_case_num`

**5.5 下载报告包分析单用例错误**：`report_download_url`（内网 `http://10.130.10.230/...zip`，本机可达）解压：
- `data/caseSurveyList.js`：每步 `reportStatus`（success / codeError）
- `data/scene/0/0.js`：每步 `errorList[].errorMessage`（含断言错误原文）

**5.6 结果分析 → 用户确认后才修复**：将「哪个单用例失败 + 失败原因（请求错误/断言路径错/数据延迟等）」呈现给用户，提出修复建议，**用户确认后再改后置脚本**；未确认则保持不动。改断言需 `deleteTestCase` 整条重建（无单步删除端点）。

**5.7 清理临时任务（必做，无论成功/失败都要执行）**：`POST /index.php/automatedTest/AutomatedTestTask/deleteTask`（spaceKey + projectHashKey + **`taskID[]=<taskID>`**，数组形式，否则 `100400 参数错误`）。调试结束后立即删除「{菜单名}-自动调试」任务，避免其按 taskTime 每日定时触发、污染报告。

### Step 6：汇总报告 + 位置提示

- 输出汇总表 + 必输位置提示：

> ✅ 用例「{caseName}」已生成至 eolinker 自动化测试 → **出港运能成本**菜单（分组 ID：394），包含 3 个单用例（日期接口 / 趋势图接口 / 明细列表接口）。

## 五、默认断言（首建即注入）

| 接口 | 断言规则 | 实现要点 |
|---|---|---|
| 日期接口 | 最新日期 = T-1 | `new Date()` 动态计算昨天；`eo.assert` 不可用则降级 `throw`。**注意**：若数据存在 1 天延迟（如周末不产出），会误报——此时按 5.6 让用户决定是否放宽为 `>= T-2` |
| 趋势图接口 | 数据非空且非全 0 | 取 `ydata[0]`（数值数组）做 `length>0` + `some(v => Number(v)!==0)` |
| 明细列表 | orgName 不重复 | `eo.userFunction.getListRepetitionAssert(resp, "orgName")`（平台内置，已验证） |

完整脚本见 `references/assert-scripts.md`。

## 六、异常处理

| 场景 | 处理 |
|---|---|
| 登录返回非 200 或 jwt 缺段 | 检查凭据/网络，重新登录 |
| Authorization 只有一段 JWT | 报 `200001 Wrong number of segments`，取 `data.jwt` 完整值 |
| `/api/` 前缀报 class not found | 改用 `/index.php/automatedTest/...` 前缀 |
| addTask 报 `100012 类型错误` | caseID 必须 `caseID[i][caseID]`/`caseID[i][retries]` 对象数组；taskTime 必须 HH:MM |
| addTask 报 `200301 no permission` | groupID 394 无建任务权限，改用 119 |
| 报告解析 | 优先 zip（含单用例错误原文）；V2 report/get 只有用例级统计 |
| 报告未生成 | 运行刚结束 report/search 可能查不到，**等 5~10s 重试**；匹配时按报告时间落在任务触发时间之后来定位 |
| 断言修复 | 无 deleteSingleCase 端点，整条 deleteTestCase 重建；且必须经用户确认 |
| eo.assert 不可用 | 降级 `throw new Error(...)`；明细列表断言直接可用 |

## 附：参考文件

- `references/api-templates.md` — addTestCase / addSingleCase / addTask 完整参数模板
- `references/assert-scripts.md` — 三个默认断言脚本
- `references/har-mapping.md` — HAR → caseData 字段映射表
- `scripts/parse_har.py` — HAR 解析 + 接口识别 + caseData 构造
- `scripts/login.py` — Step 1 登录拿 JWT
- `scripts/create_case.py` — addTestCase + addSingleCase ×3
- `scripts/run_debug.py` — 测试任务调试（addTask→testTask→轮询）
