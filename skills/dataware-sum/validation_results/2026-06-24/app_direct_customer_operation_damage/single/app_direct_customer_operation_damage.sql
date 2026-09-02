
-- ==============================================================================
-- 验证层级：HEAD | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (REGION_MANAGE))
-- 实际值来源：org_type='HEAD'
-- ==============================================================================
SELECT
    'HEAD_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'REGION_MANAGE')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'HEAD'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：HEAD.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='HEAD' 的 rate 列
-- ==============================================================================
SELECT
    'HEAD_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'REGION_MANAGE')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'HEAD'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证层级：REGION_MANAGE | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (TRANSFER_CENTER))
-- 实际值来源：org_type='REGION_MANAGE'
-- ==============================================================================
SELECT
    'REGION_MANAGE_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.region_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    region_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'TRANSFER_CENTER')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, region_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    region_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'REGION_MANAGE'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, region_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.region_code = act.region_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：REGION_MANAGE.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='REGION_MANAGE' 的 rate 列
-- ==============================================================================
SELECT
    'REGION_MANAGE_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.region_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    region_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'TRANSFER_CENTER')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, region_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    region_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'REGION_MANAGE'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, region_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.region_code = act.region_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证层级：TRANSFER_CENTER | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (GRID_AREA))
-- 实际值来源：org_type='TRANSFER_CENTER'
-- ==============================================================================
SELECT
    'TRANSFER_CENTER_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.center_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    center_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'GRID_AREA')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, center_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    center_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'TRANSFER_CENTER'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, center_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.center_code = act.center_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：TRANSFER_CENTER.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='TRANSFER_CENTER' 的 rate 列
-- ==============================================================================
SELECT
    'TRANSFER_CENTER_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.center_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    center_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'GRID_AREA')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, center_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    center_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'TRANSFER_CENTER'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, center_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.center_code = act.center_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证层级：GRID_AREA | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (BRANCH))
-- 实际值来源：org_type='GRID_AREA'
-- ==============================================================================
SELECT
    'GRID_AREA_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.grid_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    grid_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'BRANCH')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, grid_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    grid_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'GRID_AREA'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, grid_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.grid_code = act.grid_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：GRID_AREA.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='GRID_AREA' 的 rate 列
-- ==============================================================================
SELECT
    'GRID_AREA_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.grid_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    grid_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'BRANCH')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, grid_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    grid_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'GRID_AREA'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, grid_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.grid_code = act.grid_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证层级：BRANCH | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (CUSTOMER))
-- 实际值来源：org_type='BRANCH'
-- ==============================================================================
SELECT
    'BRANCH_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.branch_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    branch_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'CUSTOMER')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    branch_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'BRANCH'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.branch_code = act.branch_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：BRANCH.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='BRANCH' 的 rate 列
-- ==============================================================================
SELECT
    'BRANCH_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.branch_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    branch_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'CUSTOMER')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    branch_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'BRANCH'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, branch_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.branch_code = act.branch_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证层级：CUSTOMER | 误差阈值：0.0
-- 预期值来源：SUM(org_type IN (SHOP))
-- 实际值来源：org_type='CUSTOMER'
-- ==============================================================================
SELECT
    'CUSTOMER_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.customer_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    COALESCE(exp.son_num, 0)            AS expect_son_num,
    COALESCE(act.son_num, 0)            AS actual_son_num,
    ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) AS diff_son_num,
    COALESCE(exp.son_num_ly, 0)            AS expect_son_num_ly,
    COALESCE(act.son_num_ly, 0)            AS actual_son_num_ly,
    ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) AS diff_son_num_ly,
    COALESCE(exp.mother_num, 0)            AS expect_mother_num,
    COALESCE(act.mother_num, 0)            AS actual_mother_num,
    ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) AS diff_mother_num,
    COALESCE(exp.mother_num_ly, 0)            AS expect_mother_num_ly,
    COALESCE(act.mother_num_ly, 0)            AS actual_mother_num_ly,
    ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) AS diff_mother_num_ly
FROM (
SELECT
    rpt_date,
    sum_type,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'SHOP')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, customer_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'CUSTOMER'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, customer_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.customer_code = act.customer_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    (ABS(COALESCE(exp.son_num, 0) - COALESCE(act.son_num, 0)) > 0.0 OR act.son_num IS NULL)
    OR (ABS(COALESCE(exp.son_num_ly, 0) - COALESCE(act.son_num_ly, 0)) > 0.0 OR act.son_num_ly IS NULL)
    OR (ABS(COALESCE(exp.mother_num, 0) - COALESCE(act.mother_num, 0)) > 0.0 OR act.mother_num IS NULL)
    OR (ABS(COALESCE(exp.mother_num_ly, 0) - COALESCE(act.mother_num_ly, 0)) > 0.0 OR act.mother_num_ly IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：CUSTOMER.rate | 误差阈值：0.0
-- 原始公式：son_num / mother_num * 100000
-- 展开公式：son_num / mother_num * 100000
-- 实际值：org_type='CUSTOMER' 的 rate 列
-- ==============================================================================
SELECT
    'CUSTOMER_DERIVED_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.customer_code,
    exp.first_tab_type,
    exp.second_tab_type,
    exp.third_tab_type,
    exp.four_tab_type,
    exp.sector_name,
    exp.brand_name,
    (COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000)                          AS expect_rate,
    COALESCE(act.rate, 0)               AS actual_rate,
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) AS diff_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    SUM(CAST(son_num AS DECIMAL(22,4))) AS son_num,
    SUM(CAST(son_num_ly AS DECIMAL(22,4))) AS son_num_ly,
    SUM(CAST(mother_num AS DECIMAL(22,4))) AS mother_num,
    SUM(CAST(mother_num_ly AS DECIMAL(22,4))) AS mother_num_ly
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND (org_type = 'SHOP')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, customer_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    customer_code,
    first_tab_type,
    second_tab_type,
    third_tab_type,
    four_tab_type,
    sector_name,
    brand_name,
    CAST(son_num AS DECIMAL(22,4)) AS son_num,
    CAST(son_num_ly AS DECIMAL(22,4)) AS son_num_ly,
    CAST(mother_num AS DECIMAL(22,4)) AS mother_num,
    CAST(mother_num_ly AS DECIMAL(22,4)) AS mother_num_ly,
    CAST(rate AS DECIMAL(22,4)) AS rate
FROM nike.app_direct_customer_operation_damage
WHERE
    sum_type = 'D'
    AND org_type = 'CUSTOMER'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, customer_code, first_tab_type, second_tab_type, third_tab_type, four_tab_type, sector_name, brand_name
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.customer_code = act.customer_code AND exp.first_tab_type = act.first_tab_type AND exp.second_tab_type = act.second_tab_type AND exp.third_tab_type = act.third_tab_type AND exp.four_tab_type = act.four_tab_type AND exp.sector_name = act.sector_name AND exp.brand_name = act.brand_name
WHERE
    ABS((COALESCE(SUM(exp.son_num), 0) / COALESCE(SUM(exp.mother_num), 0) * 100000) - COALESCE(act.rate, 0)) > 0.0
    OR act.rate IS NULL
LIMIT 10;
