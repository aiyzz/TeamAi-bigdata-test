# 数仓汇总验证测试报告

## 配置摘要

| 项目 | 值 |
|------|-----|
| 表名 | export.app_schedule_use_analysis_use |
| 表注释 | 智能排班-使用分析-使用 |
| 模式 | single_table |
| 分区字段 | dt |
| 时间粒度字段 | sum_type（D-日, M-月, Y-年） |
| 日期字段 | rpt_date |
| 测试时间 | 2026-07-30 |
| 审核结论 | PASS（26项全部通过） |

## 组织层级

| 枚举值 | 含义 | 编码字段 |
|--------|------|----------|
| HEAD | 全国 | org_code |
| REGION_MANAGE | 省区 | region_code |
| TRANSFER_CENTER | 中心 | center_code |
| EMP | 人员 | emp_code |

## 指标定义

| 指标编码 | 中文名 | 聚合方式 | 公式 |
|----------|--------|----------|------|
| work_emp_num | 在职人数 | SUM | - |
| pre_use_num | 应使用人数 | SUM | - |
| real_use_num | 实际使用人数 | SUM | - |
| use_rate | 使用率 | DERIVED | real_use_num / pre_use_num * 100 |

> 注: use_times(使用次数) 不作为独立校验指标, 仅在 TRANSFER_CENTER 层级作为 real_use_num 特殊规则的判断条件 (use_times > 0)。

## 特殊规则

| 规则 | 说明 |
|------|------|
| real_use_num 特殊聚合 | EMP -> TRANSFER_CENTER 汇总时，real_use_num = SUM(CASE WHEN use_times > 0 THEN 1 ELSE 0 END)（use_times 仅作判断条件，不校验） |
| 分组维度排除 | position_code/position_name、dept_code/dept_name、dept_head_code/dept_head_name 不作为分组维度 |

## 测试用例总览

共生成 6 个测试用例：

| 用例名称 | 验证逻辑 | 类型 |
|----------|----------|------|
| HEAD_SUM_METRICS | HEAD = SUM(REGION_MANAGE) 指标汇总 | 层级汇总 |
| HEAD_DERIVED_use_rate | HEAD.use_rate = real_use_num / pre_use_num * 100 | 率值验证 |
| REGION_MANAGE_SUM_METRICS | REGION_MANAGE = SUM(TRANSFER_CENTER) 指标汇总 | 层级汇总 |
| REGION_MANAGE_DERIVED_use_rate | REGION_MANAGE.use_rate = real_use_num / pre_use_num * 100 | 率值验证 |
| TRANSFER_CENTER_SUM_METRICS | TRANSFER_CENTER = SUM(EMP) 指标汇总（含特殊规则） | 层级汇总 |
| TRANSFER_CENTER_DERIVED_use_rate | TRANSFER_CENTER.use_rate = real_use_num / pre_use_num * 100（含特殊规则） | 率值验证 |

## 层级验证逻辑

```
HEAD = SUM(REGION_MANAGE)          ── 指标: work_emp_num, pre_use_num, real_use_num
  └─ REGION_MANAGE = SUM(TRANSFER_CENTER)  ── 指标: work_emp_num, pre_use_num, real_use_num
       └─ TRANSFER_CENTER = SUM(EMP)        ── 指标: work_emp_num, pre_use_num, real_use_num(特殊)
            └─ EMP (最底层，无子级)
```

## 分组字段

| 层级 | 分组字段 |
|------|----------|
| HEAD = SUM(REGION_MANAGE) | rpt_date, sum_type, first_tab_type |
| REGION_MANAGE = SUM(TRANSFER_CENTER) | region_code, region_name, rpt_date, sum_type, first_tab_type |
| TRANSFER_CENTER = SUM(EMP) | center_code, center_name, rpt_date, sum_type, first_tab_type |

## 测试结果

> MCP 服务未连接，采用手动执行模式。

**执行方式：**
1. 打开 SQL 文件：`validation_results/2026-07-30/app_schedule_use_analysis_use/single/app_schedule_use_analysis_use.sql`
2. 将 `${bizdate}` 替换为实际分区日期（如 `'20260730'`）
3. 在数据库客户端中逐条执行 6 个测试用例
4. 将执行结果提供给助手，可帮助分析并生成最终报告

**结果判断标准：**

| 结果 | 含义 |
|------|------|
| 返回空结果 | ✅ PASS，无差异，验证通过 |
| 返回有数据 | ❌ FAIL，存在差异，需排查 |

## 文件清单

| 文件 | 路径 |
|------|------|
| JSON 配置 | configs/app_schedule_use_analysis_use.json |
| 审核报告 | validation_results/2026-07-30/app_schedule_use_analysis_use/single/app_schedule_use_analysis_use_audit.txt |
| 测试 SQL | validation_results/2026-07-30/app_schedule_use_analysis_use/single/app_schedule_use_analysis_use.sql |
| 测试报告 | report/2026-07-30/app_schedule_use_analysis_use_report.md |
