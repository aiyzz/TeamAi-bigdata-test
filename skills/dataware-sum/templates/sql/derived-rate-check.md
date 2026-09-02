# 率值验证 SQL 模板

> 验证 DERIVED 指标（率值）的计算是否正确
> 公式示例：rate = son_num / mother_num * 100000

---

## Hive 兼容性规则（必须遵守）

> 以下规则基于 Hive SQL 方言，确保生成的 SQL 在 Hive/Cloudera 环境下可执行。

| 规则 | 禁止写法 | 正确写法 | 原因 |
|------|----------|----------|------|
| 分母为零保护 | `NULLIF(x, 0)` | `CASE WHEN x = 0 THEN NULL ELSE x END` | Hive 不支持 NULLIF 函数 |
| 外层引用已聚合子查询 | `SUM(exp.col)` | `exp.col` | exp 子查询已做 GROUP BY + SUM，外层套 SUM 会触发 "Not yet supported place for UDAF" 错误 |

---

## 占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<表名>` | 完整表名 | `nike.app_direct_customer_operation_damage` |
| `<分区条件>` | 分区过滤 | `AND dt = '20260623'` |
| `<时间粒度条件>` | 时间粒度过滤 | `AND sum_type = 'D'` |
| `<父级org_type>` | 父级层级 | `BRANCH` |
| `<子级org_type>` | 子级层级 | `CUSTOMER` |
| `<分组字段>` | GROUP BY 字段列表 | `branch_code, first_tab_type, sector_name` |
| `<指标名>` | 率值指标名 | `rate` |
| `<分子字段>` | 公式分子 | `son_num` |
| `<分母字段>` | 公式分母 | `mother_num` |
| `<乘数>` | 公式乘数 | `100000` |
| `<误差阈值>` | 允许的误差 | `0.01` |
| `<LIMIT>` | 限制行数 | `10` |

---

## SQL 模板

```sql
-- ==============================================================================
-- 验证派生指标：<父级org_type>.<指标名> = <公式>
-- 公式展开：<分子字段> / <分母字段> * <乘数>
-- 实际值来源：org_type='<父级org_type>' 的 <指标名> 列
-- ==============================================================================
SELECT
    '<父级org_type>_DERIVED_<指标名>' AS test_case,
    <分组字段_exp>,
    <期望率值表达式> AS expect_<指标名>,
    COALESCE(act.<指标名>, 0) AS actual_<指标名>,
    ABS(<期望率值表达式> - COALESCE(act.<指标名>, 0)) AS diff_<指标名>
FROM (
    -- 子级聚合计算期望值
    SELECT
        <分组字段>,
        <分子SUM表达式>,
        <分母SUM表达式>
    FROM <表名>
    WHERE <时间粒度条件>
        AND org_type = '<子级org_type>'
        <分区条件>
    GROUP BY <分组字段>
) exp
LEFT JOIN (
    -- 父级实际值
    SELECT
        <分组字段>,
        CAST(<指标名> AS DECIMAL(22,4)) AS <指标名>
    FROM <表名>
    WHERE <时间粒度条件>
        AND org_type = '<父级org_type>'
        <分区条件>
) act
ON <JOIN条件>
WHERE ABS(<期望率值表达式> - COALESCE(act.<指标名>, 0)) > <阈值>
    OR act.<指标名> IS NULL
LIMIT <LIMIT>
```

---

## 生成规则

### 1. 期望率值表达式（期望率值表达式）

> **注意：** exp 子查询已通过 GROUP BY + SUM 完成聚合，外层直接引用 `exp.<字段>` 即可，**禁止再套 SUM()**。分母为零保护使用 `CASE WHEN` 而非 `NULLIF`（Hive 不支持）。

```sql
COALESCE(exp.<分子字段>, 0) / CASE WHEN COALESCE(exp.<分母字段>, 0) = 0 THEN NULL ELSE COALESCE(exp.<分母字段>, 0) END * <乘数>
```

示例：
```sql
COALESCE(exp.son_num, 0) / CASE WHEN COALESCE(exp.mother_num, 0) = 0 THEN NULL ELSE COALESCE(exp.mother_num, 0) END * 100000
```

### 2. 分子 SUM 表达式（分子SUM表达式）

```sql
SUM(CAST(<分子字段> AS DECIMAL(22,4))) AS <分子字段>
```

示例：
```sql
SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num
```

### 3. 分母 SUM 表达式（分母SUM表达式）

```sql
SUM(CAST(<分母字段> AS DECIMAL(22,4))) AS <分母字段>
```

示例：
```sql
SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num
```

### 4. 分组字段表达式（分组字段_exp）

```sql
exp.branch_code,
exp.first_tab_type,
exp.second_tab_type,
exp.third_tab_type,
exp.four_tab_type,
exp.sector_name
```

### 5. JOIN 条件（JOIN条件）

对于每个分组字段 `field`：
```sql
exp.field = act.field
```

多个字段用 `AND` 连接：
```sql
exp.branch_code = act.branch_code 
AND exp.first_tab_type = act.first_tab_type 
AND exp.sector_name = act.sector_name
```

---

## 完整示例

**配置信息**：
- 表名：`nike.app_direct_customer_operation_damage`
- 分区：`dt = '20260623'`
- 时间粒度：`sum_type = 'D'`
- 父级：`BRANCH`
- 子级：`CUSTOMER`
- 分组字段：`branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name`
- 率值公式：`rate = son_num / mother_num * 100000`
- 阈值：`0.01`

**生成的 SQL**：

```sql
-- ==============================================================================
-- 验证派生指标：BRANCH.rate = son_num / mother_num * 100000
-- 公式展开：son_num / mother_num * 100000
-- 实际值来源：org_type='BRANCH' 的 rate 列
-- ==============================================================================
SELECT
    'BRANCH_DERIVED_rate' AS test_case,
    exp.branch_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    (COALESCE(exp.son_num, 0) / CASE WHEN COALESCE(exp.mother_num, 0) = 0 THEN NULL ELSE COALESCE(exp.mother_num, 0) END * 100000) AS expect_rate,
    COALESCE(act.rate, 0) AS actual_rate,
    ABS((COALESCE(exp.son_num, 0) / CASE WHEN COALESCE(exp.mother_num, 0) = 0 THEN NULL ELSE COALESCE(exp.mother_num, 0) END * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
    SELECT
        branch_code,
        first_tab_type,
        second_tab_type,
        third_tab_type,
        four_tab_type,
        sector_name,
        SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
        SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num
    FROM nike.app_direct_customer_operation_damage
    WHERE sum_type = 'D'
        AND org_type = 'CUSTOMER'
        AND dt = '20260623'
    GROUP BY branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name
) exp
LEFT JOIN (
    SELECT
        branch_code,
        first_tab_type,
        second_tab_type,
        third_tab_type,
        four_tab_type,
        sector_name,
        CAST(rate AS DECIMAL(22,4)) AS rate
    FROM nike.app_direct_customer_operation_damage
    WHERE sum_type = 'D'
        AND org_type = 'BRANCH'
        AND dt = '20260623'
) act
ON exp.branch_code = act.branch_code 
    AND exp.first_tab_type = act.first_tab_type 
    AND exp.second_tab_type = act.second_tab_type 
    AND exp.third_tab_type = act.third_tab_type 
    AND exp.four_tab_type = act.four_tab_type 
    AND exp.sector_name = act.sector_name
WHERE ABS((COALESCE(exp.son_num, 0) / CASE WHEN COALESCE(exp.mother_num, 0) = 0 THEN NULL ELSE COALESCE(exp.mother_num, 0) END * 100000) - COALESCE(act.rate, 0)) > 0.01
    OR act.rate IS NULL
LIMIT 10
```

---

## 结果判断

| 结果 | 含义 |
|------|------|
| 返回空 `[]` | ✅ PASS，率值计算正确 |
| 返回数据 | ❌ FAIL，率值计算有误，记录差异数据 |
