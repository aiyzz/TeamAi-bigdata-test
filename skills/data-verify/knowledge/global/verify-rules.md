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

> 本技能统一使用 Hive 语法（NVL + CAST AS STRING）。详细说明见 `sql-patterns.md`。

| 字段类型 | 处理方式 |
|----------|----------|
| varchar / char / string | NVL(CAST(NULLIF(field, '') AS STRING), 'XXT') |
| int / bigint | NVL(CAST(field AS STRING), 'XXT') |
| decimal / float / double | NVL(CAST(field AS STRING), 'XXT') |

> 数值类型字段（int/bigint/decimal/float）不要套用 `NULLIF(field, '')`，直接 `NVL(CAST(field AS STRING), 'XXT')`。

### 哨兵值选择

- 使用 'XXT' 作为 NULL 的哨兵值
- 确保哨兵值不出现在业务数据中
- NULL 和空字符串统一归一化为哨兵值

---

## Hive 语法注意事项

> 本技能统一按 Hive SQL 生成验证脚本。

### 1. NVL 函数
Hive 支持 NVL，统一用 NVL 做 NULL 归一化：
- Hive: `NVL(field, 'default')`

### 2. CAST 类型转换
Hive 使用 `CAST(... AS STRING)`（不要用 `CAST(... AS CHAR)`，那是 MySQL 写法）

### 3. int/bigint 字段的 NULL 处理
- int/bigint/decimal/float: `NVL(CAST(field AS STRING), 'XXT')`（无需 NULLIF）
- varchar: `NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')`

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
