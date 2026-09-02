
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
    COALESCE(exp.should_use_num, 0)            AS expect_should_use_num,
    COALESCE(act.should_use_num, 0)            AS actual_should_use_num,
    ABS(COALESCE(exp.should_use_num, 0) - COALESCE(act.should_use_num, 0)) AS diff_should_use_num,
    COALESCE(exp.should_use_num_lp, 0)            AS expect_should_use_num_lp,
    COALESCE(act.should_use_num_lp, 0)            AS actual_should_use_num_lp,
    ABS(COALESCE(exp.should_use_num_lp, 0) - COALESCE(act.should_use_num_lp, 0)) AS diff_should_use_num_lp,
    COALESCE(exp.use_num, 0)            AS expect_use_num,
    COALESCE(act.use_num, 0)            AS actual_use_num,
    ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) AS diff_use_num,
    COALESCE(exp.use_num_lp, 0)            AS expect_use_num_lp,
    COALESCE(act.use_num_lp, 0)            AS actual_use_num_lp,
    ABS(COALESCE(exp.use_num_lp, 0) - COALESCE(act.use_num_lp, 0)) AS diff_use_num_lp
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(should_use_num_lp AS DECIMAL(22,4))) AS should_use_num_lp,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_num_lp AS DECIMAL(22,4))) AS use_num_lp
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND (org_type = 'REGION_MANAGE')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    CAST(should_use_num AS DECIMAL(22,4)) AS should_use_num,
    CAST(should_use_num_lp AS DECIMAL(22,4)) AS should_use_num_lp,
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_num_lp AS DECIMAL(22,4)) AS use_num_lp
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'HEAD'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type
WHERE
    (ABS(COALESCE(exp.should_use_num, 0) - COALESCE(act.should_use_num, 0)) > 0.0 OR act.should_use_num IS NULL)
    OR (ABS(COALESCE(exp.should_use_num_lp, 0) - COALESCE(act.should_use_num_lp, 0)) > 0.0 OR act.should_use_num_lp IS NULL)
    OR (ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) > 0.0 OR act.use_num IS NULL)
    OR (ABS(COALESCE(exp.use_num_lp, 0) - COALESCE(act.use_num_lp, 0)) > 0.0 OR act.use_num_lp IS NULL)
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
    exp.first_tab_type,
    exp.region_code,
    COALESCE(exp.should_use_num, 0)            AS expect_should_use_num,
    COALESCE(act.should_use_num, 0)            AS actual_should_use_num,
    ABS(COALESCE(exp.should_use_num, 0) - COALESCE(act.should_use_num, 0)) AS diff_should_use_num,
    COALESCE(exp.should_use_num_lp, 0)            AS expect_should_use_num_lp,
    COALESCE(act.should_use_num_lp, 0)            AS actual_should_use_num_lp,
    ABS(COALESCE(exp.should_use_num_lp, 0) - COALESCE(act.should_use_num_lp, 0)) AS diff_should_use_num_lp,
    COALESCE(exp.use_num, 0)            AS expect_use_num,
    COALESCE(act.use_num, 0)            AS actual_use_num,
    ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) AS diff_use_num,
    COALESCE(exp.use_num_lp, 0)            AS expect_use_num_lp,
    COALESCE(act.use_num_lp, 0)            AS actual_use_num_lp,
    ABS(COALESCE(exp.use_num_lp, 0) - COALESCE(act.use_num_lp, 0)) AS diff_use_num_lp
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    region_code,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(should_use_num_lp AS DECIMAL(22,4))) AS should_use_num_lp,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_num_lp AS DECIMAL(22,4))) AS use_num_lp
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND (org_type = 'TRANSFER_CENTER')
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, region_code
) exp
LEFT JOIN (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    region_code,
    CAST(should_use_num AS DECIMAL(22,4)) AS should_use_num,
    CAST(should_use_num_lp AS DECIMAL(22,4)) AS should_use_num_lp,
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_num_lp AS DECIMAL(22,4)) AS use_num_lp
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'REGION_MANAGE'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, region_code
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.region_code = act.region_code
WHERE
    (ABS(COALESCE(exp.should_use_num, 0) - COALESCE(act.should_use_num, 0)) > 0.0 OR act.should_use_num IS NULL)
    OR (ABS(COALESCE(exp.should_use_num_lp, 0) - COALESCE(act.should_use_num_lp, 0)) > 0.0 OR act.should_use_num_lp IS NULL)
    OR (ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) > 0.0 OR act.use_num IS NULL)
    OR (ABS(COALESCE(exp.use_num_lp, 0) - COALESCE(act.use_num_lp, 0)) > 0.0 OR act.use_num_lp IS NULL)
LIMIT 10;
