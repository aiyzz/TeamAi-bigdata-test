# 数据量变化与来源追溯 SQL 模板

> 本文件为 Step 2（数据量变化方向）和 Step 3（定位新增数据来源）的 SQL 模板库。
> 模板中 `<测试表>`、`<生产表>`、`<分区值>`、`<主键>`、`<新增来源表>`、`<新增来源过滤条件>`、`<关联键>`、`<来源主键>` 为占位符，执行时替换为实际值。

---

## 零、空表前置检查

在进入数据量对比前，先检查两张表是否有数据：

```sql
SELECT '测试表' AS tbl, count(*) AS cnt FROM <测试表> WHERE dt = '<分区值>'
UNION ALL
SELECT '生产表' AS tbl, count(*) AS cnt FROM <生产表> WHERE dt = '<分区值>'
```

**边界处理**：

| 测试表 | 生产表 | 处理 |
|--------|--------|------|
| 0 | 0 | 终止，两张表均无数据 |
| 0 | > 0 | 终止，测试表为空，数据丢失 |
| > 0 | 0 | 跳过 Step 2-4，仅做数据质量校验 |
| > 0 | > 0 | 继续执行 |

---

## 一、Step 2：确认数据量变化方向

### 1. 新旧表记录数对比

```sql
SELECT '测试' AS env, count(*) AS cnt
FROM <测试表> WHERE dt = '<分区值>'
UNION ALL
SELECT '生产' AS env, count(*) AS cnt
FROM <生产表> WHERE dt = '<分区值>'
```

**输出**：测试表 N 条，生产表 M 条。

---

### 2. 新增条数（测试有、生产没有）

```sql
SELECT count(*) AS added_cnt
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

---

### 3. 减少条数（生产有、测试没有）

```sql
SELECT count(*) AS removed_cnt
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
```

---

### 4. 结果判断

| added_cnt | removed_cnt | 结论 |
|-----------|-------------|------|
| > 0 | = 0 | 纯增加，符合预期 |
| > 0 | > 0 | 有增有减，需排查减少原因 |
| = 0 | = 0 | 数据量一致，无变化 |
| = 0 | > 0 | 纯减少，异常 |

---

## 二、Step 3：定位新增数据来源

### 1. 提取新增明细到临时表

```sql
CREATE TABLE temp.tmp_new_rows AS
SELECT a.*
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

---

### 2. 提取来源表数据到临时表

```sql
CREATE TABLE temp.tmp_source_rows AS
SELECT *
FROM <新增来源表>
WHERE dt = '<分区值>'
  AND <新增来源过滤条件>
```

---

### 3. 关联验证：新增数据是否全部来自来源表

```sql
SELECT count(*) AS matched_cnt
FROM temp.tmp_new_rows a
INNER JOIN temp.tmp_source_rows b ON a.<关联键>
```

**验证标准**：`matched_cnt = added_cnt`，即新增数据 100% 来源于新来源表。

---

### 4. 排查未匹配的新增记录（matched_cnt < added_cnt 时）

```sql
SELECT a.<主键>
FROM temp.tmp_new_rows a
LEFT JOIN temp.tmp_source_rows b ON a.<关联键>
WHERE b.<来源主键> IS NULL
LIMIT 20
```

---

### 5. 临时表清理

```sql
DROP TABLE IF EXISTS temp.tmp_new_rows;
DROP TABLE IF EXISTS temp.tmp_source_rows;
```

---

## 三、异常判定标准汇总

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| 测试表数据 | > 0 | = 0 | 测试表为空，数据丢失 |
| 生产表数据 | > 0 | = 0 | 生产表为空，无法对比 |
| 新增条数 | > 0 | = 0 | 无新增数据，跳过来源追溯 |
| 减少条数 | = 0 | > 0 | 原有数据被误删 |
| 来源命中率 | 100% | < 100% | 新增数据来源不可追溯 |

---

## 四、Step 3 扩展：新增数据来源筛选逻辑验证

> 本章节用于验证新增数据是否符合需求文档的筛选逻辑，确保 ETL 过滤条件正确。

### C.3.2 来源追溯匹配验证

**目的**：验证测试表新增数据是否全部来自新增数据源

```sql
SELECT 
  CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END AS match_status,
  COUNT(*) AS cnt
FROM <测试表> t
LEFT JOIN <上游表> o 
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p 
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END
```

**预期结果**：匹配数 = 新增数，未匹配数 = 0

---

### C.3.3 筛选条件符合性验证

**目的**：验证新增数据是否全部符合需求文档的筛选逻辑

```sql
SELECT 
  CASE 
    WHEN <筛选条件> THEN '符合条件'
    ELSE '不符合条件'
  END AS filter_status,
  COUNT(*) AS cnt
FROM <测试表> t
INNER JOIN <上游表> o 
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p 
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE 
    WHEN <筛选条件> THEN '符合条件'
    ELSE '不符合条件'
  END
```

**预期结果**：符合条件数 = 新增数，不符合条件数 = 0

**筛选条件示例**：
```sql
-- 示例1：审核通过且未删除
WHEN o.status = '1' AND o.is_deleted = '0' THEN '符合条件'

-- 示例2：特定客户类型
WHEN o.customer_type = '大客户' AND o.market_type = '直客' THEN '符合条件'
```

---

### C.3.4 新增数据来源特征明细

**目的**：分析新增数据在上游表中的来源特征分布

```sql
SELECT 
  <筛选字段1>,
  <筛选字段2>,
  COUNT(*) AS cnt
FROM <测试表> t
INNER JOIN <上游表> o 
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p 
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY <筛选字段1>, <筛选字段2>
ORDER BY cnt DESC
```

**用途**：
- 了解新增数据的来源构成
- 验证筛选逻辑是否覆盖了预期的数据范围
- 发现可能的异常数据分布

---

### C.3.5 不符合条件数据排查

**目的**：排查新增数据中是否存在不符合需求筛选条件的记录

```sql
SELECT 
  t.<主键字段>,
  o.<筛选字段1>,
  o.<筛选字段2>
FROM <测试表> t
INNER JOIN <上游表> o 
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p 
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
  AND NOT (<筛选条件>)
LIMIT 20
```

**预期结果**：0 条记录（无不符合条件的数据）

**异常处理**：
- 若返回记录 > 0，需排查 ETL 筛选逻辑是否正确
- 检查上游表数据质量，是否存在异常状态的记录
- 与业务方确认筛选条件是否需要调整

---

### 四、筛选逻辑验证异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| 来源匹配数 | = 新增数 | < 新增数 | 新增数据来源不完整 |
| 符合条件数 | = 新增数 | < 新增数 | 存在不符合筛选条件的数据 |
| 不符合条件数 | 0 | > 0 | ETL 筛选逻辑有误 |
