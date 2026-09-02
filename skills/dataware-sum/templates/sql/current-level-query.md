# 当前层级查询 SQL 模板

> 查询当前层级的实际值，用于排查问题
> 看汇总表里存了什么

---

## 占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<表名>` | 完整表名 | `nike.app_direct_customer_operation_damage` |
| `<分区条件>` | 分区过滤 | `AND dt = '20260623'` |
| `<时间粒度条件>` | 时间粒度过滤 | `AND sum_type = 'D'` |
| `<当前org_type>` | 当前层级 | `BRANCH` |
| `<编码字段>` | 层级编码字段 | `branch_code` |
| `<维度字段>` | 维度过滤字段 | `first_tab_type, second_tab_type, third_tab_type` |
| `<维度值>` | 维度值 | `AND first_tab_type = '3' AND second_tab_type = '3'` |
| `<异常值列表>` | 需要排查的编码值 | `('571932', '769913')` |
| `<指标字段>` | 需要查看的指标 | `son_num, mother_num, rate` |
| `<排序字段>` | 排序字段 | `branch_code, four_tab_type` |
| `<LIMIT>` | 限制行数 | `100` |

---

## SQL 模板

```sql
-- ==============================================================================
-- 查询 <当前org_type> 层级的实际值
-- 用于排查：看汇总表里存了什么
-- ==============================================================================
SELECT
    org_type,
    <编码字段>,
    <维度字段>,
    <指标字段>
FROM <表名>
WHERE <时间粒度条件>
    AND org_type = '<当前org_type>'
    <分区条件>
    AND <编码字段> IN (<异常值列表>)
    <维度值>
ORDER BY <排序字段>
LIMIT <LIMIT>
```

---

## 生成规则

### 1. 维度字段列表

从配置的 `group_by_fields` 中提取，排除 `org_code` 字段：

```sql
first_tab_type,
second_tab_type,
third_tab_type,
four_tab_type,
sector_name
```

### 2. 指标字段列表

从配置的 `metric_definitions` 中提取所有指标：

```sql
son_num,
mother_num,
son_num_ly,
mother_num_ly,
rate
```

### 3. 维度过滤条件

根据实际数据中的维度值生成过滤条件：

```sql
AND first_tab_type = '3'
AND second_tab_type = '3'
AND third_tab_type = '2'
```

---

## 完整示例

**配置信息**：
- 表名：`nike.app_direct_customer_operation_damage`
- 分区：`dt = '20260623'`
- 时间粒度：`sum_type = 'D'`
- 当前层级：`BRANCH`
- 编码字段：`branch_code`
- 异常值：`('571932', '769913', '754905', '319914', '431908', '280912')`
- 维度过滤：`first_tab_type='3', second_tab_type='3', third_tab_type='2'`

**生成的 SQL**：

```sql
-- ==============================================================================
-- 查询 BRANCH 层级的实际值
-- 用于排查：看汇总表里存了什么
-- ==============================================================================
SELECT
    org_type,
    branch_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    son_num,
    mother_num,
    son_num_ly,
    mother_num_ly,
    rate
FROM nike.app_direct_customer_operation_damage
WHERE sum_type = 'D'
    AND org_type = 'BRANCH'
    AND dt = '20260623'
    AND branch_code IN ('571932', '769913', '754905', '319914', '431908', '280912')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY branch_code, four_tab_type
LIMIT 100
```

---

## 使用场景

当测试用例 FAIL 时，使用此模板查询当前层级的实际值：

1. **BRANCH_SUM_METRICS 失败** → 查询 BRANCH 层级的实际值
2. **CUSTOMER_SUM_METRICS 失败** → 查询 CUSTOMER 层级的实际值

查看汇总表里存了什么，与下层明细对比，找出问题所在。
