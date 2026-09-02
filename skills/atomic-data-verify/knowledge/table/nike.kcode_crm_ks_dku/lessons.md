# kcode_crm_ks_dku 踩坑记录

- **迁移来源**：knowledge/verify-lessons.md
- **最后更新**：迁移自动生成


### 1. MySQL 语法差异

**问题**：模板中的 SQL 使用了 Hive 语法（NVL、CAST AS STRING），在 MySQL 中执行失败。

**解决**：
- NVL → COALESCE
- CAST(... AS STRING) → CAST(... AS CHAR)

**教训**：执行前需确认目标数据库类型，必要时调整 SQL 语法。


### 2. 状态判定规则

**问题**：初稿将字段比对差异标记为 ⚠️ WARN，实际应为 ❌ FAIL。

**规则**：
- 数据质量检查：允许 ⚠️ WARN（如枚举值分布不均）
- 其他检查项：只要有差异就是 ❌ FAIL

**教训**：除数据质量外，字段比对、来源追溯、筛选条件等检查项，有差异即为失败。


---


### 4. 筛选条件边界情况

**问题**：有1条记录（K25082775）的 settle_code 为 'Z25016365'（Z2开头），不符合 `settle_code LIKE 'ZK%'` 条件，但被包含在测试表中。

**解决**：验证筛选条件时，需特别注意 LIKE 模式的边界情况。

**教训**：`LIKE 'ZK%'` 只匹配 ZK 开头，不匹配 Z2 开头。ETL 筛选条件需要严格验证。


### 5. 上游表 JOIN 膨胀

**问题**：直接 LEFT JOIN 上游表时，diff_cnt 超过总记录数（4871 > 3638），原因是上游表存在重复记录。

**解决**：使用子查询 + GROUP BY 去重后再 JOIN：
```sql
LEFT JOIN (
  SELECT k_code, sales_emp_code, dt
  FROM upstream_table
  WHERE dt = '20260614' AND <筛选条件>
  GROUP BY k_code, sales_emp_code, dt
) src ON t.kcode = src.k_code AND t.dt = src.dt
```

**教训**：上游表可能有重复记录，JOIN 前需先去重，否则会导致结果膨胀。


### 6. 只验证新增记录的需求

**问题**：用户要求"只验证测试表新增数据的记录"，但初始SQL验证了所有记录。

**解决**：在SQL中添加 `NOT EXISTS` 子查询排除生产表已有的记录：
```sql
WHERE t.dt = '20260614'
  AND NOT EXISTS (
    SELECT 1 FROM production_table p
    WHERE p.kcode = t.kcode AND p.dt = t.dt
  )
```

**教训**：当用户要求只验证新增记录时，需要在 WHERE 条件中排除共同记录。
