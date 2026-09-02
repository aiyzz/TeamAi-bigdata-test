# 验数通用规则

## 状态判定规则

| 检查项 | ❌ FAIL | ⚠️ WARN | ✅ PASS |
|--------|---------|---------|---------|
| 主键唯一性 | 重复 > 0 | - | 重复 = 0 |
| 维度空值占比 | - | > 5% | ≤ 5% |
| 指标空值零值占比 | - | > 30% | ≤ 30% |
| 字段比对差异 | diff_cnt > 0 | - | diff_cnt = 0 |
| 来源追溯匹配 | 匹配率 < 100% | - | 匹配率 = 100% |
| 筛选条件符合 | 不符合条件 > 0 | - | 不符合条件 = 0 |

**整体结论判定**：
- 存在任何 ❌ FAIL → 不通过 ❌
- 仅存在 ⚠️ WARN → 通过（附警告） ✅⚠️
- 全部 ✅ PASS → 通过 ✅

---

## NULL 处理规则

### 字段比对时的归一化模式

| 字段类型 | 处理方式 |
|----------|----------|
| varchar | COALESCE(CAST(NULLIF(field, '') AS CHAR), 'XXT') |
| int/bigint | COALESCE(CAST(field AS CHAR), 'XXT') |
| decimal/float | COALESCE(CAST(field AS CHAR), 'XXT') |

### 哨兵值选择

- 使用 'XXT' 作为 NULL 的哨兵值
- 确保哨兵值不出现在业务数据中
- NULL 和空字符串统一归一化为哨兵值

---

## MySQL 语法注意事项

### 1. NVL 函数
MySQL 不支持 NVL，需使用 COALESCE 替代：
- Oracle/Hive: NVL(field, 'default')
- MySQL: COALESCE(field, 'default')

### 2. CAST 类型转换
MySQL 不支持 CAST(... AS STRING)，需使用 CAST(... AS CHAR)

### 3. int/bigint 字段的 NULL 处理
- int/bigint: COALESCE(CAST(field AS CHAR), 'XXT')
- varchar: COALESCE(CAST(NULLIF(field, '') AS CHAR), 'XXT')

---

## JOIN 膨胀防护

当上游表可能有重复记录时，使用子查询去重：

```sql
LEFT JOIN (
  SELECT key_field, target_field, dt
  FROM upstream_table
  WHERE dt = '{partition}' AND {filter}
  GROUP BY key_field, target_field, dt
) src ON t.key = src.key_field AND t.dt = src.dt
```

---

## 验证范围控制

当用户要求"只验证新增记录"时，添加 NOT EXISTS 排除共同记录：

```sql
WHERE t.dt = '{partition}'
  AND NOT EXISTS (
    SELECT 1 FROM production_table p
    WHERE p.pk = t.pk AND p.dt = t.dt
  )
```

---

## 能力职责边界

### 能力2 vs 能力4 的分工

| 能力 | 职责 | 验证内容 | 不验证 |
|------|------|----------|--------|
| 能力2 | 验证新增记录 | 记录数、来源追溯、筛选条件 | 字段值 |
| 能力4 | 验证字段正确性 | 新增字段值、原有字段保护 | 记录来源 |

### 关键规则

1. **能力2 不验证字段**：只关注"数据从哪来、是否符合条件"
2. **能力4 验证字段**：关注"字段值是否正确"
3. **新增记录的字段验证**：使用能力4 + NOT EXISTS 条件

### 典型场景

| 用户需求 | 正确做法 |
|----------|----------|
| "验证新增记录" | 能力2（记录数+来源+筛选） |
| "验证新增记录的某个字段" | 能力4 + NOT EXISTS |
| "验证新增字段" | 能力4（全量或按需加 NOT EXISTS） |
| "验证新增记录的新增字段" | 能力4 + NOT EXISTS |
