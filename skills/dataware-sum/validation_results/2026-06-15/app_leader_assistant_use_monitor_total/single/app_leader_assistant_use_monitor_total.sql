
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
    COALESCE(exp.use_num, 0)            AS expect_use_num,
    COALESCE(act.use_num, 0)            AS actual_use_num,
    ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) AS diff_use_num,
    COALESCE(exp.use_rate_lp, 0)            AS expect_use_rate_lp,
    COALESCE(act.use_rate_lp, 0)            AS actual_use_rate_lp,
    ABS(COALESCE(exp.use_rate_lp, 0) - COALESCE(act.use_rate_lp, 0)) AS diff_use_rate_lp
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp
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
    OR (ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) > 0.0 OR act.use_num IS NULL)
    OR (ABS(COALESCE(exp.use_rate_lp, 0) - COALESCE(act.use_rate_lp, 0)) > 0.0 OR act.use_rate_lp IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：HEAD.use_rate | 误差阈值：0.0
-- 原始公式：use_num / should_use_num * 100
-- 展开公式：use_num / should_use_num * 100
-- 实际值：org_type='HEAD' 的 use_rate 列
-- ==============================================================================
SELECT
    'HEAD_DERIVED_use_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)                          AS expect_use_rate,
    COALESCE(act.use_rate, 0)               AS actual_use_rate,
    ABS((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - COALESCE(act.use_rate, 0)) AS diff_use_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp,
    CAST(use_rate AS DECIMAL(22,4)) AS use_rate
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'HEAD'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type
WHERE
    ABS((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - COALESCE(act.use_rate, 0)) > 0.0
    OR act.use_rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：HEAD.use_rate_diff | 误差阈值：0.0
-- 原始公式：use_rate - use_rate_lp
-- 展开公式：(use_num / should_use_num * 100) - (use_num / should_use_num * 100)_lp
-- 实际值：org_type='HEAD' 的 use_rate_diff 列
-- ==============================================================================
SELECT
    'HEAD_DERIVED_use_rate_diff' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    ((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp)                          AS expect_use_rate_diff,
    COALESCE(act.use_rate_diff, 0)               AS actual_use_rate_diff,
    ABS(((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp) - COALESCE(act.use_rate_diff, 0)) AS diff_use_rate_diff
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp,
    CAST(use_rate_diff AS DECIMAL(22,4)) AS use_rate_diff
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'HEAD'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type
WHERE
    ABS(((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp) - COALESCE(act.use_rate_diff, 0)) > 0.0
    OR act.use_rate_diff IS NULL
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
    COALESCE(exp.use_num, 0)            AS expect_use_num,
    COALESCE(act.use_num, 0)            AS actual_use_num,
    ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) AS diff_use_num,
    COALESCE(exp.use_rate_lp, 0)            AS expect_use_rate_lp,
    COALESCE(act.use_rate_lp, 0)            AS actual_use_rate_lp,
    ABS(COALESCE(exp.use_rate_lp, 0) - COALESCE(act.use_rate_lp, 0)) AS diff_use_rate_lp
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    region_code,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp
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
    OR (ABS(COALESCE(exp.use_num, 0) - COALESCE(act.use_num, 0)) > 0.0 OR act.use_num IS NULL)
    OR (ABS(COALESCE(exp.use_rate_lp, 0) - COALESCE(act.use_rate_lp, 0)) > 0.0 OR act.use_rate_lp IS NULL)
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：REGION_MANAGE.use_rate | 误差阈值：0.0
-- 原始公式：use_num / should_use_num * 100
-- 展开公式：use_num / should_use_num * 100
-- 实际值：org_type='REGION_MANAGE' 的 use_rate 列
-- ==============================================================================
SELECT
    'REGION_MANAGE_DERIVED_use_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    exp.region_code,
    (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)                          AS expect_use_rate,
    COALESCE(act.use_rate, 0)               AS actual_use_rate,
    ABS((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - COALESCE(act.use_rate, 0)) AS diff_use_rate
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    region_code,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp,
    CAST(use_rate AS DECIMAL(22,4)) AS use_rate
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'REGION_MANAGE'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, region_code
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.region_code = act.region_code
WHERE
    ABS((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - COALESCE(act.use_rate, 0)) > 0.0
    OR act.use_rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 验证派生指标：REGION_MANAGE.use_rate_diff | 误差阈值：0.0
-- 原始公式：use_rate - use_rate_lp
-- 展开公式：(use_num / should_use_num * 100) - (use_num / should_use_num * 100)_lp
-- 实际值：org_type='REGION_MANAGE' 的 use_rate_diff 列
-- ==============================================================================
SELECT
    'REGION_MANAGE_DERIVED_use_rate_diff' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    exp.region_code,
    ((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp)                          AS expect_use_rate_diff,
    COALESCE(act.use_rate_diff, 0)               AS actual_use_rate_diff,
    ABS(((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp) - COALESCE(act.use_rate_diff, 0)) AS diff_use_rate_diff
FROM (
SELECT
    rpt_date,
    sum_type,
    first_tab_type,
    region_code,
    SUM(CAST(should_use_num AS DECIMAL(22,4))) AS should_use_num,
    SUM(CAST(use_num AS DECIMAL(22,4))) AS use_num,
    SUM(CAST(use_rate_lp AS DECIMAL(22,4))) AS use_rate_lp
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
    CAST(use_num AS DECIMAL(22,4)) AS use_num,
    CAST(use_rate_lp AS DECIMAL(22,4)) AS use_rate_lp,
    CAST(use_rate_diff AS DECIMAL(22,4)) AS use_rate_diff
FROM nike.app_leader_assistant_use_monitor_total
WHERE
    sum_type = 'D'
    AND org_type = 'REGION_MANAGE'
    AND dt = '${bizdate}'
GROUP BY rpt_date, sum_type, first_tab_type, region_code
) act
ON exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.region_code = act.region_code
WHERE
    ABS(((COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100) - (COALESCE(SUM(exp.use_num), 0) / COALESCE(SUM(exp.should_use_num), 0) * 100)_lp) - COALESCE(act.use_rate_diff, 0)) > 0.0
    OR act.use_rate_diff IS NULL
LIMIT 10;
