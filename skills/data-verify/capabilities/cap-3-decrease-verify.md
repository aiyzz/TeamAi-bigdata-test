# 能力 3：验证减少记录

> 验证测试表中被剔除的数据是否符合预期：全部命中剔除条件、无误删、无漏删。

---

## 触发条件

| 条件 | 说明 |
|------|------|
| 测试表记录数 < 生产表记录数 | 数据量减少 |
| RIGHT JOIN 发现生产表独有记录 > 0 | 存在被剔除记录 |
| 需求文档提到「剔除」「筛选条件」「过滤」 | 业务预期减少 |

---

## 输入

| 参数 | 必填 | 说明 |
|------|------|------|
| 生产表名 | 是 | 基准表 |
| 测试表名 | 是 | 优化后的表 |
| 主键 | 是 | JOIN 键 |
| 分区值 | 否 | 如有分区字段则必填 |
| 剔除基准表 | 条件必填 | 方式A：新增的剔除基准表 |
| 剔除条件 | 条件必填 | 方式B：新增的筛选条件 |

> 方式A 和方式B 至少提供一个。

---

## SQL 模板

- 主流程：`templates/common/diff-rows-count-sql.md`（数据量统计，主流程执行）
- 能力专用：`templates/cap-3-decrease-verify-sql.md`（剔除逻辑验证）

---

## 验证步骤

### Step 1: 统计减少条数

```sql
SELECT count(*) AS removed_cnt
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
```

### Step 2: 提取被剔除记录明细

```sql
SELECT b.<主键>
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
LIMIT 10
```

### Step 3: 来源追溯匹配验证

按 `cap-3-decrease-verify-sql.md` 二 执行，支持两种方式：

**方式A（剔除基准表）**：
```sql
SELECT
  SUM(CASE WHEN src.<关联字段> IS NOT NULL THEN 1 ELSE 0 END) AS match_exclude_cnt,
  SUM(CASE WHEN src.<关联字段> IS NULL THEN 1 ELSE 0 END) AS no_match_cnt
FROM (
  SELECT b.<主键> FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
LEFT JOIN <剔除基准表> src ON removed.<主键> = src.<关联字段> AND src.dt = '<分区值>'
```

**方式B（筛选条件）**：
```sql
SELECT
  SUM(CASE WHEN <剔除条件> THEN 1 ELSE 0 END) AS match_filter_cnt,
  SUM(CASE WHEN NOT (<剔除条件>) THEN 1 ELSE 0 END) AS no_match_cnt
FROM (
  SELECT b.* FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
```

**预期**：match_cnt = removed_cnt，no_match_cnt = 0

### Step 4: 被剔除数据特征明细

按 `cap-3-decrease-verify-sql.md` 三 执行，分析被剔除记录在各维度上的分布。

### Step 5: 误删排查

按 `cap-3-decrease-verify-sql.md` 四 执行：

```sql
-- 方式A
SELECT removed.<主键>
FROM (
  SELECT b.* FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
LEFT JOIN <剔除基准表> src ON removed.<主键> = src.<关联字段> AND src.dt = '<分区值>'
WHERE src.<关联字段> IS NULL
LIMIT 20
```

**预期**：0 条（无误删）

### Step 6: 反向验证（漏删检查）

按 `cap-3-decrease-verify-sql.md` 五 执行：

```sql
SELECT
  SUM(CASE WHEN <剔除条件> THEN 1 ELSE 0 END) AS should_be_removed,
  SUM(CASE WHEN NOT (<剔除条件>) THEN 1 ELSE 0 END) AS correct_kept
FROM <测试表>
WHERE dt = '<分区值>'
```

**预期**：should_be_removed = 0

### Step 7: 交叉验证（四象限）

按 `cap-3-decrease-verify-sql.md` 六 执行：

| 验证项 | SQL | 预期 |
|--------|-----|------|
| 应剔除且已剔除 | correctly_removed | = removed_cnt |
| 应保留且已保留 | correctly_kept | = 测试表记录数 |
| 应剔除但未剔除（漏删） | missed_removal | = 0 |
| 应保留但被剔除（误删） | false_removal | = 0 |

---

## 验证标准

| 验证项 | 预期 | 状态 |
|--------|------|------|
| removed_cnt > 0 | > 0 | ✅ / ❌ = 0（数据量无变化） |
| 来源追溯 match_cnt = removed_cnt | 100% | ✅ / ❌ < 100% |
| 误删记录数 | 0 | ✅ / ❌ > 0 |
| 漏删记录数（should_be_removed） | 0 | ✅ / ❌ > 0 |
| correctly_removed = removed_cnt | 一致 | ✅ / ❌ 不一致 |
| false_removal | 0 | ✅ / ❌ > 0 |

---

## 输出格式

```markdown
## 减少记录验证

- 被剔除记录数：X
- 命中剔除条件数：Y（命中率：Z%）
- 误删排查：0 条 / N 条

### 来源追溯
| 匹配状态 | 数量 |
|----------|------|

### 被剔除数据特征明细
| 特征字段 | 值 | 数量 |
|----------|------|------|

### 反向验证
| 验证项 | 结果 | 状态 |
|--------|------|------|
| 应剔除且已剔除 | X | ✅ |
| 应保留且已保留 | Y | ✅ |
| 漏删 | 0 | ✅ |
| 误删 | 0 | ✅ |
```
