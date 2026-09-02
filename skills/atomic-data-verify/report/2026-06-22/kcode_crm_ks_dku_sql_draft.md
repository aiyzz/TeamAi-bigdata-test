# SQL 初稿

## 基础信息

| 项目 | 内容 |
|------|------|
| 生产表 | nike.kcode_crm_ks_dku_pro |
| 测试表 | nike.kcode_crm_ks_dku |
| 分区值 | 20260614 |
| 主键 | kcode |
| 激活能力 | 能力0, 能力1, 能力2, 能力4 |

---

## ETL 逻辑确认

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| nike.ods_jsc_t_market_direct_customer_dd | kcode_crm_ks_dku.kcode = ods_jsc_t_market_direct_customer_dd.k_code | settle_code LIKE 'ZK%' AND status = '1' AND up_time <= '20260614' AND expire_time >= '20260614' |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| k_code | kcode | 直接映射 | - |
| k_name | kname | 直接映射 | - |
| sales_emp_code | sale_emp_code | 直接映射 | - |
| sales_emp_name | sale_emp_name | 直接映射 | - |
| customer_classify | first_tab_type | 条件映射 | CASE WHEN customer_classify='BRAND' THEN '1' ELSE '2' END |

---

## 能力0：数据质量检查 SQL

### 0.1 空表前置检查
```sql
SELECT '测试表' AS tbl, count(*) AS cnt FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT '生产表' AS tbl, count(*) AS cnt FROM nike.kcode_crm_ks_dku_pro WHERE dt = '20260614'
```

### 0.2 主键唯一性
```sql
SELECT kcode, count(*) AS cnt
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260614'
GROUP BY kcode
HAVING count(*) > 1
```

### 0.3 维度字段空值占比
```sql
SELECT 'rpt_date' AS field_name, count(*) AS total, sum(case when rpt_date is null or rpt_date = '' then 1 else 0 end) AS null_cnt, round(sum(case when rpt_date is null or rpt_date = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'sum_type', count(*), sum(case when sum_type is null or sum_type = '' then 1 else 0 end), round(sum(case when sum_type is null or sum_type = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'vip_id', count(*), sum(case when vip_id is null or vip_id = '' then 1 else 0 end), round(sum(case when vip_id is null or vip_id = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'vip_name', count(*), sum(case when vip_name is null or vip_name = '' then 1 else 0 end), round(sum(case when vip_name is null or vip_name = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'kcode', count(*), sum(case when kcode is null or kcode = '' then 1 else 0 end), round(sum(case when kcode is null or kcode = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'kname', count(*), sum(case when kname is null or kname = '' then 1 else 0 end), round(sum(case when kname is null or kname = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'k_type', count(*), sum(case when k_type is null or k_type = '' then 1 else 0 end), round(sum(case when k_type is null or k_type = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'region_code', count(*), sum(case when region_code is null or region_code = '' then 1 else 0 end), round(sum(case when region_code is null or region_code = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'region_name', count(*), sum(case when region_name is null or region_name = '' then 1 else 0 end), round(sum(case when region_name is null or region_name = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'department_code', count(*), sum(case when department_code is null or department_code = '' then 1 else 0 end), round(sum(case when department_code is null or department_code = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'department_name', count(*), sum(case when department_name is null or department_name = '' then 1 else 0 end), round(sum(case when department_name is null or department_name = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'first_tab_type', count(*), sum(case when first_tab_type is null or first_tab_type = '' then 1 else 0 end), round(sum(case when first_tab_type is null or first_tab_type = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'customer_type', count(*), sum(case when customer_type is null or customer_type = '' then 1 else 0 end), round(sum(case when customer_type is null or customer_type = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'third_tab_type', count(*), sum(case when third_tab_type is null or third_tab_type = '' then 1 else 0 end), round(sum(case when third_tab_type is null or third_tab_type = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'sale_emp_code', count(*), sum(case when sale_emp_code is null or sale_emp_code = '' then 1 else 0 end), round(sum(case when sale_emp_code is null or sale_emp_code = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'sale_emp_name', count(*), sum(case when sale_emp_name is null or sale_emp_name = '' then 1 else 0 end), round(sum(case when sale_emp_name is null or sale_emp_name = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
```

### 0.4 指标字段空值零值占比
```sql
SELECT 'taking_num' AS field_name, count(*) AS total, sum(case when taking_num is null then 1 else 0 end) AS null_cnt, sum(case when taking_num = '0' or taking_num = '' then 1 else 0 end) AS zero_cnt, round((sum(case when taking_num is null then 1 else 0 end) + sum(case when taking_num = '0' or taking_num = '' then 1 else 0 end)) * 100.0 / count(*), 2) AS null_zero_pct FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'taking_num_ly', count(*), sum(case when taking_num_ly is null then 1 else 0 end), sum(case when taking_num_ly = '0' or taking_num_ly = '' then 1 else 0 end), round((sum(case when taking_num_ly is null then 1 else 0 end) + sum(case when taking_num_ly = '0' or taking_num_ly = '' then 1 else 0 end)) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'last_num', count(*), sum(case when last_num is null then 1 else 0 end), sum(case when last_num = '0' or last_num = '' then 1 else 0 end), round((sum(case when last_num is null then 1 else 0 end) + sum(case when last_num = '0' or last_num = '' then 1 else 0 end)) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
```

### 0.5 枚举值校验
```sql
SELECT first_tab_type, count(*) AS cnt, round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE 
        WHEN first_tab_type = '1' THEN '品牌'
        WHEN first_tab_type = '2' THEN '非品牌'
        ELSE '未知值'
    END AS value_desc
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260614'
GROUP BY first_tab_type
ORDER BY cnt DESC
```

```sql
SELECT third_tab_type, count(*) AS cnt, round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE 
        WHEN third_tab_type = '1' THEN '含义乌商贸'
        WHEN third_tab_type = '2' THEN '不含义乌商贸'
        ELSE '未知值'
    END AS value_desc
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260614'
GROUP BY third_tab_type
ORDER BY cnt DESC
```

---

## 能力1：不变更记录验证 SQL

### 1.1 共同记录数
```sql
SELECT count(*) AS common_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'
```

### 1.2 字段比对（共同字段，排除主键和分区）
```sql
SELECT 'rpt_date' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.rpt_date,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.rpt_date,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'sum_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.sum_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.sum_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'vip_id' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.vip_id,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.vip_id,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'vip_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.vip_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.vip_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'kname' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.kname,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.kname,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'taking_num' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.taking_num,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.taking_num,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'taking_num_ly' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.taking_num_ly,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.taking_num_ly,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'last_num' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.last_num,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.last_num,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'k_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.k_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.k_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'region_code' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.region_code,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.region_code,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'region_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.region_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.region_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'department_code' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.department_code,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.department_code,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'department_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.department_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.department_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'first_tab_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.first_tab_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.first_tab_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'customer_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.customer_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.customer_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'third_tab_type' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.third_tab_type,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.third_tab_type,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'
```

---

## 能力2：增加记录验证 SQL（只验证 sale_emp_code, sale_emp_name）

### 2.1 新增记录数
```sql
SELECT count(*) AS added_cnt
FROM nike.kcode_crm_ks_dku a
LEFT JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode AND b.dt = '20260614'
WHERE a.dt = '20260614' AND b.kcode IS NULL
```

### 2.2 来源追溯匹配验证
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

### 2.3 筛选条件符合性验证
```sql
SELECT
  CASE
    WHEN o.settle_code LIKE 'ZK%' AND o.status = '1' AND o.up_time <= '20260614' AND o.expire_time >= '20260614' THEN '符合条件'
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
    WHEN o.settle_code LIKE 'ZK%' AND o.status = '1' AND o.up_time <= '20260614' AND o.expire_time >= '20260614' THEN '符合条件'
    ELSE '不符合条件'
  END
```

### 2.4 不符合条件数据排查
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

### 2.7 字段差异明细查询
```sql
SELECT
  t.kcode,
  t.sale_emp_code AS t_sale_emp_code,
  o.sales_emp_code AS o_sales_emp_code,
  t.sale_emp_name AS t_sale_emp_name,
  o.sales_emp_name AS o_sales_emp_name
FROM nike.kcode_crm_ks_dku t
INNER JOIN nike.ods_jsc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
  AND (
    COALESCE(CAST(NULLIF(t.sale_emp_code,'') AS CHAR), 'XXT') <> COALESCE(CAST(NULLIF(o.sales_emp_code,'') AS CHAR), 'XXT')
    OR COALESCE(CAST(NULLIF(t.sale_emp_name,'') AS CHAR), 'XXT') <> COALESCE(CAST(NULLIF(o.sales_emp_name,'') AS CHAR), 'XXT')
  )
LIMIT 20
```

---

## 能力4：字段增减验证 SQL

### 4.1 新增字段清单确认
```sql
SELECT t.column_name, t.data_type, t.column_comment
FROM information_schema.columns t
LEFT JOIN information_schema.columns p
  ON t.column_name = p.column_name
  AND p.table_schema = 'nike' AND p.table_name = 'kcode_crm_ks_dku_pro'
WHERE t.table_schema = 'nike' AND t.table_name = 'kcode_crm_ks_dku'
  AND p.column_name IS NULL
```

### 4.2 新增字段空值检查
```sql
SELECT 'sale_emp_code' AS field_name, count(*) AS total, sum(case when sale_emp_code is null or sale_emp_code = '' then 1 else 0 end) AS null_cnt, round(sum(case when sale_emp_code is null or sale_emp_code = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
UNION ALL
SELECT 'sale_emp_name', count(*), sum(case when sale_emp_name is null or sale_emp_name = '' then 1 else 0 end), round(sum(case when sale_emp_name is null or sale_emp_name = '' then 1 else 0 end) * 100.0 / count(*), 2) FROM nike.kcode_crm_ks_dku WHERE dt = '20260614'
```

### 4.3 新增字段验证 — sale_emp_code（直接映射，仅新增记录）
```sql
SELECT
  'sale_emp_code' AS field_name,
  SUM(CASE WHEN COALESCE(CAST(NULLIF(t.sale_emp_code,'') AS CHAR), 'XXT')
       <> COALESCE(CAST(NULLIF(o.sales_emp_code,'') AS CHAR), 'XXT')
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
INNER JOIN (
  SELECT k_code, sales_emp_code, dt
  FROM nike.ods_jsc_t_market_direct_customer_dd
  WHERE dt = '20260614'
  GROUP BY k_code, sales_emp_code, dt
) o ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
```

### 4.4 新增字段验证 — sale_emp_name（直接映射，仅新增记录）
```sql
SELECT
  'sale_emp_name' AS field_name,
  SUM(CASE WHEN COALESCE(CAST(NULLIF(t.sale_emp_name,'') AS CHAR), 'XXT')
       <> COALESCE(CAST(NULLIF(o.sales_emp_name,'') AS CHAR), 'XXT')
       THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku t
INNER JOIN (
  SELECT k_code, sales_emp_name, dt
  FROM nike.ods_jsc_t_market_direct_customer_dd
  WHERE dt = '20260614'
  GROUP BY k_code, sales_emp_name, dt
) o ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
```

### 4.5 新增字段差异明细
```sql
SELECT
  t.kcode,
  t.sale_emp_code AS t_sale_emp_code,
  o.sales_emp_code AS o_sales_emp_code,
  t.sale_emp_name AS t_sale_emp_name,
  o.sales_emp_name AS o_sales_emp_name
FROM nike.kcode_crm_ks_dku t
INNER JOIN nike.ods_jsc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260614'
  AND (
    COALESCE(CAST(NULLIF(t.sale_emp_code,'') AS CHAR), 'XXT') <> COALESCE(CAST(NULLIF(o.sales_emp_code,'') AS CHAR), 'XXT')
    OR COALESCE(CAST(NULLIF(t.sale_emp_name,'') AS CHAR), 'XXT') <> COALESCE(CAST(NULLIF(o.sales_emp_name,'') AS CHAR), 'XXT')
  )
LIMIT 20
```
