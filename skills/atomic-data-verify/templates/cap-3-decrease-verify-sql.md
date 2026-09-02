# 能力3：验证减少记录 SQL 模板

> 本文件为能力3（验证减少记录）的 SQL 模板。
> 用于验证测试表中被剔除的数据是否符合预期：全部命中剔除条件、无误删、无漏删。
> 模板中 `<生产表>`、`<测试表>`、`<剔除基准表>`、`<主键>`、`<关联字段>`、`<分区值>`、`<剔除条件>`、`<特征字段>` 为占位符，执行时替换为实际值。

---

## 一、被剔除数据提取

### 1. 被剔除记录明细（RIGHT JOIN）

```sql
SELECT b.<主键>
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
LIMIT 10
```

**说明**：RIGHT JOIN 以生产表为主表，测试表主键为 NULL 的记录即为被剔除记录。

**预期**：返回被剔除的记录主键列表。

---

### 2. 被剔除记录数统计

```sql
SELECT count(*) AS removed_cnt
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
```

**预期**：removed_cnt = 生产表记录数 - 测试表记录数。

---

### 3. 被剔除记录完整字段（用于后续分析）

```sql
SELECT b.*
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
```

**用途**：作为子查询供后续来源追溯、特征分析使用。

---

## 二、来源追溯匹配验证

> 验证被剔除记录是否全部符合剔除条件。
> 支持两种剔除方式：方式A（剔除基准表）、方式B（新增筛选条件）。

### 方式A：基于剔除基准表

> 适用场景：新增一张表作为剔除基准，被剔除记录应全部在基准表中。

```sql
SELECT 
  SUM(CASE WHEN src.<关联字段> IS NOT NULL THEN 1 ELSE 0 END) AS match_exclude_cnt,
  SUM(CASE WHEN src.<关联字段> IS NULL THEN 1 ELSE 0 END) AS no_match_cnt
FROM (
  SELECT b.<主键>
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
LEFT JOIN <剔除基准表> src 
  ON removed.<主键> = src.<关联字段> 
  AND src.dt = '<分区值>'
```

**验证标准**：

| 指标 | 预期 | 说明 |
|------|------|------|
| match_exclude_cnt | = removed_cnt | 被剔除记录全部在基准表中 |
| no_match_cnt | = 0 | 无未匹配记录 |

---

### 方式B：基于新增筛选条件

> 适用场景：在原有逻辑上增加筛选条件，不符合新条件的记录被剔除。

```sql
SELECT 
  SUM(CASE WHEN <剔除条件> THEN 1 ELSE 0 END) AS match_filter_cnt,
  SUM(CASE WHEN NOT (<剔除条件>) THEN 1 ELSE 0 END) AS no_match_cnt
FROM (
  SELECT b.*
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
```

**验证标准**：

| 指标 | 预期 | 说明 |
|------|------|------|
| match_filter_cnt | = removed_cnt | 被剔除记录全部不符合新条件 |
| no_match_cnt | = 0 | 无符合新条件的记录被剔除 |

---

### 占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<剔除基准表>` | 用于剔除的来源表 | `nike.ods_jsc_t_market_direct_customer_dd` |
| `<关联字段>` | 测试表与剔除基准表的关联字段 | `kcode` / `k_code` |
| `<剔除条件>` | 剔除的 SQL 条件 | `settle_code LIKE 'ZK%' AND status = '1'` |

---

## 三、被剔除数据特征明细

> 分析被剔除记录在各维度上的分布。

### 1. 单字段特征分布

```sql
SELECT 
  removed.<特征字段>,
  COUNT(*) AS cnt
FROM (
  SELECT b.*
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
GROUP BY removed.<特征字段>
ORDER BY cnt DESC
```

---

### 2. 多字段特征分布

```sql
SELECT 
  removed.<特征字段1>,
  removed.<特征字段2>,
  COUNT(*) AS cnt
FROM (
  SELECT b.*
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
GROUP BY removed.<特征字段1>, removed.<特征字段2>
ORDER BY cnt DESC
```

---

## 四、误删排查

> 排查不符合剔除条件的记录是否被误删。

### 方式A：基于剔除基准表

```sql
SELECT removed.<主键>
FROM (
  SELECT b.*
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
LEFT JOIN <剔除基准表> src 
  ON removed.<主键> = src.<关联字段> 
  AND src.dt = '<分区值>'
WHERE src.<关联字段> IS NULL
LIMIT 20
```

**预期**：0 条（无误删）。

---

### 方式B：基于新增筛选条件

```sql
SELECT removed.<主键>
FROM (
  SELECT b.*
  FROM <测试表> a
  RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
  WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
) removed
WHERE NOT (<剔除条件>)
LIMIT 20
```

**预期**：0 条（无误删）。

---

## 五、反向验证

> 验证剩余记录（测试表中的记录）是否都不符合剔除条件（无漏删）。

### 1. 剩余数据剔除条件检查

```sql
SELECT 
  SUM(CASE WHEN <剔除条件> THEN 1 ELSE 0 END) AS should_be_removed,
  SUM(CASE WHEN NOT (<剔除条件>) THEN 1 ELSE 0 END) AS correct_kept
FROM <测试表>
WHERE dt = '<分区值>'
```

**验证标准**：

| 指标 | 预期 | 说明 |
|------|------|------|
| should_be_removed | = 0 | 剩余记录都不应被剔除（无漏删） |
| correct_kept | = 测试表记录数 | 全部保留记录都正确 |

---

### 2. 漏删记录明细

```sql
SELECT <主键>
FROM <测试表>
WHERE dt = '<分区值>'
  AND <剔除条件>
LIMIT 20
```

**预期**：0 条（无漏删）。

---

### 3. 剔除基准表反向匹配（方式A专用）

```sql
SELECT 
  SUM(CASE WHEN src.<关联字段> IS NOT NULL THEN 1 ELSE 0 END) AS should_be_removed,
  SUM(CASE WHEN src.<关联字段> IS NULL THEN 1 ELSE 0 END) AS correct_kept
FROM <测试表> t
LEFT JOIN <剔除基准表> src 
  ON t.<主键> = src.<关联字段> 
  AND src.dt = '<分区值>'
WHERE t.dt = '<分区值>'
```

**验证标准**：

| 指标 | 预期 | 说明 |
|------|------|------|
| should_be_removed | = 0 | 测试表中无应剔除的记录 |
| correct_kept | = 测试表记录数 | 全部保留记录都不在基准表中 |

---

## 六、交叉验证

> 综合验证剔除逻辑的正确性。

### 1. 四象限验证

```sql
-- 应剔除且已剔除（正确剔除）
SELECT COUNT(*) AS correctly_removed
FROM <生产表> pro
LEFT JOIN <测试表> t ON pro.<主键> = t.<主键> AND pro.dt = t.dt
WHERE pro.dt = '<分区值>' AND t.<主键> IS NULL AND <剔除条件>
```

```sql
-- 应保留且已保留（正确保留）
SELECT COUNT(*) AS correctly_kept
FROM <生产表> pro
JOIN <测试表> t ON pro.<主键> = t.<主键> AND pro.dt = t.dt
WHERE pro.dt = '<分区值>' AND NOT (<剔除条件>)
```

```sql
-- 应剔除但未剔除（漏删）
SELECT COUNT(*) AS missed_removal
FROM <生产表> pro
JOIN <测试表> t ON pro.<主键> = t.<主键> AND pro.dt = t.dt
WHERE pro.dt = '<分区值>' AND <剔除条件>
```

```sql
-- 应保留但被剔除（误删）
SELECT COUNT(*) AS false_removal
FROM <生产表> pro
LEFT JOIN <测试表> t ON pro.<主键> = t.<主键> AND pro.dt = t.dt
WHERE pro.dt = '<分区值>' AND t.<主键> IS NULL AND NOT (<剔除条件>)
```

---

### 2. 验证标准

| 验证项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| correctly_removed | = removed_cnt | ≠ removed_cnt | 剔除量不一致 |
| correctly_kept | = 测试表记录数 | ≠ 测试表记录数 | 保留量不一致 |
| missed_removal | = 0 | > 0 | 存在漏删 |
| false_removal | = 0 | > 0 | 存在误删 |

---

### 3. 一致性验证（剔除条件覆盖范围）

```sql
SELECT 
  COUNT(*) AS total_prod,
  SUM(CASE WHEN <剔除条件> THEN 1 ELSE 0 END) AS should_remove,
  SUM(CASE WHEN NOT (<剔除条件>) THEN 1 ELSE 0 END) AS should_keep
FROM <生产表>
WHERE dt = '<分区值>'
```

**验证标准**：

| 指标 | 预期 | 说明 |
|------|------|------|
| should_remove | = 生产表记录数 - 测试表记录数 | 剔除量一致 |
| should_keep | = 测试表记录数 | 保留量一致 |

---

## 七、异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| removed_cnt | > 0 | = 0（数据量无变化） | 预期有减少但实际未减少 |
| 来源追溯 match_cnt | = removed_cnt | < removed_cnt | 存在无法追溯的剔除记录 |
| 来源追溯 no_match_cnt | = 0 | > 0 | 存在无法追溯的剔除记录 |
| 误删记录数 | = 0 | > 0 | 存在误删 |
| 漏删记录数（should_be_removed） | = 0 | > 0 | 存在漏删 |
| correctly_removed | = removed_cnt | ≠ removed_cnt | 剔除量不一致 |
| correctly_kept | = 测试表记录数 | ≠ 测试表记录数 | 保留量不一致 |
| missed_removal | = 0 | > 0 | 存在漏删 |
| false_removal | = 0 | > 0 | 存在误删 |

---

## 八、注意事项

- **JOIN 方向**：被剔除数据提取必须用 `RIGHT JOIN`（生产表为主表），不要用 `LEFT JOIN`
- **分区条件**：大表务必加分区条件，避免全表扫描
- **剔除条件**：可能是复合条件（多个 AND/OR），需仔细核对业务逻辑
- **NULL 处理**：剔除条件中涉及 NULL 值时，注意 `IS NULL` 和 `= NULL` 的区别
- **子查询命名**：被剔除数据子查询统一命名为 `removed`，便于后续引用
- **LIMIT**：明细查询默认 LIMIT 20，统计查询不加 LIMIT
- **临时表**：若使用临时表存储被剔除数据，验证完成后及时清理：`DROP TABLE IF EXISTS temp.tmp_xxx`
