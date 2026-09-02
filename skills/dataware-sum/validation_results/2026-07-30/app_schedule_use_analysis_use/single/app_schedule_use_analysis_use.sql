-- ==============================================================================
-- 表名: export.app_schedule_use_analysis_use
-- 模式: single_table
-- 层级: HEAD > REGION_MANAGE > TRANSFER_CENTER > EMP
-- 指标: work_emp_num(在职人数), pre_use_num(应使用人数), real_use_num(实际使用人数), use_rate(使用率)
-- 率值公式: use_rate = real_use_num / pre_use_num * 100
-- 特殊规则: EMP->TRANSFER_CENTER 汇总时, real_use_num = SUM(CASE WHEN use_times > 0 THEN 1 ELSE 0 END)
--   注: use_times 仅作为特殊规则的判断条件, 不作为独立校验指标
-- 阈值: 0.0 (SUM_METRICS) / 0.01 (DERIVED_rate)
-- 使用时将 ${bizdate} 替换为实际分区日期(如 '20260730')
-- ==============================================================================


-- ==============================================================================
-- 用例 1: HEAD_SUM_METRICS
-- 验证逻辑: HEAD = SUM(REGION_MANAGE) 指标汇总
-- 预期值来源: SUM(org_type = 'REGION_MANAGE')
-- 实际值来源: org_type = 'HEAD'
-- ==============================================================================
SELECT
    'HEAD_SUM_METRICS' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    COALESCE(exp.work_emp_num, 0) AS expect_work_emp_num,
    COALESCE(act.work_emp_num, 0) AS actual_work_emp_num,
    ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) AS diff_work_emp_num,
    COALESCE(exp.pre_use_num, 0) AS expect_pre_use_num,
    COALESCE(act.pre_use_num, 0) AS actual_pre_use_num,
    ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) AS diff_pre_use_num,
    COALESCE(exp.real_use_num, 0) AS expect_real_use_num,
    COALESCE(act.real_use_num, 0) AS actual_real_use_num,
    ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) AS diff_real_use_num
FROM (
    SELECT
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CAST(work_emp_num AS DECIMAL(22,4))) AS work_emp_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num,
        SUM(CAST(real_use_num AS DECIMAL(22,4))) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'REGION_MANAGE'
        AND dt = '${bizdate}'
    GROUP BY rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(work_emp_num AS DECIMAL(22,4)) AS work_emp_num,
        CAST(pre_use_num AS DECIMAL(22,4)) AS pre_use_num,
        CAST(real_use_num AS DECIMAL(22,4)) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'HEAD'
        AND dt = '${bizdate}'
) act
ON exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE (ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) > 0.0 OR act.work_emp_num IS NULL)
    OR (ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) > 0.0 OR act.pre_use_num IS NULL)
    OR (ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) > 0.0 OR act.real_use_num IS NULL)
LIMIT 10;


-- ==============================================================================
-- 用例 2: HEAD_DERIVED_use_rate
-- 验证逻辑: HEAD.use_rate = real_use_num / pre_use_num * 100
-- 公式展开: real_use_num / pre_use_num * 100
-- 预期值来源: SUM(org_type = 'REGION_MANAGE') 的 real_use_num 和 pre_use_num
-- 实际值来源: org_type = 'HEAD' 的 use_rate 列
-- ==============================================================================
SELECT
    'HEAD_DERIVED_use_rate' AS test_case,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    (COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) AS expect_use_rate,
    COALESCE(act.use_rate, 0) AS actual_use_rate,
    ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) AS diff_use_rate
FROM (
    SELECT
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CAST(real_use_num AS DECIMAL(22,4))) AS real_use_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'REGION_MANAGE'
        AND dt = '${bizdate}'
    GROUP BY rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(use_rate AS DECIMAL(22,4)) AS use_rate
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'HEAD'
        AND dt = '${bizdate}'
) act
ON exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) > 0.01
    OR act.use_rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 用例 3: REGION_MANAGE_SUM_METRICS
-- 验证逻辑: REGION_MANAGE = SUM(TRANSFER_CENTER) 指标汇总
-- 预期值来源: SUM(org_type = 'TRANSFER_CENTER')
-- 实际值来源: org_type = 'REGION_MANAGE'
-- ==============================================================================
SELECT
    'REGION_MANAGE_SUM_METRICS' AS test_case,
    exp.region_code,
    exp.region_name,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    COALESCE(exp.work_emp_num, 0) AS expect_work_emp_num,
    COALESCE(act.work_emp_num, 0) AS actual_work_emp_num,
    ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) AS diff_work_emp_num,
    COALESCE(exp.pre_use_num, 0) AS expect_pre_use_num,
    COALESCE(act.pre_use_num, 0) AS actual_pre_use_num,
    ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) AS diff_pre_use_num,
    COALESCE(exp.real_use_num, 0) AS expect_real_use_num,
    COALESCE(act.real_use_num, 0) AS actual_real_use_num,
    ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) AS diff_real_use_num
FROM (
    SELECT
        region_code,
        region_name,
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CAST(work_emp_num AS DECIMAL(22,4))) AS work_emp_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num,
        SUM(CAST(real_use_num AS DECIMAL(22,4))) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'TRANSFER_CENTER'
        AND dt = '${bizdate}'
    GROUP BY region_code, region_name, rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        region_code,
        region_name,
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(work_emp_num AS DECIMAL(22,4)) AS work_emp_num,
        CAST(pre_use_num AS DECIMAL(22,4)) AS pre_use_num,
        CAST(real_use_num AS DECIMAL(22,4)) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'REGION_MANAGE'
        AND dt = '${bizdate}'
) act
ON exp.region_code = act.region_code
    AND exp.region_name = act.region_name
    AND exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE (ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) > 0.0 OR act.work_emp_num IS NULL)
    OR (ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) > 0.0 OR act.pre_use_num IS NULL)
    OR (ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) > 0.0 OR act.real_use_num IS NULL)
LIMIT 10;


-- ==============================================================================
-- 用例 4: REGION_MANAGE_DERIVED_use_rate
-- 验证逻辑: REGION_MANAGE.use_rate = real_use_num / pre_use_num * 100
-- 公式展开: real_use_num / pre_use_num * 100
-- 预期值来源: SUM(org_type = 'TRANSFER_CENTER') 的 real_use_num 和 pre_use_num
-- 实际值来源: org_type = 'REGION_MANAGE' 的 use_rate 列
-- ==============================================================================
SELECT
    'REGION_MANAGE_DERIVED_use_rate' AS test_case,
    exp.region_code,
    exp.region_name,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    (COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) AS expect_use_rate,
    COALESCE(act.use_rate, 0) AS actual_use_rate,
    ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) AS diff_use_rate
FROM (
    SELECT
        region_code,
        region_name,
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CAST(real_use_num AS DECIMAL(22,4))) AS real_use_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'TRANSFER_CENTER'
        AND dt = '${bizdate}'
    GROUP BY region_code, region_name, rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        region_code,
        region_name,
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(use_rate AS DECIMAL(22,4)) AS use_rate
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'REGION_MANAGE'
        AND dt = '${bizdate}'
) act
ON exp.region_code = act.region_code
    AND exp.region_name = act.region_name
    AND exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) > 0.01
    OR act.use_rate IS NULL
LIMIT 10;


-- ==============================================================================
-- 用例 5: TRANSFER_CENTER_SUM_METRICS
-- 验证逻辑: TRANSFER_CENTER = SUM(EMP) 指标汇总
-- 预期值来源: SUM(org_type = 'EMP')
-- 实际值来源: org_type = 'TRANSFER_CENTER'
-- 注意: real_use_num 使用特殊聚合规则 SUM(CASE WHEN use_times > 0 THEN 1 ELSE 0 END)
--       use_times 仅作为特殊规则的判断条件, 不作为独立校验指标
-- ==============================================================================
SELECT
    'TRANSFER_CENTER_SUM_METRICS' AS test_case,
    exp.center_code,
    exp.center_name,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    COALESCE(exp.work_emp_num, 0) AS expect_work_emp_num,
    COALESCE(act.work_emp_num, 0) AS actual_work_emp_num,
    ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) AS diff_work_emp_num,
    COALESCE(exp.pre_use_num, 0) AS expect_pre_use_num,
    COALESCE(act.pre_use_num, 0) AS actual_pre_use_num,
    ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) AS diff_pre_use_num,
    COALESCE(exp.real_use_num, 0) AS expect_real_use_num,
    COALESCE(act.real_use_num, 0) AS actual_real_use_num,
    ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) AS diff_real_use_num
FROM (
    SELECT
        center_code,
        center_name,
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CAST(work_emp_num AS DECIMAL(22,4))) AS work_emp_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num,
        SUM(CASE WHEN CAST(use_times AS DECIMAL(22,4)) > 0 THEN 1 ELSE 0 END) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'EMP'
        AND dt = '${bizdate}'
    GROUP BY center_code, center_name, rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        center_code,
        center_name,
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(work_emp_num AS DECIMAL(22,4)) AS work_emp_num,
        CAST(pre_use_num AS DECIMAL(22,4)) AS pre_use_num,
        CAST(real_use_num AS DECIMAL(22,4)) AS real_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'TRANSFER_CENTER'
        AND dt = '${bizdate}'
) act
ON exp.center_code = act.center_code
    AND exp.center_name = act.center_name
    AND exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE (ABS(COALESCE(exp.work_emp_num, 0) - COALESCE(act.work_emp_num, 0)) > 0.0 OR act.work_emp_num IS NULL)
    OR (ABS(COALESCE(exp.pre_use_num, 0) - COALESCE(act.pre_use_num, 0)) > 0.0 OR act.pre_use_num IS NULL)
    OR (ABS(COALESCE(exp.real_use_num, 0) - COALESCE(act.real_use_num, 0)) > 0.0 OR act.real_use_num IS NULL)
LIMIT 10;


-- ==============================================================================
-- 用例 6: TRANSFER_CENTER_DERIVED_use_rate
-- 验证逻辑: TRANSFER_CENTER.use_rate = real_use_num / pre_use_num * 100
-- 公式展开: real_use_num / pre_use_num * 100
-- 预期值来源: SUM(org_type = 'EMP') 的 real_use_num(特殊规则) 和 pre_use_num
-- 实际值来源: org_type = 'TRANSFER_CENTER' 的 use_rate 列
-- 注意: real_use_num 使用特殊聚合规则 SUM(CASE WHEN use_times > 0 THEN 1 ELSE 0 END)
-- ==============================================================================
SELECT
    'TRANSFER_CENTER_DERIVED_use_rate' AS test_case,
    exp.center_code,
    exp.center_name,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    (COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) AS expect_use_rate,
    COALESCE(act.use_rate, 0) AS actual_use_rate,
    ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) AS diff_use_rate
FROM (
    SELECT
        center_code,
        center_name,
        rpt_date,
        sum_type,
        first_tab_type,
        SUM(CASE WHEN CAST(use_times AS DECIMAL(22,4)) > 0 THEN 1 ELSE 0 END) AS real_use_num,
        SUM(CAST(pre_use_num AS DECIMAL(22,4))) AS pre_use_num
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'EMP'
        AND dt = '${bizdate}'
    GROUP BY center_code, center_name, rpt_date, sum_type, first_tab_type
) exp
LEFT JOIN (
    SELECT
        center_code,
        center_name,
        rpt_date,
        sum_type,
        first_tab_type,
        CAST(use_rate AS DECIMAL(22,4)) AS use_rate
    FROM export.app_schedule_use_analysis_use
    WHERE sum_type = 'D'
        AND org_type = 'TRANSFER_CENTER'
        AND dt = '${bizdate}'
) act
ON exp.center_code = act.center_code
    AND exp.center_name = act.center_name
    AND exp.rpt_date = act.rpt_date
    AND exp.sum_type = act.sum_type
    AND exp.first_tab_type = act.first_tab_type
WHERE ABS((COALESCE(exp.real_use_num, 0) / CASE WHEN COALESCE(exp.pre_use_num, 0) = 0 THEN NULL ELSE COALESCE(exp.pre_use_num, 0) END * 100) - COALESCE(act.use_rate, 0)) > 0.01
    OR act.use_rate IS NULL
LIMIT 10;
