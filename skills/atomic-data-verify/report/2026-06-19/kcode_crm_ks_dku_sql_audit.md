# SQL 审核报告

## 审核概要

| 项目 | 内容 |
|------|------|
| 审核时间 | 2026-06-19 |
| 激活能力 | 能力1, 能力2, 能力4 |
| 审核SQL数量 | 8 条 |
| 通过数量 | 8 条 |
| 偏差数量 | 0 条 |

---

## 审核结果

| 测试点 | SQL 类型 | 是否遵循模板 | 修正说明 |
|--------|----------|-------------|----------|
| 1.1 | 共同记录数 | ✅ 是 | - |
| 1.2 | 批量字段比对（16个字段） | ✅ 是 | varchar使用NULLIF，int不使用NULLIF |
| 2.1 | 来源追溯匹配 | ✅ 是 | - |
| 2.2 | 筛选条件符合性 | ✅ 是 | - |
| 2.3 | 不符合条件排查 | ✅ 是 | - |
| 4.1 | 原有字段保护（16个字段） | ✅ 是 | - |
| 4.2 | 新增字段验证（直接映射） | ✅ 是 | - |
| 4.3 | 新增字段质量检查 | ✅ 是 | - |

**审核结论**：全部通过

---

## 审核通过的 SQL

### 能力1：不变更记录验证 SQL

#### 1.1 共同记录数

```sql
SELECT count(*) AS common_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'
```

#### 1.2 批量字段差异数统计（UNION ALL）

```sql
SELECT
    'rpt_date' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.rpt_date,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.rpt_date,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'sum_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.sum_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.sum_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'vip_id' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.vip_id,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.vip_id,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'vip_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.vip_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.vip_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'kname' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.kname,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.kname,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'taking_num' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(a.taking_num AS CHAR), 'XXT')
           <> COALESCE(CAST(b.taking_num AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'taking_num_ly' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(a.taking_num_ly AS CHAR), 'XXT')
           <> COALESCE(CAST(b.taking_num_ly AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'last_num' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(a.last_num AS CHAR), 'XXT')
           <> COALESCE(CAST(b.last_num AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'k_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.k_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.k_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'region_code' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.region_code,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.region_code,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'region_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.region_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.region_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'department_code' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.department_code,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.department_code,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'department_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.department_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.department_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'first_tab_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.first_tab_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.first_tab_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'customer_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.customer_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.customer_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT
    'third_tab_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.third_tab_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.third_tab_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'
```

---

### 能力2：增加记录验证 SQL

#### 2.1 来源追溯匹配验证

```sql
SELECT
  CASE WHEN o.k_code IS NOT NULL THEN '匹配' ELSE '未匹配' END AS match_status,
  COUNT(*) AS cnt
FROM nike.kcode_crm_ks_dku t
LEFT JOIN nike.ods_jsc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
GROUP BY CASE WHEN o.k_code IS NOT NULL THEN '匹配' ELSE '未匹配' END
```

#### 2.2 筛选条件符合性验证

```sql
SELECT
  CASE
    WHEN o.settle_code LIKE 'ZK%' AND o.status = '1' AND o.up_time <= '20260614' AND o.expire_time >= '20260614'
    THEN '符合条件'
    ELSE '不符合条件'
  END AS filter_status,
  COUNT(*) AS cnt
FROM nike.kcode_crm_ks_dku t
INNER JOIN nike.ods_jsc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
GROUP BY CASE
    WHEN o.settle_code LIKE 'ZK%' AND o.status = '1' AND o.up_time <= '20260614' AND o.expire_time >= '20260614'
    THEN '符合条件'
    ELSE '不符合条件'
  END
```

#### 2.3 不符合条件数据排查

```sql
SELECT
  t.kcode,
  o.settle_code,
  o.status,
  o.up_time,
  o.expire_time
FROM nike.kcode_crm_ks_dku t
INNER JOIN nike.ods_jsc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
  AND NOT (o.settle_code LIKE 'ZK%' AND o.status = '1' AND o.up_time <= '20260614' AND o.expire_time >= '20260614')
LIMIT 20
```

---

### 能力4：字段增减验证 SQL

#### 4.1 原有字段保护验证（UNION ALL）

```sql
SELECT
  'rpt_date' AS field_name,
  SUM(CASE WHEN t.rpt_date != pro.rpt_date
       OR (t.rpt_date IS NULL AND pro.rpt_date IS NOT NULL)
       OR (t.rpt_date IS NOT NULL AND pro.rpt_date IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'sum_type' AS field_name,
  SUM(CASE WHEN t.sum_type != pro.sum_type
       OR (t.sum_type IS NULL AND pro.sum_type IS NOT NULL)
       OR (t.sum_type IS NOT NULL AND pro.sum_type IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'vip_id' AS field_name,
  SUM(CASE WHEN t.vip_id != pro.vip_id
       OR (t.vip_id IS NULL AND pro.vip_id IS NOT NULL)
       OR (t.vip_id IS NOT NULL AND pro.vip_id IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'vip_name' AS field_name,
  SUM(CASE WHEN t.vip_name != pro.vip_name
       OR (t.vip_name IS NULL AND pro.vip_name IS NOT NULL)
       OR (t.vip_name IS NOT NULL AND pro.vip_name IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'kname' AS field_name,
  SUM(CASE WHEN t.kname != pro.kname
       OR (t.kname IS NULL AND pro.kname IS NOT NULL)
       OR (t.kname IS NOT NULL AND pro.kname IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'taking_num' AS field_name,
  SUM(CASE WHEN t.taking_num != pro.taking_num
       OR (t.taking_num IS NULL AND pro.taking_num IS NOT NULL)
       OR (t.taking_num IS NOT NULL AND pro.taking_num IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'taking_num_ly' AS field_name,
  SUM(CASE WHEN t.taking_num_ly != pro.taking_num_ly
       OR (t.taking_num_ly IS NULL AND pro.taking_num_ly IS NOT NULL)
       OR (t.taking_num_ly IS NOT NULL AND pro.taking_num_ly IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'last_num' AS field_name,
  SUM(CASE WHEN t.last_num != pro.last_num
       OR (t.last_num IS NULL AND pro.last_num IS NOT NULL)
       OR (t.last_num IS NOT NULL AND pro.last_num IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'k_type' AS field_name,
  SUM(CASE WHEN t.k_type != pro.k_type
       OR (t.k_type IS NULL AND pro.k_type IS NOT NULL)
       OR (t.k_type IS NOT NULL AND pro.k_type IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'region_code' AS field_name,
  SUM(CASE WHEN t.region_code != pro.region_code
       OR (t.region_code IS NULL AND pro.region_code IS NOT NULL)
       OR (t.region_code IS NOT NULL AND pro.region_code IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'region_name' AS field_name,
  SUM(CASE WHEN t.region_name != pro.region_name
       OR (t.region_name IS NULL AND pro.region_name IS NOT NULL)
       OR (t.region_name IS NOT NULL AND pro.region_name IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'department_code' AS field_name,
  SUM(CASE WHEN t.department_code != pro.department_code
       OR (t.department_code IS NULL AND pro.department_code IS NOT NULL)
       OR (t.department_code IS NOT NULL AND pro.department_code IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'department_name' AS field_name,
  SUM(CASE WHEN t.department_name != pro.department_name
       OR (t.department_name IS NULL AND pro.department_name IS NOT NULL)
       OR (t.department_name IS NOT NULL AND pro.department_name IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'first_tab_type' AS field_name,
  SUM(CASE WHEN t.first_tab_type != pro.first_tab_type
       OR (t.first_tab_type IS NULL AND pro.first_tab_type IS NOT NULL)
       OR (t.first_tab_type IS NOT NULL AND pro.first_tab_type IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'customer_type' AS field_name,
  SUM(CASE WHEN t.customer_type != pro.customer_type
       OR (t.customer_type IS NULL AND pro.customer_type IS NOT NULL)
       OR (t.customer_type IS NOT NULL AND pro.customer_type IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'third_tab_type' AS field_name,
  SUM(CASE WHEN t.third_tab_type != pro.third_tab_type
       OR (t.third_tab_type IS NULL AND pro.third_tab_type IS NOT NULL)
       OR (t.third_tab_type IS NOT NULL AND pro.third_tab_type IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
JOIN nike.kcode_crm_ks_dku_pro pro ON t.kcode = pro.kcode AND t.dt = pro.dt
WHERE t.dt = '20260614'
```

#### 4.2 新增字段验证 — 直接映射（D1）

```sql
SELECT
  'sale_emp_code' AS field_name,
  SUM(CASE WHEN t.sale_emp_code != src.sales_emp_code
       OR (t.sale_emp_code IS NULL AND src.sales_emp_code IS NOT NULL)
       OR (t.sale_emp_code IS NOT NULL AND src.sales_emp_code IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
LEFT JOIN nike.ods_jsc_t_market_direct_customer_dd src
  ON t.kcode = src.k_code AND src.dt = '20260614'
WHERE t.dt = '20260614'

UNION ALL

SELECT
  'sale_emp_name' AS field_name,
  SUM(CASE WHEN t.sale_emp_name != src.sales_emp_name
       OR (t.sale_emp_name IS NULL AND src.sales_emp_name IS NOT NULL)
       OR (t.sale_emp_name IS NOT NULL AND src.sales_emp_name IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
LEFT JOIN nike.ods_jsc_t_market_direct_customer_dd src
  ON t.kcode = src.k_code AND src.dt = '20260614'
WHERE t.dt = '20260614'
```

#### 4.3 新增字段质量检查

```sql
SELECT
  'sale_emp_code' AS field_name,
  COUNT(*) AS total,
  SUM(CASE WHEN sale_emp_code IS NULL OR sale_emp_code = '' THEN 1 ELSE 0 END) AS null_cnt,
  ROUND(SUM(CASE WHEN sale_emp_code IS NULL OR sale_emp_code = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260614'

UNION ALL

SELECT
  'sale_emp_name' AS field_name,
  COUNT(*) AS total,
  SUM(CASE WHEN sale_emp_name IS NULL OR sale_emp_name = '' THEN 1 ELSE 0 END) AS null_cnt,
  ROUND(SUM(CASE WHEN sale_emp_name IS NULL OR sale_emp_name = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260614'
```
