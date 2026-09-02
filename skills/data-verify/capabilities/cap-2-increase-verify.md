# 能力 2：验证增加记录

> 验证测试表中新增的数据是否符合预期：来源可追溯、筛选条件正确、ETL 转换正确。

---

## 触发条件

| 条件 | 说明 |
|------|------|
| 测试表记录数 > 生产表记录数 | 数据量增加 |
| LEFT JOIN 发现测试表独有记录 > 0 | 存在新增记录 |
| 需求文档提到「新增数据源」「扩展」 | 业务预期增加 |

---

## 输入

| 参数 | 必填 | 说明 | 来源 |
|------|------|------|------|
| 生产表名 | 是 | 基准表 | 知识库 |
| 测试表名 | 是 | 优化后的表 | 知识库 |
| 主键 | 是 | JOIN 键 | 知识库 |
| 分区值 | 否 | 如有分区字段则必填 | Step 0 自动识别 |
| 上游表 | 是 | 新增数据的来源表 | Step 3.2 用户确认 |
| 关联键 | 是 | 测试表与上游表的关联字段 | Step 3.2 用户确认 |
| 筛选条件 | 是 | 新增数据应满足的筛选逻辑 | Step 3.2 用户确认 |
| ETL 转换逻辑 | 否 | 新增字段的转换规则 | Step 3.2 用户确认 |

---

## SQL 模板

- 主流程：`templates/common/diff-rows-count-sql.md`（数据量统计，主流程执行）
- 能力专用：`templates/cap-2-increase-verify-sql.md`（来源追溯、筛选条件验证）

---

## 验证步骤

### Step 1: 统计新增条数

```sql
SELECT count(*) AS added_cnt
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

### Step 2: 提取新增记录明细

```sql
SELECT a.<主键>
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
LIMIT 10
```

### Step 3: 来源追溯匹配验证（需上游表）

按 `cap-2-increase-verify-sql.md` 一 执行：

```sql
SELECT
  CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END AS match_status,
  COUNT(*) AS cnt
FROM <测试表> t
LEFT JOIN <上游表> o ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END
```

**预期**：匹配数 = 新增数

### Step 4: 筛选条件符合性验证（需筛选条件）

按 `cap-2-increase-verify-sql.md` 二 执行：

```sql
SELECT
  CASE WHEN <筛选条件> THEN '符合条件' ELSE '不符合条件' END AS filter_status,
  COUNT(*) AS cnt
FROM <测试表> t
INNER JOIN <上游表> o ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE WHEN <筛选条件> THEN '符合条件' ELSE '不符合条件' END
```

**预期**：符合条件数 = 新增数

### Step 5: 不符合条件数据排查

按 `cap-2-increase-verify-sql.md` 三 执行，预期 0 条。

### Step 6: ETL 转换逻辑验证（需转换逻辑）

按 `cap-4-schema-change-sql.md` 四（D3 ETL 转换）逐字段验证转换正确性。

---

## 验证标准

| 验证项 | 预期 | 状态 |
|--------|------|------|
| 新增数 > 0 | > 0 | ✅ / ❌ = 0 |
| 来源匹配数 = 新增数 | 100% | ✅ / ❌ < 100% |
| 符合筛选条件数 = 新增数 | 100% | ✅ / ❌ < 100% |
| 不符合条件数据 | 0 条 | ✅ / ❌ > 0 |
| ETL 转换 diff_cnt = 0 | 0 | ✅ / ❌ > 0 |

---

## 输出格式

```markdown
## 增加记录验证

- 新增记录数：X
- 来源匹配数：Y（命中率：Z%）

### 来源追溯
| 匹配状态 | 数量 |
|----------|------|

### 筛选条件符合性
| 状态 | 数量 |
|------|------|

### ETL 转换验证（如有）
| 字段 | 转换类型 | 差异数 | 状态 |
|------|----------|--------|------|
```
