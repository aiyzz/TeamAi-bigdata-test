# 下层明细查询 SQL 模板

> 查询下层层级的原始明细数据，用于排查问题
> 不做聚合，直接查看原始记录

---

## 占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<表名>` | 完整表名 | `nike.app_direct_customer_operation_damage` |
| `<分区条件>` | 分区过滤 | `AND dt = '20260623'` |
| `<时间粒度条件>` | 时间粒度过滤 | `AND sum_type = 'D'` |
| `<子级org_type>` | 子级层级 | `CUSTOMER` |
| `<子级编码字段>` | 子级编码字段 | `customer_code` |
| `<父级编码字段>` | 父级编码字段 | `branch_code` |
| `<维度字段>` | 维度过滤字段 | `first_tab_type, second_tab_type, third_tab_type` |
| `<维度值>` | 维度值 | `AND first_tab_type = '3' AND second_tab_type = '3'` |
| `<异常值列表>` | 需要排查的父级编码值 | `('571932', '769913')` |
| `<指标字段>` | 需要查看的指标 | `son_num, mother_num, rate` |
| `<排序字段>` | 排序字段 | `branch_code, customer_code, four_tab_type` |
| `<LIMIT>` | 限制行数 | `100` |

---

## SQL 模板

```sql
-- ==============================================================================
-- 查询 <子级org_type> 层级的原始明细数据
-- 用于排查：看下层原始数据，不做聚合
-- ==============================================================================
SELECT
    org_type,
    <子级编码字段>,
    <父级编码字段>,
    <维度字段>,
    <指标字段>
FROM <表名>
WHERE <时间粒度条件>
    AND org_type = '<子级org_type>'
    <分区条件>
    AND <父级编码字段> IN (<异常值列表>)
    <维度值>
ORDER BY <排序字段>
LIMIT <LIMIT>
```

---

## 生成规则

### 1. 子级编码字段

根据层级关系确定：

| 当前层级 | 子级层级 | 子级编码字段 |
|----------|----------|-------------|
| HEAD | REGION_MANAGE | region_code |
| REGION_MANAGE | TRANSFER_CENTER | center_code |
| TRANSFER_CENTER | GRID_AREA | grid_code |
| GRID_AREA | BRANCH | branch_code |
| BRANCH | CUSTOMER | customer_code |
| CUSTOMER | SHOP | shop_code |

### 2. 父级编码字段

根据层级关系确定：

| 当前层级 | 子级层级 | 父级编码字段 |
|----------|----------|-------------|
| HEAD | REGION_MANAGE | - |
| REGION_MANAGE | TRANSFER_CENTER | region_code |
| TRANSFER_CENTER | GRID_AREA | center_code |
| GRID_AREA | BRANCH | grid_code |
| BRANCH | CUSTOMER | branch_code |
| CUSTOMER | SHOP | customer_code |

### 3. 维度字段列表

从配置的 `group_by_fields` 中提取，排除 `org_code` 字段：

```sql
first_tab_type,
second_tab_type,
third_tab_type,
four_tab_type,
sector_name
```

### 4. 指标字段列表

从配置的 `metric_definitions` 中提取所有指标：

```sql
son_num,
mother_num,
son_num_ly,
mother_num_ly,
rate
```

---

## 完整示例

**配置信息**：
- 表名：`nike.app_direct_customer_operation_damage`
- 分区：`dt = '20260623'`
- 时间粒度：`sum_type = 'D'`
- 子级层级：`CUSTOMER`
- 子级编码字段：`customer_code`
- 父级编码字段：`branch_code`
- 异常值：`('571932', '769913', '754905', '319914', '431908', '280912')`
- 维度过滤：`first_tab_type='3', second_tab_type='3', third_tab_type='2'`

**生成的 SQL**：

```sql
-- ==============================================================================
-- 查询 CUSTOMER 层级的原始明细数据
-- 用于排查：看下层原始数据，不做聚合
-- ==============================================================================
SELECT
    org_type,
    customer_code,
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
    AND org_type = 'CUSTOMER'
    AND dt = '20260623'
    AND branch_code IN ('571932', '769913', '754905', '319914', '431908', '280912')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY branch_code, customer_code, four_tab_type
LIMIT 100
```

---

## 使用场景

当测试用例 FAIL 时，使用此模板查询下层明细数据：

1. **BRANCH_SUM_METRICS 失败** → 查询 CUSTOMER 层级的明细数据
2. **CUSTOMER_SUM_METRICS 失败** → 查询 SHOP 层级的明细数据

查看下层原始数据，与当前层级对比，找出问题所在。

---

## 排查思路

1. **执行当前层级查询** → 看汇总表存了什么
2. **执行下层明细查询** → 看原始数据
3. **对比两者**：
   - 下层有数据，当前层级为空 → 汇总任务未执行
   - 下层有数据，当前层级数据不对 → 汇总逻辑有问题
   - 下层无数据 → 数据源问题
