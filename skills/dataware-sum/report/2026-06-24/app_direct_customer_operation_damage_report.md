# 数仓汇总验证测试报告

## 配置摘要

| 项目 | 值 |
|------|-----|
| 表名 | nike.app_direct_customer_operation_damage |
| 模式 | single_table |
| 分区字段 | dt |
| 分区日期 | 20260623 |
| 时间粒度 | sum_type (D=日) |
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
| HEAD_DERIVED_rate | HEAD.rate = son_num/mother_num*100000 | ✅ PASS |
| REGION_MANAGE_SUM_METRICS | REGION_MANAGE = SUM(TRANSFER_CENTER) | ✅ PASS |
| REGION_MANAGE_DERIVED_rate | REGION_MANAGE.rate = son_num/mother_num*100000 | ✅ PASS |
| TRANSFER_CENTER_SUM_METRICS | TRANSFER_CENTER = SUM(GRID_AREA) | ✅ PASS |
| TRANSFER_CENTER_DERIVED_rate | TRANSFER_CENTER.rate = son_num/mother_num*100000 | ✅ PASS |
| GRID_AREA_SUM_METRICS | GRID_AREA = SUM(BRANCH) | ✅ PASS |
| GRID_AREA_DERIVED_rate | GRID_AREA.rate = son_num/mother_num*100000 | ✅ PASS |
| BRANCH_SUM_METRICS | BRANCH = SUM(CUSTOMER) | ✅ PASS |
| BRANCH_DERIVED_rate | BRANCH.rate = son_num/mother_num*100000 | ✅ PASS |
| CUSTOMER_SUM_METRICS | CUSTOMER = SUM(SHOP) | ❌ FAIL |
| CUSTOMER_DERIVED_rate | CUSTOMER.rate = son_num/mother_num*100000 | ❌ FAIL |

---

## ⚠️ 数据质量问题：brand_name 不一致

**发现**: 不同层级的 `brand_name` 字段值不一致

| 层级 | brand_name 示例 |
|------|-----------------|
| BRANCH | '' (空字符串) |
| CUSTOMER | '非品牌' |

**影响**: 测试 SQL 的 JOIN 条件如果包含 `brand_name`，会导致匹配失败，误报为 FAIL

**建议**: 
1. 检查数据源，确保各层级 `brand_name` 一致
2. 或者在配置中将 `brand_name` 从 `group_by_fields` 中排除

---

## FAIL 用例详情

### 1. CUSTOMER_SUM_METRICS

**验证逻辑**: CUSTOMER = SUM(SHOP) 指标汇总

**问题**: 分母(mother_num)存在差异，分子(son_num)一致

**对比数据**:

| customer_code | sector_name | 下层SHOP聚合(expect) | 汇总CUSTOMER(actual) | 差异 |
|---------------|-------------|----------------------|----------------------|------|
| K77230581 | 美妆 | 93,254 | 94,812 | **1,558** |
| K200430621 | 美妆 | 4,576 | 12,747 | **8,171** |
| K53644255 | 宠物用品 | 2,861 | 3,925 | **1,064** |
| K576105332 | 仪器设备 | 760 | 1,362 | **602** |
| K220146595 | 家具 | 3,328 | 3,765 | **437** |
| K57375768 | 菜鸟 | 15,308 | 15,702 | **394** |
| K35159561 | 水饮 | 8,404 | 8,690 | **286** |
| K576113564 | 仪器设备 | 505 | 768 | **263** |
| K371117844 | 装修建材 | 638 | 854 | **216** |
| K31185123 | 园艺 | 340 | 912 | **572** |

**排查 SQL**:

<details>
<summary>1. 查询 CUSTOMER 实际值（看汇总表存了什么）</summary>

```sql
-- 查询 CUSTOMER 层级的实际值
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
    AND customer_code IN ('K77230581', 'K200430621', 'K53644255', 'K576105332', 'K220146595')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, four_tab_type;
```

</details>

<details>
<summary>2. 查询 SHOP 明细（看下层原始数据）</summary>

```sql
-- 查询 SHOP 层级的原始明细数据
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
    AND customer_code IN ('K77230581', 'K200430621', 'K53644255', 'K576105332', 'K220146595')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, shop_code, four_tab_type;
```

</details>

<details>
<summary>3. 聚合 SHOP 数据对比</summary>

```sql
-- 聚合 SHOP 数据，与 CUSTOMER 对比
SELECT
    customer_code,
    sector_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS shop_son_sum,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS shop_mother_sum
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'SHOP'
    AND dt = '20260623'
    AND customer_code IN ('K77230581', 'K200430621', 'K53644255', 'K576105332', 'K220146595')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
GROUP BY customer_code, sector_name
ORDER BY customer_code;
```

</details>

---

### 2. CUSTOMER_DERIVED_rate

**验证逻辑**: CUSTOMER.rate = son_num/mother_num*100000

**问题**: 由于分母差异导致率值计算结果不一致

**对比数据**:

| customer_code | sector_name | SHOP聚合率值(expect) | CUSTOMER实际率值(actual) | 差异 |
|---------------|-------------|----------------------|--------------------------|------|
| K576113564 | 仪器设备 | 1980.20 | 1302.08 | **678.12** |
| K576105332 | 仪器设备 | 1315.79 | 734.21 | **581.58** |
| K53644255 | 宠物用品 | 1502.97 | 1095.54 | **407.43** |
| K200430621 | 美妆 | 480.77 | 172.59 | **308.18** |
| K220146595 | 家具 | 2013.22 | 1779.55 | **233.67** |
| K35159561 | 水饮 | 1285.10 | 1242.81 | **42.29** |
| K57375768 | 菜鸟 | 235.17 | 229.27 | **5.90** |
| K77230581 | 美妆 | 176.94 | 174.03 | **2.91** |
| K100557249 | 宠物用品 | 425.34 | 411.08 | **14.26** |
| K531104953 | 米面粮油 | 188.90 | 188.81 | **0.09** |

**排查 SQL**:

<details>
<summary>1. 查询 CUSTOMER 率值实际值</summary>

```sql
-- 查询 CUSTOMER 层级的率值
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
    AND customer_code IN ('K35159561', 'K220146595', 'K53644255', 'K200430621', 'K576105332')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, four_tab_type;
```

</details>

<details>
<summary>2. 查询 SHOP 明细（计算期望率值）</summary>

```sql
-- 查询 SHOP 层级的原始数据
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
    AND customer_code IN ('K35159561', 'K220146595', 'K53644255', 'K200430621', 'K576105332')
    AND first_tab_type = '3'
    AND second_tab_type = '3'
    AND third_tab_type = '2'
ORDER BY customer_code, shop_code, four_tab_type;
```

</details>

---

## 问题汇总

### 问题 1: CUSTOMER 层级分母不一致

**现象**: SUM(SHOP.mother_num) ≠ CUSTOMER.mother_num，差异从 263 到 8171 不等

**影响维度**:
- 多个 K码 客户
- 主要集中在 first_tab_type=3, second_tab_type=3, third_tab_type=2 的维度组合
- son_num（分子）一致，只有 mother_num（分母）有差异

**可能原因**:
1. SHOP 层级数据更新后，CUSTOMER 层级未重新汇总
2. 汇总逻辑使用了不同的过滤条件
3. 存在数据重复或遗漏

**建议**: 
1. 检查 SHOP→CUSTOMER 的汇总任务是否正常执行
2. 对比 SHOP 和 CUSTOMER 层级的数据源
3. 检查汇总 SQL 的过滤条件是否一致

---

## 附录：配置注意事项

### brand_name 字段处理

**问题**: 配置文件中 `group_by_fields` 包含 `brand_name`，但不同层级的值不一致：
- BRANCH: brand_name = '' (空字符串)
- CUSTOMER: brand_name = '非品牌'

**影响**: 测试 SQL 的 JOIN 条件包含 `brand_name` 时，会导致匹配失败

**建议**: 
1. 检查数据源，确保各层级 `brand_name` 一致
2. 或者在配置中将 `brand_name` 从 `group_by_fields` 中排除
3. 或者在生成 SQL 时，对 `brand_name` 做特殊处理（如 COALESCE 或排除）
