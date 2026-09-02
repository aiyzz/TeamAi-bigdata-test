# 层级汇总验证 SQL 模板

> 验证父级层级 = SUM(子级层级) 的指标汇总是否一致
> 用于 ROLLUP_SUM 类型的 hierarchy_logic

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
| `<指标字段>` | 需要验证的指标 | `son_num, mother_num` |
| `<误差阈值>` | 允许的误差 | `0.01` |
| `<LIMIT>` | 限制行数 | `10` |

---

## SQL 模板

```sql
-- ==============================================================================
-- 验证层级：<父级org_type> = SUM(<子级org_type>)
-- 预期值来源：SUM(org_type IN (<子级org_type>))
-- 实际值来源：org_type='<父级org_type>'
-- ==============================================================================
SELECT
    '<父级org_type>_SUM_METRICS' AS test_case,
    <分组字段_exp>,
    <指标期望值列表>,
    <指标实际值列表>,
    <指标差异列表>
FROM (
    -- 子级聚合（期望值）
    SELECT
        <分组字段>,
        <指标SUM表达式列表>
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
        <指标原始值列表>
    FROM <表名>
    WHERE <时间粒度条件>
        AND org_type = '<父级org_type>'
        <分区条件>
) act
ON <JOIN条件>
WHERE <差异过滤条件>
LIMIT <LIMIT>
```

---

## 生成规则

### 1. 分组字段表达式（分组字段_exp）

```sql
exp.branch_code,
exp.first_tab_type,
exp.second_tab_type,
exp.third_tab_type,
exp.four_tab_type,
exp.sector_name
```

### 2. 指标 SUM 表达式列表（指标SUM表达式列表）

对于每个指标 `metric_code`：
```sql
SUM(CAST(metric_code AS DECIMAL(22,4))) AS metric_code
```

示例：
```sql
SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num
```

### 3. 指标原始值列表（指标原始值列表）

对于每个指标 `metric_code`：
```sql
CAST(metric_code AS DECIMAL(22,4)) AS metric_code
```

### 4. 指标期望值列表（指标期望值列表）

对于每个指标 `metric_code`：
```sql
COALESCE(exp.metric_code, 0) AS expect_metric_code
```

### 5. 指标实际值列表（指标实际值列表）

对于每个指标 `metric_code`：
```sql
COALESCE(act.metric_code, 0) AS actual_metric_code
```

### 6. 指标差异列表（指标差异列表）

对于每个指标 `metric_code`：
```sql
ABS(COALESCE(exp.metric_code, 0) - COALESCE(act.metric_code, 0)) AS diff_metric_code
```

### 7. JOIN 条件（JOIN条件）

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

### 8. 差异过滤条件（差异过滤条件）

对于每个指标 `metric_code`：
```sql
(ABS(COALESCE(exp.metric_code, 0) - COALESCE(act.metric_code, 0)) > <阈值> OR act.metric_code IS NULL)
```

多个条件用 `OR` 连接：
```sql
(ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.01 OR act.son_num IS NULL)
OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.01 OR act.mother_num IS NULL)
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
- 指标：`son_num, mother_num`
- 阈值：`0.01`

**生成的 SQL**：

```sql
-- ==============================================================================
-- 验证层级：BRANCH = SUM(CUSTOMER)
-- 预期值来源：SUM(org_type IN (CUSTOMER))
-- 实际值来源：org_type='BRANCH'
-- ==============================================================================
SELECT
    'BRANCH_SUM_METRICS' AS test_case,
    exp.branch_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    COALESCE(exp.son_num, 0) AS expect_son_num,
    COALESCE(act.son_num, 0) AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.mother_num, 0) AS expect_mother_num,
    COALESCE(act.mother_num, 0) AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num
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
        CAST(son_num AS DECIMAL(22,4)) AS son_num,
        CAST(mother_num AS DECIMAL(22,4)) AS mother_num
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
WHERE (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.01 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.01 OR act.mother_num IS NULL)
LIMIT 10
```

---

## 结果判断

| 结果 | 含义 |
|------|------|
| 返回空 `[]` | ✅ PASS，无差异 |
| 返回数据 | ❌ FAIL，存在差异，记录差异数据 |
