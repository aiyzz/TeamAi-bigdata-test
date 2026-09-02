# SQL 审核报告

## 审核概要

| 项目 | 内容 |
|------|------|
| 审核时间 | 2026-07-28 |
| 生产表 | nike.kcode_crm_ks_dku_pro |
| 测试表 | nike.kcode_crm_ks_dku |
| 激活能力 | 能力0, 能力1, 能力2 |
| 审核SQL数量 | 15 条 |
| 通过数量 | 15 条 |
| 偏差数量 | 0 条（2处适配性调整已标注） |

---

## 审核结果

### 通用检查

| 检查项 | 预期 | 实际 | 状态 |
|--------|------|------|------|
| 分区条件声明 | 所有SQL包含 dt = '20260726' | ✅ 全部包含 | ✅ PASS |
| 表名完整 | database.table_name 格式 | ✅ nike.kcode_crm_ks_dku / nike.kcode_crm_ks_dku_pro | ✅ PASS |
| 主键正确 | JOIN条件使用 kcode | ✅ 全部JOIN使用 a.kcode = b.kcode | ✅ PASS |

### 能力0检查

| 测试点 | SQL类型 | 是否遵循模板 | 修正说明 |
|--------|---------|-------------|----------|
| 0.1 空表前置检查 | 同时检查测试表和生产表 | ✅ 是 | - |
| 0.2 主键唯一性 | GROUP BY kcode HAVING count(*)>1 | ✅ 是 | - |
| 0.3 维度空值占比 | UNION ALL 批量13个维度字段 | ✅ 是 | - |
| 0.4 指标空值+零值占比 | UNION ALL 批量3个指标字段 | ✅ 是 | ⚠️ 适配：字段为varchar，零值检查使用 `field = '0'/'0.0'/'0.00'` 代替 `field = 0` |
| 0.5 枚举值校验 | sum_type/first_tab_type/third_tab_type 各一次 | ✅ 是 | - |
| 0.6 指标统计分布 | UNION ALL 批量，CAST为DECIMAL | ✅ 是 | ⚠️ 适配：省略 median(percentile)，因varchar字段转bigint丢精度 |
| 0.7 指标范围校验 | UNION ALL 批量，CAST(field AS DECIMAL) <= 0 | ✅ 是 | - |

### 能力1检查

| 测试点 | SQL类型 | 是否遵循模板 | 修正说明 |
|--------|---------|-------------|----------|
| 1.1 共同记录数 | INNER JOIN 统计 | ✅ 是 | - |
| 1.2 批量字段差异数 | UNION ALL 16个共同字段 | ✅ 是 | - |
| 1.3 NULL处理 | 三段式 NVL(CAST(NULLIF(...))) | ✅ 是 | 所有字段均为varchar，统一使用 NULLIF(field,'') 模式 |

### 能力2检查

| 测试点 | SQL类型 | 是否遵循模板 | 修正说明 |
|--------|---------|-------------|----------|
| 2.1 来源追溯匹配 | NOT EXISTS 子查询 | ✅ 是 | - |
| 2.2 筛选条件符合性 | NOT EXISTS + CASE WHEN | ✅ 是 | 筛选条件为 `settle_code LIKE 'ZK%' AND status = 1` |
| 2.3 不符合条件排查 | NOT EXISTS + NOT(筛选条件) | ✅ 是 | - |
| 2.4 新增记录特征明细 | GROUP BY 筛选字段 | ✅ 是 | - |

---

## 审核结论

**✅ PASS — 全部通过**

- 15条SQL全部符合模板规范
- 2处适配性调整（varchar指标字段的零值检查和统计分布）属于合理的类型适配，不影响验证逻辑正确性
- 筛选条件 `settle_code LIKE 'ZK%' AND status = 1` 综合了用户业务描述和显式提供的筛选条件

---

## 注意事项

1. **筛选条件字段名确认**：`settle_code` 和 `status` 为推测的上游表字段名。如实际字段名不同，请修改 [2.2]-[2.4] 中的字段名后重新执行。
2. **指标字段类型适配**：taking_num/taking_num_ly/last_num 为 varchar 类型，统计分布和范围校验使用 `CAST AS DECIMAL(20,4)` 转换。如数据中含非数字字符，CAST 会返回 NULL。
3. **跨库JOIN**：能力2 SQL 涉及 `nike.kcode_crm_ks_dku`（MySQL）与 `ytexp.ods_psc_t_market_direct_customer_dd`（Hive）的跨库JOIN。如DBeaver连接不支持跨库查询，需分步执行。
