# 数据量变化与来源追溯 SQL 模板

> 本文件为 Step 2（数据量变化方向）和 Step 3（定位新增数据来源）的 SQL 模板库。
> 模板中 `<测试表>`、`<生产表>`、`<分区值>`、`<主键>`、`<新增来源表>`、`<新增来源过滤条件>`、`<关联键>`、`<来源主键>` 为占位符，执行时替换为实际值。

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
WHERE  b.<主键> IS NULL
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

| 检查项 | 预期 | 异常处理 |
|--------|------|----------|
| 新增条数 | > 0 | = 0 说明无新增数据，跳过后续来源追溯 |
| 减少条数 | = 0 | > 0 需排查原有数据是否被误删 |
| 来源命中率 | 100% | < 100% 需排查未匹配记录的来源 |
