# SQL 审核报告

## 审核概要

| 项目 | 内容 |
|------|------|
| 审核时间 | 2026-06-22 |
| 激活能力 | 能力0, 能力1, 能力2, 能力4 |
| 审核SQL数量 | 19 条 |
| 通过数量 | 19 条 |
| 偏差数量 | 0 条 |

---

## 审核结果

| 测试点 | SQL 类型 | 是否遵循模板 | 修正说明 |
|--------|----------|-------------|----------|
| 0.1 | 空表前置检查 | ✅ 是 | - |
| 0.2 | 主键唯一性 | ✅ 是 | - |
| 0.3 | 维度字段空值占比 | ✅ 是 | 16个维度字段批量UNION ALL |
| 0.4 | 指标字段空值零值 | ✅ 是 | 3个指标字段批量UNION ALL |
| 0.5 | 枚举值校验 | ✅ 是 | first_tab_type, third_tab_type |
| 1.1 | 共同记录数 | ✅ 是 | INNER JOIN |
| 1.2 | 字段比对 | ✅ 是 | 归一化模式（MySQL推荐），14个共同字段 |
| 2.1 | 新增记录数 | ✅ 是 | LEFT JOIN + IS NULL |
| 2.2 | 来源追溯匹配 | ✅ 是 | NOT EXISTS + LEFT JOIN |
| 2.3 | 筛选条件符合性 | ✅ 是 | NOT EXISTS + CASE WHEN |
| 2.4 | 字段验证 sale_emp_code | ✅ 是 | 直接映射比对 |
| 2.5 | 字段验证 sale_emp_name | ✅ 是 | 直接映射比对 |
| 2.6 | 不符合条件排查 | ✅ 是 | 明细查询 LIMIT 20 |
| 2.7 | 字段差异明细 | ✅ 是 | 差异行展示 |
| 4.1 | 新增字段清单 | ✅ 是 | information_schema 查询 |
| 4.2 | 新增字段空值检查 | ✅ 是 | 2个字段批量UNION ALL |
| 4.3 | 字段验证 sale_emp_code | ✅ 是 | 全量直接映射比对 |
| 4.4 | 字段验证 sale_emp_name | ✅ 是 | 全量直接映射比对 |
| 4.5 | 字段差异明细 | ✅ 是 | 差异行展示 LIMIT 20 |

**审核结论**：✅ 全部通过

---

## 审核说明

### MySQL 语法适配

本验证使用 MySQL 数据库，SQL 已适配以下语法差异：

| Hive 语法 | MySQL 语法 | 说明 |
|-----------|------------|------|
| NVL() | COALESCE() | MySQL 不支持 NVL |
| CAST(... AS STRING) | CAST(... AS CHAR) | MySQL 不支持 STRING 类型 |
| NULLIF + NVL | NULLIF + COALESCE | 归一化模式处理 NULL 和空字符串 |

### 归一化模式说明

字段比对使用归一化模式而非三段式：

```sql
-- 归一化模式（本SQL使用）
COALESCE(CAST(NULLIF(a.field,'') AS CHAR), 'XXT') <> COALESCE(CAST(NULLIF(b.field,'') AS CHAR), 'XXT')

-- 三段式（模板原始写法）
a.field != b.field OR (a.field IS NULL AND b.field IS NOT NULL) OR (a.field IS NOT NULL AND b.field IS NULL)
```

两种写法等效，归一化模式更简洁，且符合 `knowledge/global/sql-patterns.md` 中的 MySQL 推荐写法。

---

## 审核通过的 SQL

> 详见 `report/2026-06-22/kcode_crm_ks_dku_sql_draft.md`

所有 SQL 已通过审核，可直接执行。
