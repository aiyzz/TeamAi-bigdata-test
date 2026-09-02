import json

with open('test_cases.json', 'r', encoding='utf-8') as f:
    test_cases = json.load(f)

fixed_cases = []

for tc in test_cases:
    sql = tc['sql']

    if 'DERIVED' in tc['name']:
        # 提取层级信息
        if 'HEAD' in tc['name']:
            org_filter_exp = "org_type = 'REGION_MANAGE'"
            org_filter_act = "org_type = 'HEAD'"
            group_by = 'dt, rpt_date, sum_type, first_tab_type'
            join_cond = 'exp.dt = act.dt AND exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type'
            region_field = ''
        else:
            org_filter_exp = "org_type = 'TRANSFER_CENTER'"
            org_filter_act = "org_type = 'REGION_MANAGE'"
            group_by = 'dt, rpt_date, sum_type, first_tab_type, region_code'
            join_cond = 'exp.dt = act.dt AND exp.rpt_date = act.rpt_date AND exp.sum_type = act.sum_type AND exp.first_tab_type = act.first_tab_type AND exp.region_code = act.region_code'
            region_field = 'exp.region_code,'

        if 'use_rate_diff' in tc['name']:
            derived_formula = """(COALESCE(SUM(CAST(use_num AS DECIMAL(22,4))), 0) / NULLIF(COALESCE(SUM(CAST(should_use_num AS DECIMAL(22,4))), 0), 0) * 100)
        - (COALESCE(SUM(CAST(use_num_lp AS DECIMAL(22,4))), 0) / NULLIF(COALESCE(SUM(CAST(should_use_num_lp AS DECIMAL(22,4))), 0), 0) * 100) AS exp_value"""
            field_name = 'use_rate_diff'
        elif 'use_rate_lp' in tc['name']:
            derived_formula = "COALESCE(SUM(CAST(use_num_lp AS DECIMAL(22,4))), 0) / NULLIF(COALESCE(SUM(CAST(should_use_num_lp AS DECIMAL(22,4))), 0), 0) * 100 AS exp_value"
            field_name = 'use_rate_lp'
        else:
            derived_formula = "COALESCE(SUM(CAST(use_num AS DECIMAL(22,4))), 0) / NULLIF(COALESCE(SUM(CAST(should_use_num AS DECIMAL(22,4))), 0), 0) * 100 AS exp_value"
            field_name = 'use_rate'

        fixed_sql = f"""SELECT
    '{tc['name']}' AS test_case,
    exp.dt,
    exp.rpt_date,
    exp.sum_type,
    exp.first_tab_type,
    {region_field}
    exp.exp_value AS expect_{field_name},
    COALESCE(act.{field_name}, 0) AS actual_{field_name},
    ABS(exp.exp_value - COALESCE(act.{field_name}, 0)) AS diff_{field_name}
FROM (
    SELECT
        dt, rpt_date, sum_type, first_tab_type,
        {derived_formula}
    FROM nike.app_leader_assistant_use_monitor_total
    WHERE sum_type = 'D' AND ({org_filter_exp}) AND dt = '20260613'
    GROUP BY {group_by}
) exp
LEFT JOIN (
    SELECT
        dt, rpt_date, sum_type, first_tab_type,
        CAST({field_name} AS DECIMAL(22,4)) AS {field_name}
    FROM nike.app_leader_assistant_use_monitor_total
    WHERE sum_type = 'D' AND {org_filter_act} AND dt = '20260613'
    GROUP BY {group_by}
) act
ON {join_cond}
WHERE ABS(exp.exp_value - COALESCE(act.{field_name}, 0)) > 0.0 OR act.{field_name} IS NULL
LIMIT 10;"""

        fixed_cases.append({
            'name': tc['name'],
            'description': tc['description'],
            'sql': fixed_sql
        })
    else:
        fixed_cases.append(tc)

with open('test_cases_fixed.json', 'w', encoding='utf-8') as f:
    json.dump(fixed_cases, f, ensure_ascii=False, indent=2)

print(f'Fixed {len(fixed_cases)} test cases')
