-- ============================================================
-- 数仓汇总验证 SQL
-- 表: app_close_ring_total_d（单表模式）
-- 生成时间: 2026-04-25
-- 使用方式: 将 @dt 替换为目标日期分区值，如 '2026-04-24'
-- ============================================================

-- ============================================================
-- 测试用例 1: HEAD(全国) = SUM(TEAM 数据)
-- 验证逻辑: 全国层的闭环量 = 所有客户团队层的闭环量之和
-- 验证指标: should_close_ring_num, close_ring_num
-- ============================================================
WITH head_val AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'HEAD'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type
),
team_sum AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'TEAM'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type
)
SELECT
  'HEAD vs TEAM' AS test_case,
  h.rpt_date,
  h.sum_type,
  h.first_tab_type,
  h.second_tab_type,
  h.third_tab_type,
  h.should_close_ring_num AS head_should_close,
  t.should_close_ring_num AS team_sum_should_close,
  ABS(h.should_close_ring_num - t.should_close_ring_num) AS diff_should_close,
  h.close_ring_num        AS head_close,
  t.close_ring_num        AS team_sum_close,
  ABS(h.close_ring_num - t.close_ring_num) AS diff_close
FROM head_val h
LEFT JOIN team_sum t
  ON  h.rpt_date         = t.rpt_date
  AND h.sum_type         = t.sum_type
  AND h.first_tab_type   = t.first_tab_type
  AND h.second_tab_type  = t.second_tab_type
  AND h.third_tab_type   = t.third_tab_type
WHERE ABS(h.should_close_ring_num - t.should_close_ring_num) > 0.0001
   OR ABS(h.close_ring_num - t.close_ring_num) > 0.0001;


-- ============================================================
-- 测试用例 2: TEAM = SUM(GROUPS 数据)
-- 验证逻辑: 客户团队层的闭环量 = 所有客服组层的闭环量之和
-- 验证指标: should_close_ring_num, close_ring_num
-- ============================================================
WITH team_val AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, team_code,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'TEAM'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, team_code
),
groups_sum AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, team_code,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'GROUPS'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, team_code
)
SELECT
  'TEAM vs GROUPS' AS test_case,
  t.rpt_date,
  t.sum_type,
  t.first_tab_type,
  t.second_tab_type,
  t.third_tab_type,
  t.team_code,
  t.should_close_ring_num AS team_should_close,
  g.should_close_ring_num AS groups_sum_should_close,
  ABS(t.should_close_ring_num - g.should_close_ring_num) AS diff_should_close,
  t.close_ring_num        AS team_close,
  g.close_ring_num        AS groups_sum_close,
  ABS(t.close_ring_num - g.close_ring_num) AS diff_close
FROM team_val t
LEFT JOIN groups_sum g
  ON  t.rpt_date         = g.rpt_date
  AND t.sum_type         = g.sum_type
  AND t.first_tab_type   = g.first_tab_type
  AND t.second_tab_type  = g.second_tab_type
  AND t.third_tab_type   = g.third_tab_type
  AND t.team_code        = g.team_code
WHERE ABS(t.should_close_ring_num - g.should_close_ring_num) > 0.0001
   OR ABS(t.close_ring_num - g.close_ring_num) > 0.0001;


-- ============================================================
-- 测试用例 3: GROUPS = SUM(EMP 数据)
-- 验证逻辑: 客服组层的闭环量 = 所有客服层的闭环量之和
-- 验证指标: should_close_ring_num, close_ring_num
-- ============================================================
WITH groups_val AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, groups_code,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'GROUPS'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, groups_code
),
emp_sum AS (
  SELECT
    rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, groups_code,
    SUM(should_close_ring_num) AS should_close_ring_num,
    SUM(close_ring_num)        AS close_ring_num
  FROM app_close_ring_total_d
  WHERE org_type = 'EMP'
    AND rpt_date = @dt
  GROUP BY rpt_date, sum_type, first_tab_type, second_tab_type, third_tab_type, groups_code
)
SELECT
  'GROUPS vs EMP' AS test_case,
  g.rpt_date,
  g.sum_type,
  g.first_tab_type,
  g.second_tab_type,
  g.third_tab_type,
  g.groups_code,
  g.should_close_ring_num AS groups_should_close,
  e.should_close_ring_num AS emp_sum_should_close,
  ABS(g.should_close_ring_num - e.should_close_ring_num) AS diff_should_close,
  g.close_ring_num        AS groups_close,
  e.close_ring_num        AS emp_sum_close,
  ABS(g.close_ring_num - e.close_ring_num) AS diff_close
FROM groups_val g
LEFT JOIN emp_sum e
  ON  g.rpt_date         = e.rpt_date
  AND g.sum_type         = e.sum_type
  AND g.first_tab_type   = e.first_tab_type
  AND g.second_tab_type  = e.second_tab_type
  AND g.third_tab_type   = e.third_tab_type
  AND g.groups_code      = e.groups_code
WHERE ABS(g.should_close_ring_num - e.should_close_ring_num) > 0.0001
   OR ABS(g.close_ring_num - e.close_ring_num) > 0.0001;


-- ============================================================
-- 测试用例 4: close_ring_rate 率值验证
-- 验证逻辑: close_ring_rate = close_ring_num / should_close_ring_num
-- 全层级验证
-- ============================================================
SELECT
  'close_ring_rate' AS test_case,
  rpt_date,
  sum_type,
  org_type,
  org_code,
  close_ring_num,
  should_close_ring_num,
  close_ring_rate AS actual_rate,
  CASE
    WHEN should_close_ring_num = 0 THEN NULL
    ELSE ROUND(close_ring_num / should_close_ring_num, 4)
  END AS expected_rate,
  ABS(close_ring_rate - CASE
    WHEN should_close_ring_num = 0 THEN NULL
    ELSE ROUND(close_ring_num / should_close_ring_num, 4)
  END) AS diff
FROM app_close_ring_total_d
WHERE rpt_date = @dt
  AND ABS(close_ring_rate - CASE
    WHEN should_close_ring_num = 0 THEN NULL
    ELSE ROUND(close_ring_num / should_close_ring_num, 4)
  END) > 0.0001;
