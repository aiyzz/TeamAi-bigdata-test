---
name: atomic-data-verify
description: 数据仓库 ETL 验数技能，自动识别验证场景并组合原子能力执行。支持生产表对比（能力1-4）和基准表溯源验证（能力6）。触发词：验数、数据验证、ETL验证、比对、数据比对、基准表验证、溯源验证。
---

# 原子数据验证技能

## 目录结构

```
.claude/skills/atomic-data-verify/
├── skill.md                    # 技能主文件（本文件）
├── capabilities/               # 原子能力定义
│   ├── cap-0-quality-check.md
│   ├── cap-1-unchanged-verify.md
│   ├── cap-2-increase-verify.md
│   ├── cap-3-decrease-verify.md
│   ├── cap-4-schema-change-verify.md
│   ├── cap-5-sql-audit.md      # SQL审核能力
│   └── cap-6-base-table-verify.md  # 能力6：基准表溯源验证
├── templates/                  # SQL 模板
│   ├── common/                 # 主流程执行（只执行一次）
│   │   ├── quality-check-sql.md        # 数据质量检查
│   │   ├── diff-rows-count-sql.md      # 差异行统计 → 判断能力2/3
│   │   └── field-structure-compare-sql.md # 字段结构比对 → 判断能力4
│   ├── cap-1-unchanged-verify-sql.md   # 能力1：不变更记录（字段值比对）
│   ├── cap-2-increase-verify-sql.md    # 能力2：增加记录（来源追溯+筛选条件）
│   ├── cap-3-decrease-verify-sql.md    # 能力3：减少记录（剔除逻辑验证）
│   ├── cap-4-schema-change-sql.md      # 能力4：字段增减（结构变更+ETL转换）
│   └── cap-6-base-table-verify-sql.md  # 能力6：基准表溯源验证
├── knowledge/                  # 知识沉淀（分层存储）
│   ├── README.md               # 知识库说明
│   ├── index.md                # 知识索引
│   ├── global/                 # 全局知识（每次都加载）
│   │   ├── sql-patterns.md     # SQL 语法模式
│   │   └── verify-rules.md     # 验数通用规则
│   ├── table/                  # 按表分组（只加载当前表）
│   │   └── {database}.{table}/
│   │       ├── schema.md       # 表结构 + ETL逻辑
│   │       ├── data-patterns.md # 数据规律
│   │       └── lessons.md      # 踩坑记录
│   └── archive/                # 归档区（超过90天的记录）
└── report/                     # 验证报告（按日期归档）
    └── {YYYY-MM-DD}/
        ├── {table_name}_sql_draft.md    # SQL初稿
        ├── {table_name}_sql_audit.md    # SQL审核报告
        └── {table_name}_report.md       # 验证报告
```

> 所有路径均为 skill 目录的相对路径，使用时自动解析为绝对路径。

## 模式说明

本 skill 不区分场景，自动识别所需原子能力并组合执行。

---

## 流程总览

| Step | 说明 | 详情 |
|------|------|------|
| 初始化 | 读取知识沉淀 | 加载历史踩坑记录、SQL模式、数据规律 |
| Step 0 | 收集信息 + 获取表结构 | 建立数仓表列表，获取分区值 |
| Step 1 | 主流程执行 | 执行 `common/` 模板：质量检查 + 数据量统计 + 字段结构比对 |
| Step 2 | 能力判别 | 根据主流程结果 + 需求文档 → 自动识别所需能力 |
| Step 3 | 用户确认 | 展示能力激活清单，用户确认/调整 |
| Step 4 | 生成SQL文档 | 根据激活能力生成SQL初稿，写入 `sql_draft.md` |
| Step 5 | SQL审核 | 调用能力5审核SQL文档，生成 `sql_audit.md` |
| Step 6 | 执行能力 | 按依赖顺序执行各原子能力的专用模板 |
| Step 7 | 生成报告 | 汇总所有能力结果，生成统一报告 |
| Step 8 | 知识沉淀 | 沉淀本次验证的新发现（追加，不重复） |

---

## 初始化：读取知识沉淀

在开始验证前，先读取相关知识沉淀文件，避免重复踩坑：

```bash
# 读取顺序（分层加载）
1. knowledge/global/verify-rules.md    # 全局验数规则（每次都加载）
2. knowledge/global/sql-patterns.md    # SQL语法模式（每次都加载）
3. knowledge/table/{database}.{table}/schema.md      # 当前表结构（如有）
4. knowledge/table/{database}.{table}/data-patterns.md # 当前表数据规律（如有）
5. knowledge/table/{database}.{table}/lessons.md       # 当前表踩坑记录（如有）
```

**加载策略**：
- **全局知识**：每次都加载（verify-rules.md、sql-patterns.md）
- **表级知识**：只加载当前验证的表（schema.md、data-patterns.md、lessons.md）
- **归档知识**：不加载（需要时手动查询 `knowledge/archive/`）

**用途**：
- 执行SQL前检查目标数据库类型，必要时调整语法
- 分析差异时参考历史教训，不轻易判定为错误
- 了解已知的数据规律和ETL逻辑

---

## Step 0: 收集信息 + 获取表结构

### 0.1 用户提供基础信息

| 信息 | 必填 | 说明 |
|------|------|------|
| 生产表名 | 是 | 基准表，如 `ytrpt.kcode_crm_ks_dku` |
| 测试表名 | 是 | 优化/迁移后的表，如 `temp.kcode_crm_ks_dku` |
| 需求文档/ETL代码 | 否 | SQL 文件、需求描述、筛选条件 |
| 上游表 | 否 | 新增数据的来源表 |
| 剔除基准表 | 否 | 用于剔除的来源表 |

**需求文档读取方式**（按优先级）：
1. **用户提供 SQL 文件路径** → 用 Read 工具读取文件内容
2. **用户提供需求描述** → 直接使用文本
3. **用户指向 wiki/文档目录** → 用 Glob 扫描相关文件，Read 读取内容
4. **无文档** → 询问用户口头描述业务场景

**SQL 解析失败 Fallback**：

| 失败场景 | 处理动作 |
|----------|----------|
| SQL 文件读取失败（路径错误/权限不足） | 提示用户重新提供路径，或改为口头描述 |
| SQL 文件过大（>10000行） | 提供关键段落（FROM/JOIN/WHERE），询问用户确认 |
| SQL 结构复杂（多层嵌套/CTE） | 列出识别到的源表和 JOIN 关系，询问用户补充字段映射 |
| 无法识别源表 | 列出 SQL 中所有表名，询问用户指定基准表 |
| 字段映射无法自动提取 | 列出测试表字段，询问用户逐一指定来源（A/B/C/D/E/F） |

### 0.2 获取表结构，建立数仓表列表

按以下顺序获取表结构：

1. **优先从知识库读取**：检查 `knowledge/table/{database}.{table_name}/schema.md` 是否存在
2. **通过 MCP 查询**：调用 `mcp__mysql-server__mysql_show_create_table` 获取 DDL
3. **写入知识库**：将表结构保存为 `knowledge/table/{database}.{table_name}/schema.md`
4. **展示给用户确认**

### 0.3 字段自动分类规则

从 DDL 中提取字段后，按以下规则自动分类为维度/指标/分区：

| 判断条件 | 分类 |
|----------|------|
| COMMENT 包含枚举值描述 | 维度 |
| COMMENT 含"数量""金额""快量""指标""统计""汇总""count""sum""avg" | 指标 |
| 类型为 INT/BIGINT/FLOAT/DECIMAL 且 COMMENT 不含维度关键词 | 指标 |
| 分区字段（dt/rpt_date 等） | 分区 |
| 其余 | 维度 |

> 分类结果写入数仓表列表文件，供质量检查和字段比对使用。

### 0.4 知识库表结构文件格式

每个表一个目录，路径为 `knowledge/table/{database}.{table_name}/`，包含以下文件：

#### schema.md（表结构 + ETL逻辑）

```markdown
# {table_name}

- **表名**：{database}.{table_name}
- **表描述**：{COMMENT 或用户描述}
- **最后更新**：{YYYY-MM-DD}

## 字段列表

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| kcode | varchar(255) | 客户代码 | 维度（主键） |
| taking_num | varchar(255) | 业务量 | 指标 |
| dt | varchar(255) | 分区字段 | 分区 |

## 分区信息

- **分区字段**：dt
- **分区格式**：yyyyMMdd

## 主键

- **主键**：kcode

## ETL 逻辑

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| {source_table} | {join_condition} | {filter_condition} |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| {source_field} | {target_field} | {transform_type} | {transform_logic} |
```

### 0.5 自动识别分区值

```sql
SELECT MAX(dt) AS latest_dt
FROM <测试表>
WHERE dt >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 7 DAY), '%Y%m%d')
  AND dt <= DATE_FORMAT(CURDATE(), '%Y%m%d')
```

若查询成功且返回非空值 → 使用该日期
若查询失败或返回空值 → 询问用户手动提供

---

## Step 1: 主流程执行

> 执行 `templates/common/` 下的 SQL 模板，获取场景判断所需的基础数据。
> 所有 SQL 只执行一次，结果用于 Step 2 的能力判别。

**执行条件**：

| 场景 | 1.1 数据质量 | 1.2 差异行统计 | 1.3 字段结构比对 |
|------|-------------|---------------|-----------------|
| 有生产表 | ✅ 执行 | ✅ 执行 | ✅ 执行 |
| 新增表（能力6） | ✅ 执行（仅测试表） | ⏭️ 跳过 | ⏭️ 跳过 |

> 新增表场景下，1.2/1.3 无生产表可对比，跳过并在报告中标注「新增表场景，跳过此步骤」。

### 1.1 数据质量检查

引用 `templates/common/quality-check-sql.md`，执行：
- 空表前置检查
- 主键唯一性、空值占比
- 维度字段空值占比、分布
- 枚举值分布与占比（含业务含义映射）
- 指标字段空值零值占比、统计分布、范围校验

### 1.2 差异行统计

引用 `templates/common/diff-rows-count-sql.md`，执行：
- 新旧表记录数对比
- 新增条数（测试有、生产没有）
- 减少条数（生产有、测试没有）

**结果用途**：
| 结果 | 判断 |
|------|------|
| added_cnt > 0 | 需激活能力2 |
| removed_cnt > 0 | 需激活能力3 |

### 1.3 字段结构比对

引用 `templates/common/field-structure-compare-sql.md`，执行：
- 字段数量对比
- 新增字段列表（测试表有、生产表没有）
- 删除字段列表（生产表有、测试表没有）

**结果用途**：
| 结果 | 判断 |
|------|------|
| 新增字段数 > 0 | 需激活能力4（D1/D3） |
| 删除字段数 > 0 | 需激活能力4（D2） |

---

## Step 2: 能力判别

### 2.1 Layer 1 — 需求文档分析（优先级最高）

阅读用户提供的需求文档/ETL代码，提取关键词和业务逻辑：

| 需求关键词 | 激活能力 |
|-----------|---------|
| 新增数据来源、扩展、新数据源、增加数据 | 能力2（验证增加记录） |
| 剔除、筛选条件、过滤、减少、移除数据 | 能力3（验证减少记录） |
| 迁移、双写、一致性、比对 | 能力1（验证不变更记录） |
| 增加字段、删除字段、新增列、结构变更 | 能力4（验证字段增减） |
| 优化需求（无明确增减描述） | 能力1 + 能力2（默认组合） |

> 组合场景可同时激活多个能力。

### 2.2 Layer 2 — 主流程结果验证

根据 Step 1 主流程执行结果，修正 Layer 1 的判断：

| 主流程结果 | 修正动作 |
|-----------|---------|
| added_cnt > 0 | 确认激活能力2 |
| removed_cnt > 0 | 确认激活能力3 |
| 新增字段数 > 0 | 确认激活能力4（D1/D3） |
| 删除字段数 > 0 | 确认激活能力4（D2） |
| 与 Layer 1 矛盾 | 提醒用户确认 |

### 2.3 能力激活清单

展示给用户确认：

| 能力 | 激活原因 | 状态 |
|------|----------|------|
| 数据质量检查 | 主流程已执行 | ✅ 已完成 |
| 能力1: 验证不变更记录 | 需求文档 / 优化需求 | ✅ / ⬜ |
| 能力2: 验证增加记录 | 需求文档 / added_cnt > 0 | ✅ / ⬜ |
| 能力3: 验证减少记录 | 需求文档 / removed_cnt > 0 | ✅ / ⬜ |
| 能力4: 验证字段增减 | 需求文档 / 字段差异 | ✅ / ⬜ |
| 能力6: 基准表溯源验证 | 新增表场景 / 需求文档提及基准表 | ✅ / ⬜ |

### 2.4 能力6判别 — 基准表溯源验证

#### 触发条件

满足以下任一条件时激活能力6：
- 新增表场景（无生产表可对比）
- 需求文档中提及基准表（运单操作明细、包操作明细、揽收单号、签收单号等）

#### 自动识别流程

1. 读取需求文档，提取关键词
2. 匹配基准表：

| 关键词 | 基准表 |
|--------|--------|
| 运单操作、走件、拆包 | dwd.operate_waybill_record_dd |
| 包操作、建包 | dwd.operate_pkg_record_dd |
| 揽收、收件 | dwd.waybill_take_waybill_info_dd |
| 签收 | dwd.waybill_sign_waybill_info_dd |
| 派件 | dwd.waybill_sign_waybill_info_dd |
| 轨迹 | dwd.waybill_sign_waybill_track_dd |
| 退回 | dwd.waybill_record_return_dd |

3. 匹配维表筛选条件：

| 业务场景 | 维表 | 筛选条件 |
|----------|------|----------|
| 揽收 | dim.mdm_opcode_info_a | op_code IN ('310','311','313','340') |
| 签收 | dim.mdm_opcode_info_a | op_code IN ('740','741','745','746') |
| 派件 | dim.mdm_opcode_info_a | op_code IN ('710','711') |
| 按中心统计 | dim.t03_user_org_mdm_org | org_type = 'TRANSFER_CENTER' |
| 按分公司统计 | dim.t03_user_org_mdm_org | org_type = 'BRANCH' |
| 按省区统计 | dim.t03_user_org_mdm_org | org_type = 'REGION_MANAGE' |
| 按分部统计 | dim.t03_user_org_mdm_org | org_type = 'SUB_DEPARTMENT' |
| 按片区统计 | dim.t03_user_org_mdm_org | org_type = 'GRID' |

4. 从 ETL 代码提取字段映射，分类为 A/B/C/D/E/F 类

#### 口径判断规则（统一入口）

| 判断依据 | 同口径 | 子集口径 |
|----------|--------|----------|
| 生产表本身就是目标口径（如 dwd.waybill_sign_waybill_info_dd = 签收口径） | ✅ | |
| ETL 代码有 op_code 筛选条件 | | ✅ |
| ETL 代码有 org_type 筛选条件 | | ✅ |
| 测试表名含业务场景词（揽收/签收/派件） | | ✅ |
| 测试表与生产表结构完全一致 | ✅ | |

**口径决定 SQL 模板选择**：
- 同口径 → SQL 模板中的"同口径"版本（无筛选条件）
- 子集口径 → SQL 模板中的"子集口径"版本（带 `<筛选条件>`）

---

## Step 3: 用户确认

### 3.1 确认激活能力

用户可：
1. **确认**自动判别结果
2. **手动激活/关闭**某个能力
3. **补充额外信息**（如剔除条件、上游表等）

### 3.2 ETL 逻辑确认（能力2/4 必填）

当激活能力2（增加记录）或能力4（字段增减）时，需要确认 ETL 逻辑：

#### 3.2.1 源表确认

| 确认项 | 说明 | 示例 |
|--------|------|------|
| 源表名称 | 新增数据的来源表 | `nike.ods_jsc_t_market_direct_customer_dd` |
| 关联键 | 测试表与源表的关联字段 | 测试表.kcode = 源表.k_code |
| 分区字段 | 源表的分区字段 | `dt` |
| 筛选条件 | 从源表筛选数据的条件 | `settle_code LIKE 'ZK%'` |

#### 3.2.2 字段映射确认

| 确认项 | 说明 | 示例 |
|--------|------|------|
| 源字段 | 源表中的字段名 | `sales_emp_code` |
| 目标字段 | 测试表中的字段名 | `sale_emp_code` |
| 转换类型 | 直接映射 / ETL转换 | 直接映射 |
| 转换逻辑 | ETL转换的表达式（如有） | `CASE WHEN status='1' THEN '有效' ELSE '无效' END` |

#### 3.2.3 转换类型说明

| 转换类型 | 说明 | 验证方式 |
|----------|------|----------|
| 直接映射（D1） | 源字段直接赋值给目标字段 | 比对源字段和目标字段值 |
| 条件映射 | 使用 CASE WHEN 转换 | 比对转换表达式结果和目标字段值 |
| 空值填充 | 使用 COALESCE/IF 填充默认值 | 比对填充后结果和目标字段值 |
| 字段拼接 | 使用 CONCAT 拼接多个字段 | 比对拼接结果和目标字段值 |
| 关联取值 | 从维表关联获取值 | 比对维表字段值和目标字段值 |
| 固定值 | 硬编码固定值 | 比对固定值和目标字段值 |

### 3.3 确认输出

将用户确认的 ETL 逻辑记录到知识库的 `knowledge/table/{database}.{table_name}/schema.md`：

```markdown
## ETL 逻辑确认

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| nike.ods_jsc_t_market_direct_customer_dd | 测试表.kcode = 源表.k_code | settle_code LIKE 'ZK%' |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| k_code | kcode | 直接映射 | - |
| sales_emp_code | sale_emp_code | 直接映射 | - |
| sales_emp_name | sale_emp_name | 直接映射 | - |
| customer_classify | first_tab_type | 条件映射 | CASE WHEN customer_classify='BRAND' THEN '1' ELSE '2' END |
```

### 3.4 用户补充/修正

用户可以：
1. **补充源表**：添加遗漏的源表
2. **修正筛选条件**：修改筛选逻辑
3. **补充字段映射**：添加遗漏的字段映射
4. **修正转换逻辑**：修改转换表达式
5. **添加注释**：说明业务逻辑的特殊处理

### 3.5 能力6确认 — 基准表溯源验证

展示溯源分析结果：

| 测试字段 | 分类 | 来源 | 验证方式 |
|----------|------|------|----------|
| waybill_no | A类 | b.waybill_no | 直接比对 |
| org_code | A类 | b.org_code | 直接比对 |
| op_name | B类 | dim.mdm_opcode_info_a.oper_type | 维表关联 |
| org_name | B类 | dim.t03_user_org_mdm_org.org_name | 维表关联 |
| weight_kg | C类 | weight / 1000 | 计算转换 |
| data_source | D类 | 'YTO' | 常量比对 |
| status_name | E类 | CASE WHEN status='1' THEN '有效' ELSE '无效' END | 字典映射 |
| custom_flag | F类 | - | 待用户确认 |

用户确认：
1. **基准表选择**是否正确
2. **维表筛选条件**是否正确
3. **A/B/C/D/E 类字段映射**是否正确
4. **F 类字段**是否需要验证，如需，指定验证表和关联键

---

## Step 4: 生成SQL文档

> 根据激活能力清单和ETL逻辑确认，从模板生成SQL初稿，写入临时文件供审核。

### 4.1 生成流程

1. **读取激活能力清单**：从 Step 3 确定的能力列表
2. **读取ETL逻辑确认**：从 Step 3.2 确认的源表、字段映射、转换逻辑
3. **读取模板文件**：根据激活能力读取对应的 SQL 模板
4. **读取知识库表结构**：从 `knowledge/table/{database}.{table_name}/schema.md` 获取表名、字段名、分区值等信息
5. **生成SQL**：将模板中的占位符替换为实际值
6. **写入文件**：保存到 `report/{YYYY-MM-DD}/{table_name}_sql_draft.md`

### 4.2 SQL文档格式

```markdown
# SQL 初稿

## 基础信息

| 项目 | 内容 |
|------|------|
| 生产表 | {database}.{table_name} |
| 测试表 | {database}.{table_name} |
| 分区值 | {dt_value} |
| 主键 | {primary_key} |
| 激活能力 | 能力0, 能力1, 能力2, ... |

---

## ETL 逻辑确认

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| {source_table} | {join_condition} | {filter_condition} |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| {source_field} | {target_field} | {transform_type} | {transform_logic} |

---

## 主流程 SQL

### 1.1 空表前置检查
```sql
{SQL内容}
```

### 1.2 数据量统计
```sql
{SQL内容}
```

### 1.3 字段结构比对
```sql
{SQL内容}
```

---

## 能力0：数据质量检查 SQL

### 0.1 主键唯一性
```sql
{SQL内容}
```

### 0.2 维度字段空值占比
```sql
{SQL内容}
```

...（其他能力SQL）

---

## 能力1：不变更记录验证 SQL

### 1.1 共同记录数
```sql
{SQL内容}
```

### 1.2 字段比对
```sql
{SQL内容}
```

...（其他能力SQL）

---

## 能力2：增加记录验证 SQL

### 2.1 来源追溯匹配
```sql
{SQL内容}
```

### 2.2 筛选条件符合性
```sql
{SQL内容}
```

...（其他能力SQL）

---

## 能力4：字段增减验证 SQL

### 4.1 原有字段保护
```sql
{SQL内容}
```

### 4.2 新增字段验证（直接映射）
```sql
{SQL内容}
```

### 4.3 新增字段验证（ETL转换）
```sql
{SQL内容}
```

...（其他能力SQL）
```

### 4.3 占位符替换规则

| 占位符 | 替换为 | 来源 |
|--------|--------|------|
| `<测试表>` | `database.table_name` | 知识库 schema.md |
| `<生产表>` | `database.table_name` | 知识库 schema.md |
| `<主键>` | `kcode` | 知识库 schema.md |
| `<分区值>` | `20260614` | Step 0 自动识别 |
| `<field>` | 实际字段名 | 知识库 schema.md 字段列表 |
| `<维度字段列表>` | UNION ALL 所有维度字段 | 知识库 schema.md 字段分类 |
| `<指标字段列表>` | UNION ALL 所有指标字段 | 知识库 schema.md 字段分类 |
| `<共同字段列表>` | UNION ALL 所有共同字段 | 知识库 schema.md 字段比对 |
| `<上游表>` | `database.table_name` | Step 3.2 确认 |
| `<关联键>` | `t.kcode = src.k_code` | Step 3.2 确认 |
| `<筛选条件>` | `settle_code LIKE 'ZK%'` | Step 3.2 确认 |
| `<源字段>` | `sales_emp_code` | Step 3.2 确认 |
| `<目标字段>` | `sale_emp_code` | Step 3.2 确认 |
| `<转换表达式>` | `CASE WHEN ... END` | Step 3.2 确认 |

### 4.4 能力6 SQL 生成

引用 `templates/cap-6-base-table-verify-sql.md`，根据字段分类生成：

- SQL 0：前置检查（容错）
- SQL 1：记录完整性验证（双向）
- SQL 2：A类字段验证（直接映射）
- SQL 3：B类字段验证（维表关联）
- SQL 4：C类字段验证（计算转换）
- SQL 5：D类字段验证（常量）
- SQL 6：E类字段验证（字典映射）
- SQL 7：全字段差异汇总

---

## Step 5: SQL审核

> 调用能力5审核SQL文档，确保所有SQL符合模板规范。
> 审核通过后生成 `sql_audit.md` 文件，作为执行依据。

### 5.1 审核流程

1. **读取SQL初稿**：读取 `report/{YYYY-MM-DD}/{table_name}_sql_draft.md`
2. **读取模板文件**：根据激活能力读取对应的 SQL 模板
3. **逐条审核**：对照模板检查每条SQL的结构
4. **修正偏差**：发现不符合模板的SQL，立即修正
5. **生成审核报告**：写入 `report/{YYYY-MM-DD}/{table_name}_sql_audit.md`

### 5.2 审核内容

引用 `capabilities/cap-5-sql-audit.md`，执行：
- 通用检查（分区条件、表名完整性、主键正确性）
- 能力0检查（空表检查、主键唯一性、维度/指标空值占比）
- 能力1检查（字段比对三段式、批量执行）
- 能力2检查（NOT EXISTS结构、CASE WHEN分组）
- 能力3检查（NOT EXISTS结构、误删排查）
- 能力4检查（三段式NULL处理、NVL(CAST)包裹）
- 主流程检查（LEFT/RIGHT JOIN方向、字段结构比对）

### 5.3 审核输出

生成 `report/{YYYY-MM-DD}/{table_name}_sql_audit.md`：

```markdown
# SQL 审核报告

## 审核概要

| 项目 | 内容 |
|------|------|
| 审核时间 | YYYY-MM-DD |
| 激活能力 | 能力0, 能力1, 能力2, ... |
| 审核SQL数量 | N 条 |
| 通过数量 | M 条 |
| 偏差数量 | K 条 |

---

## 审核结果

| 测试点 | SQL 类型 | 是否遵循模板 | 修正说明 |
|--------|----------|-------------|----------|
| 0.1 | 空表前置检查 | ✅ 是 | - |
| 0.2 | 主键唯一性 | ✅ 是 | - |
| 1.1 | 字段比对 | ❌ 否 | 已修正：补充完整UNION ALL |
| ... | ... | ... | ... |

**审核结论**：全部通过 / 存在 N 处偏差已修正

---

## 审核通过的 SQL

（修正后的完整SQL，按能力分组）
```

### 5.4 审核标准

| 结果 | 状态 | 后续动作 |
|------|------|----------|
| 所有 SQL 符合模板 | ✅ PASS | 继续执行 Step 6 |
| 部分 SQL 存在偏差 | ⚠️ WARN | 修正后继续执行 |
| 关键 SQL 结构错误 | ❌ FAIL | 重新生成SQL初稿 |

---

## Step 6: 执行能力

> 读取审核通过的SQL执行，按依赖顺序执行各原子能力。

### 6.1 执行依据

读取 `report/{YYYY-MM-DD}/{table_name}_sql_audit.md` 中「审核通过的 SQL」章节。

### 6.2 执行顺序

```
能力6（基准表溯源）→ 若激活，独立于其他能力执行
    ↓
能力4（字段增减）→ 若激活，优先于 1/2/3
    ↓
能力1 + 能力2 + 能力3 → 若激活，按序执行
```

**依赖关系**：
- 能力6 独立执行，不依赖其他能力
- 主流程（质量检查 + 数据量统计 + 字段结构比对）已在 Step 1 完成
- 能力4 优先于能力1/2/3（结构变更影响字段比对范围）
- 能力1/2/3 之间无严格依赖，按序执行即可

### 6.3 能力执行

每个能力读取对应的 `capabilities/cap-X-xxx.md` 文件，按其中定义的步骤执行。

**执行方式**：直接执行 `sql_audit.md` 中的SQL，无需再次从模板生成。

---

## Step 7: 生成报告

报告输出到 `report/{YYYY-MM-DD}/{测试表名}_report.md`。

### 7.1 统一报告格式

```markdown
# 数据验证测试报告

## 测试概要
| 项目 | 内容 |
|------|------|
| 生产表 | xxx |
| 测试表 | xxx |
| 测试分区 | dt = xxx |
| 测试时间 | YYYY-MM-DD |
| 激活能力 | 能力0, 能力1, 能力2, ... |

---

## 1. 数据质量校验（能力0）
### 1.1 主键校验
### 1.2 维度字段
### 1.3 指标字段

---

## 2. 数据量变化（能力2/3，若激活）
| 环境 | 记录数 |
|------|--------|

---

## 3. 不变更记录验证（能力1，若激活）
| 字段 | 差异数 | 状态 |

---

## 4. 增加记录验证（能力2，若激活）
- 新增记录数
- 来源追溯结果
- 筛选条件符合性

---

## 5. 减少记录验证（能力3，若激活）
- 被剔除记录数
- 来源追溯结果
- 误删排查结果
- 反向验证结果

---

## 6. 字段增减验证（能力4，若激活）
### 6.1 字段变更清单
### 6.2 原有字段保护
### 6.3 新增字段验证

---

## 7. 基准表溯源验证（能力6，若激活）
### 7.1 前置检查
### 7.2 口径判断
### 7.3 记录完整性验证
### 7.4 字段值验证
### 7.5 F类不可溯源字段

---

## 结论
- [ ] 数据质量合格
- [ ] 不变更记录一致
- [ ] 新增数据来源可追溯
- [ ] 剔除逻辑正确
- [ ] 字段变更正确
- [ ] 基准表溯源验证通过

**判定规则**：
- **数据质量检查**：允许 ⚠️ WARN（如枚举值分布不均）
- **其他检查项**：只要有差异就是 ❌ FAIL（如字段比对、来源追溯、筛选条件等）

**整体结论**：
- 存在任何 ❌ FAIL → **不通过 ❌**
- 仅存在 ⚠️ WARN（仅限数据质量） → **通过（附警告） ✅⚠️**
- 全部 ✅ PASS → **通过 ✅**

---

## SQL 审核

> 详见 `report/{YYYY-MM-DD}/{table_name}_sql_audit.md`

| 测试点 | SQL 类型 | 是否遵循模板 | 修正说明 |
|--------|----------|-------------|----------|
| （从 sql_audit.md 中复制审核结果） |

**审核结论**：全部通过 / 存在 N 处偏差已修正

---

## 验数知识沉淀

---

## 附录

> 详见 `report/{YYYY-MM-DD}/{table_name}_sql_audit.md` 中「审核通过的 SQL」章节

### A. 数据质量校验 SQL
### B. 数据量变化 SQL
### C. 不变更记录验证 SQL
### D. 增加记录验证 SQL
### E. 减少记录验证 SQL
### F. 字段增减验证 SQL
### G. 基准表溯源验证 SQL
```

---

## Step 8: 知识沉淀

本次验证过程中发现的新知识，按分层存储规则写入对应文件：

### 写入位置

| 知识类型 | 写入位置 |
|----------|----------|
| SQL语法问题 | `knowledge/global/sql-patterns.md` |
| 通用验数规则 | `knowledge/global/verify-rules.md` |
| 表结构信息 | `knowledge/table/{db}.{table}/schema.md` |
| 数据规律 | `knowledge/table/{db}.{table}/data-patterns.md` |
| 踩坑记录 | `knowledge/table/{db}.{table}/lessons.md` |

### 沉淀规则

1. **先读取再写入**：写入前先读取现有文件内容
2. **去重检查**：检查新知识是否已存在（按标题和内容相似度）
3. **按状态分类**：已解决/待解决/待验证
4. **追加而非覆盖**：新内容追加到文件末尾，不删除已有内容
5. **更新索引**：更新 `knowledge/index.md`

在报告末尾增加「验数知识沉淀」章节。若无新发现，注明「本次验证无新增知识沉淀」。

---

## MCP 工具说明

本 skill 使用 Claude Code 内置的 MCP 工具执行 SQL 查询，直接调用 `mcp__mysql-server__mysql_query` 等工具即可。

| 工具名称 | 功能说明 |
|----------|----------|
| `mcp__mysql-server__mysql_query` | 执行 SQL 查询并返回结果 |
| `mcp__mysql-server__mysql_paginate_results` | 分页执行查询，处理大型结果集 |
| `mcp__mysql-server__mysql_show_databases` | 获取数据库列表 |
| `mcp__mysql-server__mysql_show_tables` | 获取表列表 |
| `mcp__mysql-server__mysql_show_columns` | 获取表的列信息 |
| `mcp__mysql-server__mysql_show_create_table` | 获取表的创建语句（DDL） |
| `mcp__mysql-server__mysql_show_indexes` | 获取表的索引信息 |

---

## 通用注意事项

- 大表务必加分区条件，避免全表扫描
- 哨兵值 `'XXT'` 应选择业务数据中不会出现的值，避免误判
- NULL 和空字符串统一归一化为 `'XXT'`，避免 `NULL = NULL` 误判为一致
- 临时表使用后及时清理：`DROP TABLE IF EXISTS temp.tmp_xxx`

---

## 异常与边界条件

| 场景 | 触发条件 | 处理动作 |
|------|----------|----------|
| 表不存在 | MCP 查询返回表不存在错误 | 终止验证，提示用户确认表名 |
| 分区无数据 | 测试表/生产表指定分区记录数为 0 | 终止验证，提示用户确认分区值 |
| 主键重复 | 主键唯一性检查发现重复 | 记录重复数，标记为 ❌ FAIL，继续验证 |
| 字段类型不匹配 | 比对字段类型不一致（如 varchar vs int） | 自动 CAST 转换后比对，记录类型差异 |
| SQL 执行超时 | 查询超过 5 分钟无响应 | 终止该 SQL，记录为 ⚠️ TIMEOUT，继续下一个 |
| 维表数据缺失 | 维表关联后匹配率为 0 | 检查维表分区是否存在，提示用户确认 |
| ETL 代码缺失 | 用户未提供 ETL 代码 | 跳过能力6的字段分类，仅执行记录完整性验证 |
| 知识库无表结构 | knowledge/table/ 下无对应 schema.md | 通过 MCP 查询 DDL，自动创建 schema.md |
