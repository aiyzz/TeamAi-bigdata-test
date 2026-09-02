-- ============================================================
-- 数据验证 SQL 脚本
-- 生产表: nike.kcode_crm_ks_dku_pro    测试表: nike.kcode_crm_ks_dku
-- 分区值: 20260726    主键: kcode
-- 上游表: ytexp.ods_psc_t_market_direct_customer_dd
-- 关联键: t.kcode = o.k_code    筛选条件: settle_code LIKE 'ZK%' AND status = 1
-- 执行方式: DBeaver → Alt+X (执行脚本)
-- 激活能力: 能力0(数据质量) + 能力1(不变更记录) + 能力2(增加记录)
-- ============================================================

-- ============================================================
-- 主流程
-- ============================================================

-- [1.1] 空表前置检查
-- 预期: 两表均有数据（测试表 3674, 生产表 3498）
SELECT '测试表' AS tbl, count(*) AS cnt FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT '生产表' AS tbl, count(*) AS cnt FROM nike.kcode_crm_ks_dku_pro WHERE dt = '20260726';

-- [1.2] 数据量统计
-- 预期: 测试 3674, 生产 3498, 差值 +176
SELECT '测试' AS env, count(*) AS cnt FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT '生产' AS env, count(*) AS cnt FROM nike.kcode_crm_ks_dku_pro WHERE dt = '20260726';

-- [1.3] 新增条数（测试有、生产没有）
-- 预期: added_cnt > 0（约 176 条）
SELECT count(*) AS added_cnt
FROM nike.kcode_crm_ks_dku a
LEFT JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode AND b.dt = '20260726'
WHERE a.dt = '20260726' AND b.kcode IS NULL;

-- [1.4] 减少条数（生产有、测试没有）
-- 预期: removed_cnt = 0（测试表为增量优化，不应有减少）
SELECT count(*) AS removed_cnt
FROM nike.kcode_crm_ks_dku a
RIGHT JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode AND a.dt = '20260726'
WHERE b.dt = '20260726' AND a.kcode IS NULL;

-- [1.5] 新增记录明细（前10条）
-- 预期: 展示新增的 kcode 列表
SELECT a.kcode
FROM nike.kcode_crm_ks_dku a
LEFT JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode AND b.dt = '20260726'
WHERE a.dt = '20260726' AND b.kcode IS NULL
LIMIT 10;


-- ============================================================
-- 能力0: 数据质量检查
-- ============================================================

-- [0.1] 主键唯一性校验
-- 预期: 0 条重复
SELECT kcode, count(*) AS cnt
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260726'
GROUP BY kcode
HAVING count(*) > 1;

-- [0.2] 维度字段空值占比（UNION ALL 批量）
-- 预期: 各字段空值占比 ≤ 5%
SELECT 'rpt_date' AS field_name, count(*) AS total,
    sum(case when rpt_date is null or rpt_date = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when rpt_date is null or rpt_date = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'sum_type' AS field_name, count(*) AS total,
    sum(case when sum_type is null or sum_type = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when sum_type is null or sum_type = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'vip_id' AS field_name, count(*) AS total,
    sum(case when vip_id is null or vip_id = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when vip_id is null or vip_id = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'vip_name' AS field_name, count(*) AS total,
    sum(case when vip_name is null or vip_name = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when vip_name is null or vip_name = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'kname' AS field_name, count(*) AS total,
    sum(case when kname is null or kname = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when kname is null or kname = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'k_type' AS field_name, count(*) AS total,
    sum(case when k_type is null or k_type = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when k_type is null or k_type = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'region_code' AS field_name, count(*) AS total,
    sum(case when region_code is null or region_code = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when region_code is null or region_code = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'region_name' AS field_name, count(*) AS total,
    sum(case when region_name is null or region_name = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when region_name is null or region_name = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'department_code' AS field_name, count(*) AS total,
    sum(case when department_code is null or department_code = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when department_code is null or department_code = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'department_name' AS field_name, count(*) AS total,
    sum(case when department_name is null or department_name = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when department_name is null or department_name = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'first_tab_type' AS field_name, count(*) AS total,
    sum(case when first_tab_type is null or first_tab_type = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when first_tab_type is null or first_tab_type = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'customer_type' AS field_name, count(*) AS total,
    sum(case when customer_type is null or customer_type = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when customer_type is null or customer_type = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'third_tab_type' AS field_name, count(*) AS total,
    sum(case when third_tab_type is null or third_tab_type = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when third_tab_type is null or third_tab_type = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726';

-- [0.3] 指标字段空值+零值占比（UNION ALL 批量）
-- 预期: 空值+零值占比 ≤ 30%
SELECT 'taking_num' AS field_name, count(*) AS total,
    sum(case when taking_num is null then 1 else 0 end) AS null_cnt,
    sum(case when taking_num = '0' or taking_num = '0.0' or taking_num = '0.00' then 1 else 0 end) AS zero_cnt,
    round((sum(case when taking_num is null then 1 else 0 end) + sum(case when taking_num = '0' or taking_num = '0.0' or taking_num = '0.00' then 1 else 0 end)) * 100.0 / count(*), 2) AS null_zero_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'taking_num_ly' AS field_name, count(*) AS total,
    sum(case when taking_num_ly is null then 1 else 0 end) AS null_cnt,
    sum(case when taking_num_ly = '0' or taking_num_ly = '0.0' or taking_num_ly = '0.00' then 1 else 0 end) AS zero_cnt,
    round((sum(case when taking_num_ly is null then 1 else 0 end) + sum(case when taking_num_ly = '0' or taking_num_ly = '0.0' or taking_num_ly = '0.00' then 1 else 0 end)) * 100.0 / count(*), 2) AS null_zero_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'last_num' AS field_name, count(*) AS total,
    sum(case when last_num is null then 1 else 0 end) AS null_cnt,
    sum(case when last_num = '0' or last_num = '0.0' or last_num = '0.00' then 1 else 0 end) AS zero_cnt,
    round((sum(case when last_num is null then 1 else 0 end) + sum(case when last_num = '0' or last_num = '0.0' or last_num = '0.00' then 1 else 0 end)) * 100.0 / count(*), 2) AS null_zero_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726';

-- [0.4] 枚举值校验 - sum_type（d=日, m=月, y=年）
-- 预期: 仅出现 d/m/y，无未知值
SELECT
    sum_type,
    count(*) AS cnt,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE
        WHEN sum_type = 'd' THEN '日'
        WHEN sum_type = 'm' THEN '月'
        WHEN sum_type = 'y' THEN '年'
        ELSE '未知值'
    END AS value_desc
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260726'
GROUP BY sum_type
ORDER BY cnt DESC;

-- [0.5] 枚举值校验 - first_tab_type（1=品牌, 2=非品牌）
-- 预期: 仅出现 1/2，无未知值
SELECT
    first_tab_type,
    count(*) AS cnt,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE
        WHEN first_tab_type = '1' THEN '品牌'
        WHEN first_tab_type = '2' THEN '非品牌'
        ELSE '未知值'
    END AS value_desc
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260726'
GROUP BY first_tab_type
ORDER BY cnt DESC;

-- [0.6] 枚举值校验 - third_tab_type（1=含义乌商贸, 2=不含义乌商贸）
-- 预期: 仅出现 1/2，无未知值
SELECT
    third_tab_type,
    count(*) AS cnt,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE
        WHEN third_tab_type = '1' THEN '含义乌商贸'
        WHEN third_tab_type = '2' THEN '不含义乌商贸'
        ELSE '未知值'
    END AS value_desc
FROM nike.kcode_crm_ks_dku
WHERE dt = '20260726'
GROUP BY third_tab_type
ORDER BY cnt DESC;

-- [0.7] 指标字段统计分布（UNION ALL 批量，CAST 为 DECIMAL）
-- 预期: MIN ≥ 0（业务量不应为负）
SELECT 'taking_num' AS field_name,
    min(CAST(taking_num AS DECIMAL(20,4))) AS min_val,
    max(CAST(taking_num AS DECIMAL(20,4))) AS max_val,
    round(avg(CAST(taking_num AS DECIMAL(20,4))), 2) AS avg_val
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'taking_num_ly' AS field_name,
    min(CAST(taking_num_ly AS DECIMAL(20,4))) AS min_val,
    max(CAST(taking_num_ly AS DECIMAL(20,4))) AS max_val,
    round(avg(CAST(taking_num_ly AS DECIMAL(20,4))), 2) AS avg_val
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726'
UNION ALL
SELECT 'last_num' AS field_name,
    min(CAST(last_num AS DECIMAL(20,4))) AS min_val,
    max(CAST(last_num AS DECIMAL(20,4))) AS max_val,
    round(avg(CAST(last_num AS DECIMAL(20,4))), 2) AS avg_val
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726';

-- [0.8] 指标字段范围校验（业务量应 > 0，UNION ALL 批量）
-- 预期: invalid_cnt = 0
SELECT 'taking_num' AS field_name, count(*) AS total,
    sum(case when CAST(taking_num AS DECIMAL(20,4)) <= 0 then 1 else 0 end) AS invalid_cnt,
    round(sum(case when CAST(taking_num AS DECIMAL(20,4)) <= 0 then 1 else 0 end) * 100.0 / count(*), 2) AS invalid_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726' AND taking_num IS NOT NULL
UNION ALL
SELECT 'taking_num_ly' AS field_name, count(*) AS total,
    sum(case when CAST(taking_num_ly AS DECIMAL(20,4)) <= 0 then 1 else 0 end) AS invalid_cnt,
    round(sum(case when CAST(taking_num_ly AS DECIMAL(20,4)) <= 0 then 1 else 0 end) * 100.0 / count(*), 2) AS invalid_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726' AND taking_num_ly IS NOT NULL
UNION ALL
SELECT 'last_num' AS field_name, count(*) AS total,
    sum(case when CAST(last_num AS DECIMAL(20,4)) <= 0 then 1 else 0 end) AS invalid_cnt,
    round(sum(case when CAST(last_num AS DECIMAL(20,4)) <= 0 then 1 else 0 end) * 100.0 / count(*), 2) AS invalid_pct
FROM nike.kcode_crm_ks_dku WHERE dt = '20260726' AND last_num IS NOT NULL;


-- ============================================================
-- 能力1: 不变更记录验证
-- ============================================================

-- [1.1] 共同记录数
-- 预期: common_cnt > 0（约 3498 条）
SELECT count(*) AS common_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726';

-- [1.2] 批量字段差异数统计（UNION ALL，16个共同字段，排除主键kcode和分区dt）
-- 预期: 所有字段 diff_cnt = 0
SELECT 'rpt_date' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.rpt_date,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.rpt_date,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'sum_type' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.sum_type,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.sum_type,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'vip_id' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.vip_id,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.vip_id,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'vip_name' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.vip_name,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.vip_name,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'kname' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.kname,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.kname,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'taking_num' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.taking_num,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.taking_num,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'taking_num_ly' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.taking_num_ly,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.taking_num_ly,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'last_num' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.last_num,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.last_num,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'k_type' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.k_type,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.k_type,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'region_code' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.region_code,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.region_code,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'region_name' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.region_name,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.region_name,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'department_code' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.department_code,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.department_code,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'department_name' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.department_name,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.department_name,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'first_tab_type' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.first_tab_type,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.first_tab_type,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'customer_type' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.customer_type,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.customer_type,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726'
UNION ALL
SELECT 'third_tab_type' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.third_tab_type,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.third_tab_type,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.kcode_crm_ks_dku a
INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
WHERE a.dt = '20260726' AND b.dt = '20260726';

-- [1.3] 差异明细查询模板（当某字段 diff_cnt > 0 时执行，以 kname 为例）
-- 如需查看某字段差异明细，将 <差异字段> 替换为实际字段名后执行
-- SELECT a.kcode, a.<差异字段> AS a_val, b.<差异字段> AS b_val
-- FROM nike.kcode_crm_ks_dku a
-- INNER JOIN nike.kcode_crm_ks_dku_pro b ON a.kcode = b.kcode
-- WHERE NVL(CAST(NULLIF(a.<差异字段>,'') AS STRING), 'XXT')
--    <> NVL(CAST(NULLIF(b.<差异字段>,'') AS STRING), 'XXT')
-- AND a.dt = '20260726' AND b.dt = '20260726'
-- LIMIT 10;


-- ============================================================
-- 能力2: 增加记录验证
-- ============================================================

-- [2.1] 来源追溯匹配验证
-- 验证新增记录是否全部来自上游表 ytexp.ods_psc_t_market_direct_customer_dd
-- 预期: 匹配数 = 新增数, 未匹配数 = 0
SELECT
  CASE WHEN o.k_code IS NOT NULL THEN '匹配' ELSE '未匹配' END AS match_status,
  COUNT(*) AS cnt
FROM nike.kcode_crm_ks_dku t
LEFT JOIN ytexp.ods_psc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260726'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
GROUP BY CASE WHEN o.k_code IS NOT NULL THEN '匹配' ELSE '未匹配' END;

-- [2.2] 筛选条件符合性验证
-- 验证新增记录是否全部符合筛选条件: settle_code LIKE 'ZK%' AND status = 1
-- 注: 如上游表中"结算编码"字段名不是 settle_code，请替换为实际字段名
-- 预期: 符合条件数 = 新增数, 不符合条件数 = 0
SELECT
  CASE
    WHEN o.settle_code LIKE 'ZK%' AND o.status = 1 THEN '符合条件'
    ELSE '不符合条件'
  END AS filter_status,
  COUNT(*) AS cnt
FROM nike.kcode_crm_ks_dku t
INNER JOIN ytexp.ods_psc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260726'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
GROUP BY CASE
    WHEN o.settle_code LIKE 'ZK%' AND o.status = 1 THEN '符合条件'
    ELSE '不符合条件'
  END;

-- [2.3] 不符合条件数据排查
-- 预期: 0 条记录
SELECT
  t.kcode,
  o.k_code,
  o.settle_code,
  o.status
FROM nike.kcode_crm_ks_dku t
INNER JOIN ytexp.ods_psc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260726'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
  AND NOT (o.settle_code LIKE 'ZK%' AND o.status = 1)
LIMIT 20;

-- [2.4] 新增记录特征明细（按 settle_code 和 status 分布）
-- 预期: 所有记录的 settle_code 均以 ZK 开头，status 均为 1
SELECT
  o.settle_code,
  o.status,
  COUNT(*) AS cnt
FROM nike.kcode_crm_ks_dku t
INNER JOIN ytexp.ods_psc_t_market_direct_customer_dd o
  ON t.kcode = o.k_code AND t.dt = o.dt
WHERE t.dt = '20260726'
  AND NOT EXISTS (
    SELECT 1 FROM nike.kcode_crm_ks_dku_pro p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
GROUP BY o.settle_code, o.status
ORDER BY cnt DESC;
