---
name: dataware-sum
description: 数仓汇总验证
---

# 数仓汇总验证

## 触发条件

用户提到以下任一内容时激活本技能：
- 数仓测试、数据审核、汇总验证、汇总一致性
- 明细表聚合验证、汇总表层级校验
- 生成汇总测试 SQL、验证汇总层级
- 表名包含 total / summary / detail 且涉及汇总逻辑

## 能力

- **单表模式**：验证汇总表内部各层级的汇总一致性（如 HEAD 汇总 = SUM(所有 REGION_MANAGE)）
- **双表模式**：验证明细表聚合值与汇总表是否一致，同时验证汇总表内部层级

## 工作流程

> **【强制规则】Step 3 和 Step 4 必须按照模板执行，禁止手写 SQL 或跳过审核。**
>
> 模板位于 `templates/` 目录：
> - `templates/audit/` — 审核检查清单（结构、内容、数据类型）
> - `templates/sql/` — SQL 模板（层级汇总、率值验证、排查查询）
>
> 按照模板逐项检查、替换占位符生成 SQL，确保 GROUP BY 对齐、阈值一致、变量替换等细节。

> **【重要】MCP 工具调用说明**
>
> 本 skill 使用 Claude Code 内置的 MCP 工具执行 SQL 查询，无需手动处理 MCP 协议握手。
> 直接调用 `mcp__mysql-server__mysql_query` 等工具即可，Claude Code 框架会自动处理连接和初始化。

### mysql-server MCP 工具列表

| 工具名称 | 功能说明 |
|----------|----------|
| `mcp__mysql-server__mysql_query` | 执行 SQL 查询并返回结果 |
| `mcp__mysql-server__mysql_paginate_results` | 分页执行查询，处理大型结果集 |
| `mcp__mysql-server__mysql_show_databases` | 获取数据库列表 |
| `mcp__mysql-server__mysql_show_tables` | 获取表列表 |
| `mcp__mysql-server__mysql_show_columns` | 获取表的列信息 |
| `mcp__mysql-server__mysql_show_create_table` | 获取表的创建语句（DDL） |
| `mcp__mysql-server__mysql_show_indexes` | 获取表的索引信息 |
| `mcp__mysql-server__mysql_show_foreign_keys` | 获取表的外键约束信息 |
| `mcp__mysql-server__mysql_show_variables` | 获取 MySQL 系统变量 |
| `mcp__mysql-server__mysql_show_status` | 获取 MySQL 服务器状态 |
| `mcp__mysql-server__mysql_show_table_status` | 获取表状态信息 |

### Step 0: 判断模式

| 用户输入特征 | 模式 |
|-------------|------|
| 只提供一张汇总表 | single_table |
| 提供明细表 + 汇总表 | double_table |
| 无法判断 | 询问用户确认 |

### Step 1: 收集信息

用户可能通过两种方式提供表结构：

**方式 A — 用户直接提供 DDL：**
直接解析用户粘贴的 CREATE TABLE 语句。

**方式 B — 用户提供表名，通过 MCP 查询 DDL：**
当用户只提供表名（如 `bigdata_app.app_sign_delay_total`）时，使用 Claude Code 内置的 MCP 工具查询表结构：

1. 先调用 `mcp__mysql-server__mysql_show_create_table(table="表名", database="库名")` 获取完整 DDL
2. 若不支持则回退到 `mcp__mysql-server__mysql_show_columns(table="表名", database="库名")`
3. 解析返回结果，提取字段名、类型、COMMENT 等信息
4. 将查询到的结构展示给用户确认，再继续后续流程

> **注意：** MCP 查询结果可能不完整（如 COMMENT 截断、分区信息缺失）。解析后需与用户确认关键信息（org_type 枚举、率值公式等），不要盲信查询结果。

---

解析 DDL 后，检查以下信息是否完整，**缺失必须询问用户，不自行猜测**。

> **禁止引用历史配置：** 即使当前工作目录、`configs/` 目录或其他路径下已有同表的旧配置文件、SQL 文件或任何历史记录，也**不得**直接复用其中的公式、枚举值或层级定义。历史数据可能已过时或不准确。所有缺失信息必须逐项向用户确认，用户明确回复后方可写入配置。

**检查项 1 — org_type 枚举值：**

DDL 中 `org_type` 字段的 COMMENT 是否列出了所有枚举值？
- 有枚举 → 直接使用，生成配置前展示给用户确认
- 无枚举 → 必须询问：

> **注意：** 不得从历史配置中提取枚举值，即使存在同表旧配置也必须向用户确认。

```
DDL 中 org_type 字段没有列出枚举值，请提供：
1. org_type 有哪些取值？（如 HEAD、REGION_MANAGE、TRANSFER_CENTER、BRANCH）
2. 每个值对应的层级含义？（如 全国、省区、中心、网点）
```

**检查项 2 — 率值字段的计算公式：**

DDL 中率值字段（如 `delay_rate`、`coverage_rate`）的 COMMENT 是否包含计算公式？
- 有公式 → 直接使用，生成 DERIVED 指标
- 无公式 → 必须询问：

> **注意：** 不得从历史配置中提取公式，即使存在同表旧配置也必须向用户确认每个率值字段的分子和分母。

```
以下率值字段缺少计算公式，请补充：
- 字段名（中文名）：分子是什么？分母是什么？
  示例：delay_vol / sign_vol * 100
```

**检查项 3 — 双表模式额外检查（仅 double_table）：**

| 检查项 | 缺失时询问 |
|--------|-----------|
| JOIN 键 | "两表通过哪些字段关联？" |
| 指标聚合公式 | "汇总表的 X 在明细表中如何计算？（COUNT/SUM/...）" |
| 维度过滤 | "明细和汇总的维度值是否一致？（如明细 2-6，汇总 1-6）" |
| 分组字段 | "汇总表 GROUP BY 哪些字段？" |

**原则：信息不全不生成配置。宁可多问一轮，不要猜着写公式或层级名。**

**铁律：禁止从任何历史文件（configs/、当前目录、其他项目目录中的旧配置或旧 SQL）中提取 org_type 枚举值、率值公式、JOIN 键等信息。所有缺失信息必须逐项询问用户，等用户明确回复后再写入配置。即使用户说"和之前一样"，也要列出具体内容让用户确认。**

### Step 2: 生成 JSON 配置

根据收集的信息生成 JSON 配置。配置结构如下：

```json
{
  "meta_info": {
    "mode": "single_table 或 double_table",
    "table_name": "库名.表名",
    "detail_table_name": "库名.明细表名（双表模式必填）",
    "partition_field": "分区字段名",
    "date_field": "日期字段名",
    "time_field": "时间粒度字段名（如 sum_type）"
  },

  "detail_summary_mapping": {
    "join_keys": ["JOIN 关联字段"],
    "filter_dimensions_join": {
      "维度字段名": {
        "detail_values": ["明细表取值列表"],
        "summary_filter": "汇总表过滤条件 SQL 片段"
      }
    },
    "metric_mapping": [
      {"summary_field": "汇总表指标名", "detail_aggregation": "明细表聚合表达式"}
    ],
    "group_by_mapping": ["分组字段列表"],
    "summary_where": "汇总表额外 WHERE 条件（如 sum_type = 'D'）"
  },

  "dimension_definitions": {
    "org_hierarchy": {
      "order": ["按 org_type 实际枚举值排列，从高到低"],
      "level_field": "org_type",
      "mapping": {"枚举值": "中文含义"}
    },
    "time_granularity": {
      "field": "时间粒度字段",
      "enum_values": ["D", "M"]
    }
  },

  "metric_definitions": [
    {"code": "指标字段名", "name": "中文名", "base_aggregation": "SUM 或 DERIVED", "formula": "DERIVED 时必填", "data_type": "decimal"}
  ],

  "hierarchy_logic": [
    {
      "target_level": "目标层级（org_type 枚举值）",
      "calculation_method": "ROLLUP_SUM 或 COMPARE_DETAIL_SUMMARY",
      "source_definition": {"org_levels": ["子级 org_type 枚举值"]},
      "aggregation_granularity": {"group_by_fields": ["分组字段"]}
    }
  ],

  "diff_threshold": 0.0
}
```

**关键规则：**
- `org_hierarchy.order` 只取 `org_type` 列的实际枚举值，不从 sub_code/emp_code/grid_code 推断
- 双表模式必须同时包含 `detail_summary_mapping` 和 `hierarchy_logic`
- `hierarchy_logic` 中双表模式必须有 `COMPARE_DETAIL_SUMMARY` 条目（最低层级比对）
- `hierarchy_logic` 中每条 ROLLUP_SUM 的 `target_level` 来源是父级，`org_levels` 是直接子级
- `metric_mapping` 中的 `summary_field` 必须在 `metric_definitions` 中存在
- `partition_field` 必须配置，避免扫描全量数据
- **【重要】`group_by_fields` 中的字段必须在各层级值一致**，否则会导致 JOIN 匹配失败，误报为 FAIL

**group_by_fields 字段一致性检查：**

> **铁律：配置 `group_by_fields` 时，必须验证该字段在父子层级的值是否一致。**

常见的不一致字段：
| 字段 | 问题 | 处理方式 |
|------|------|----------|
| brand_name | 父级为空字符串 ''，子级为 '非品牌' | 从 group_by_fields 中排除 |
| sector_name | 父级为空或不同值 | 从 group_by_fields 中排除 |
| 其他维度字段 | 类似问题 | 从 group_by_fields 中排除 |

**处理方式：**
1. **优先修复数据源**：确保各层级的维度字段值一致
2. **次选方案**：从 `group_by_fields` 中排除不一致的字段
3. **测试时处理**：在生成测试 SQL 时，对不一致字段做 COALESCE 或排除

**示例：**
```json
// 错误配置 - brand_name 在各层级不一致
"group_by_fields": ["branch_code", "first_tab_type", "sector_name", "brand_name"]

// 正确配置 - 排除不一致的字段
"group_by_fields": ["branch_code", "first_tab_type", "sector_name"]
```

**层级递推规则（ROLLUP_SUM）：**

假设 org_hierarchy.order = [HEAD, REGION_MANAGE, TRANSFER_CENTER, BRANCH]：

| target_level | source_definition.org_levels | 含义 |
|-------------|----------------------------|------|
| HEAD | [REGION_MANAGE] | HEAD = SUM(REGION_MANAGE 数据) |
| REGION | [TRANSFER_CENTER] | REGION = SUM(TRANSFER_CENTER 数据) |
| CENTER | [BRANCH] | CENTER = SUM(BRANCH 数据) |

BRANCH 是最底层，不需要 ROLLUP_SUM 条目（没有子级可汇总）。

### Step 3: 审核配置

> **铁律：必须按照审核模板逐项检查，禁止跳过审核、禁止人工目测代替审核。**

审核模板位于 `templates/audit/` 目录：
- `structure-check.md` — 结构规范性检查
- `content-check.md` — 内容正确性检查
- `data-type-check.md` — 数据类型一致性检查

**审核流程：**

1. **读取审核模板**：读取 `templates/audit/` 下的三个检查清单
2. **逐项检查**：按照清单逐项检查配置文件
3. **输出审核报告**：记录每项检查的状态（PASS/WARN/FAIL）
4. **判断是否通过**：
   - 有 FAIL → 必须修复后才能继续
   - 只有 WARN → 可继续，但需关注
   - 全部 PASS → 继续下一步

**审核报告格式：**

```
【结构规范性检查】
| 检查项 | 状态 | 说明 |
|--------|------|------|
| meta_info 存在 | ✅ PASS | - |
| table_name 格式正确 | ✅ PASS | nike.xxx |
| ... | ... | ... |

【内容正确性检查】
| 检查项 | 状态 | 说明 |
|--------|------|------|
| metric_definitions code 唯一 | ✅ PASS | - |
| DERIVED 公式变量正确 | ✅ PASS | - |
| ROLLUP_SUM 层级顺序正确 | ✅ PASS | - |
| ... | ... | ... |

【数据类型一致性检查】
| 检查项 | 状态 | 说明 |
|--------|------|------|
| DERIVED 指标有公式 | ✅ PASS | - |
| diff_threshold 合理 | ✅ PASS | 0.0 |

统计：X 项通过 / Y 项警告 / Z 项失败
结论：PASS / PASS_WITH_WARNINGS / FAIL
```

### Step 4: 生成测试 SQL

> **铁律：必须按照 SQL 模板生成，禁止手写 SQL。模板确保了 GROUP BY 对齐、阈值一致、变量替换等细节。**

SQL 模板位于 `templates/sql/` 目录：
- `rollup-sum-check.md` — 层级汇总验证模板
- `derived-rate-check.md` — 率值验证模板
- `detail-query.md` — 下层明细查询模板（排查用）
- `current-level-query.md` — 当前层级查询模板（排查用）

**生成流程：**

1. **读取 SQL 模板**：读取 `templates/sql/` 下的模板文件
2. **提取配置信息**：从 JSON 配置中提取：
   - 表名、分区字段、时间粒度
   - 层级关系（父级、子级）
   - 分组字段（group_by_fields）
   - 指标列表（metric_definitions）
   - 阈值（diff_threshold）
3. **替换占位符**：将模板中的占位符替换为实际值
4. **生成完整 SQL**：输出可直接执行的 SQL

**生成的 SQL 结构：**

对于每个 ROLLUP_SUM 条目，生成 2 个测试用例：
1. **SUM_METRICS** — 验证层级汇总一致性
2. **DERIVED_rate** — 验证率值计算正确性

**示例输出：**

```
生成了 12 个测试用例：

| 用例 | 验证逻辑 |
|------|----------|
| HEAD_SUM_METRICS | HEAD = SUM(REGION_MANAGE) 指标汇总 |
| HEAD_DERIVED_rate | HEAD.rate = son_num/mother_num*100000 |
| REGION_MANAGE_SUM_METRICS | REGION_MANAGE = SUM(TRANSFER_CENTER) 指标汇总 |
| ... | ... |

使用时将 ${bizdate} 替换为实际分区日期（如 20260623）
```

### Step 5: 执行测试 SQL

**默认使用 MCP 自动执行**。仅当 MCP 服务不可用时，回退到手动执行方式。

#### 方式 1：MCP 自动执行（默认）

> **【重要】MCP 工具调用说明**
>
> 本 skill 使用 Claude Code 内置的 MCP 工具执行 SQL 查询，无需手动处理 MCP 协议握手。
> 直接调用 `mcp__mysql-server__mysql_query` 等工具即可，Claude Code 框架会自动处理连接和初始化。

**5.1.1 自动获取分区日期**

自动识别分区字段并查询近 7 天的最大分区日期，无需询问用户：

**分区字段识别规则**：
1. 优先使用配置中的 `partition_field`（通常为 `dt`）
2. 若未配置，从表结构中自动识别：优先 `dt`，其次选择时间类型字段（如 `date`、`datetime`、`timestamp` 类型）

```sql
SELECT MAX(<partition_field>) AS latest_dt
FROM <table_name>
WHERE <partition_field> >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 7 DAY), '%Y%m%d')
  AND <partition_field> <= DATE_FORMAT(CURDATE(), '%Y%m%d')
```

- 若查询成功且返回非空值 → 使用该日期作为分区时间
- 若查询失败或返回空值 → 回退询问用户手动提供分区日期和分区字段

**5.1.2 拆分测试用例**

读取生成的 `.sql` 文件，按 `-- ====` 分隔符拆分为独立的测试用例。每个用例包含：
- 用例名称（从注释中提取，如 `HEAD_SUM_METRICS`）
- 验证逻辑描述（从注释中提取）
- 完整的 SQL 语句

**5.1.3 替换分区变量**

将每个 SQL 中的 `${bizdate}` 替换为实际日期值（如 `'2026-06-14'`）。

**5.1.4 逐个执行并处理错误**

对每个测试用例，直接调用 Claude Code 内置的 MCP 工具执行 SQL：

```
mcp__mysql-server__mysql_query(query="<SQL语句>")
```

**执行后根据返回结果判断：**

**情况 A — 执行成功，返回空结果 `[]`：**
- 标记该用例为 `PASS`（无差异，验证通过）
- 继续下一个用例

**情况 B — 执行成功，返回有数据：**
- 标记该用例为 `FAIL`（存在差异）
- **【重要】完整记录 MCP 返回的所有字段**，包括：
  - 维度字段：org_code（如 branch_code, customer_code 等）
  - 维度分类字段：first_tab_type, second_tab_type, third_tab_type, four_tab_type
  - 其他维度字段：sector_name, brand_name 等
  - 指标字段：expect_*, actual_*, diff_*
- 不要省略任何字段，确保差异数据表格包含完整的上下文信息
- 继续下一个用例

**情况 C — 执行报错：**
- 标记该用例为 `ERROR`
- **自动修复循环**（最多 3 次）：
  1. 阅读错误信息，分析原因（语法错误、字段不存在、表不存在等）
  2. 修改该用例的 SQL
  3. 对修改后的 SQL 重新执行静态审核（确保 GROUP BY、阈值等未被破坏）
  4. 重新调用 `mcp__mysql-server__mysql_query` 执行
  5. 若仍报错，重复 1-4
- 若 3 次修复后仍失败，记录最终错误信息，继续下一个用例

**5.1.5 汇总执行结果**

所有用例执行完毕后，进入 Step 6 生成报告。

#### 方式 2：手动复制 SQL 执行（MCP 不可用时的回退）

当 MCP 服务不可用（连接失败、工具调用报错等）时，自动回退到此方式：

1. 告知用户 MCP 服务不可用，切换到手动执行模式
2. 将生成的 SQL 文件内容展示给用户，并提示：
   - 将 `${bizdate}` 替换为实际日期分区值
   - 在数据库客户端中逐条执行
   - 如果用户后续提供了执行结果，可以帮助分析和生成报告

### Step 6: 生成测试报告

**触发条件：** Step 5 执行完成后自动生成。

> **铁律：报告由模型直接生成，不使用脚本。** 报告必须让用户一眼看出哪里错了。

**报告生成原则：**
1. **总览数据** - 包含表名、模式、分区日期、测试时间、总用例数、通过/失败/出错数量及最终结论
2. **测试结果** - 每个用例的状态汇总（PASS/FAIL/ERROR）
3. **FAIL 用例必须展示对比数据** - 同时展示：
   - **汇总表实际值** (actual) - 当前层级的数据
   - **下层明细期望值** (expect) - 子层级聚合后的数据
   - **差异值** (diff) - 一眼可以看出哪里错了
4. **FAIL 用例必须包含排查 SQL** - 每个 FAIL 用例提供两个可复制执行的 SQL：
   - **SQL 1：查询当前层级实际值** - 看汇总表存了什么
   - **SQL 2：查询下层明细** - 看原始数据，不聚合

**报告结构：**

```markdown
# 数仓汇总验证测试报告

## 配置摘要
| 项目 | 值 |
|------|-----|
| 表名 | xxx |
| 模式 | single_table / double_table |
| 分区字段 | dt |
| 分区日期 | 20260623 |
| 测试时间 | 2026-06-24 |

## 测试总结
| 指标 | 值 |
|------|-----|
| 总用例数 | 12 |
| 通过 | 10 |
| 失败 | 2 |
| 出错 | 0 |
| **最终结论** | **FAIL** |

## 测试用例状态
| 用例名称 | 验证逻辑 | 状态 |
|----------|----------|------|
| HEAD_SUM_METRICS | HEAD = SUM(REGION_MANAGE) | ✅ PASS |
| CUSTOMER_SUM_METRICS | CUSTOMER = SUM(SHOP) | ❌ FAIL |

## FAIL 用例详情

### 1. CUSTOMER_SUM_METRICS
**验证逻辑**: CUSTOMER = SUM(SHOP) 指标汇总

**问题**: 分母(mother_num)存在差异，分子(son_num)一致

**对比数据**:
| customer_code | sector_name | 下层SHOP聚合(expect) | 汇总CUSTOMER(actual) | 差异 |
|---------------|-------------|----------------------|----------------------|------|
| K77230581 | 美妆 | 93,254 | 94,812 | **1,558** |
| K200430621 | 美妆 | 4,576 | 12,747 | **8,171** |

**排查 SQL**:

<details>
<summary>1. 查询 CUSTOMER 实际值（看汇总表存了什么）</summary>

```sql
SELECT
    org_type,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    son_num,
    mother_num,
    rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'CUSTOMER'
    AND dt = '20260623'
    AND customer_code IN ('K77230581', 'K200430621')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, four_tab_type;
```

</details>

<details>
<summary>2. 查询 SHOP 明细（看下层原始数据）</summary>

```sql
SELECT
    org_type,
    shop_code,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    son_num,
    mother_num,
    rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'SHOP'
    AND dt = '20260623'
    AND customer_code IN ('K77230581', 'K200430621')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, shop_code, four_tab_type;
```

</details>
```

**排查 SQL 说明：**

| SQL | 用途 | 说明 |
|-----|------|------|
| SQL 1 | 查询当前层级实际值 | 直接查 `org_type = '当前层级'` 的记录 |
| SQL 2 | 查询下层明细 | 直接查 `org_type = '下层'` 的记录，**不聚合** |

**报告输出路径**: `report/{YYYY-MM-DD}/{table_name}_report.md`

向用户展示报告路径和测试结论。

## 常见错误

1. **org_hierarchy.order 写了 org_type 中不存在的层级**
   → SQL 过滤条件 `org_type = 'XXX'` 匹配不到数据，结果为空

2. **双表模式漏了 summary_where（如 sum_type='D'）**
   → 汇总表返回日/月多套数据，JOIN 产生笛卡尔积

3. **partition_field 缺失**
   → 扫描全表历史数据，性能极差

4. **DERIVED 指标缺 formula**
   → 审核 WARN，SQL 中无法验证该指标

5. **join_keys 不够唯一**
   → 明细聚合后一对多 JOIN，结果数量膨胀

6. **外层查询误用 SUM(exp.xxx)（Hive UDAF 错误）**
   → exp 子查询已通过 GROUP BY + SUM 完成聚合，外层直接引用 `exp.xxx` 即可，**禁止再套 SUM()**
   → 报错信息：`FAILED: SemanticException [Error 10128]: Not yet supported place for UDAF 'SUM'`
   → 正确写法：`COALESCE(exp.col, 0)` 而非 `COALESCE(SUM(exp.col), 0)`

7. **Hive 不支持 NULLIF 函数**
   → 报错信息：`FAILED: SemanticException [Error 10011]: Invalid function 'NULLIF'`
   → 正确写法：用 `CASE WHEN x = 0 THEN NULL ELSE x END` 替代 `NULLIF(x, 0)`
   → 此规则已同步到 `templates/sql/derived-rate-check.md` 模板
