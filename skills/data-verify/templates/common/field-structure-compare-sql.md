# 字段结构比对 SQL 模板

> 本文件为主流程的字段结构比对 SQL 模板，由 skill 主流程直接执行。
> 用于比对两表的字段数量和字段列表差异，决定是否激活能力4（字段增减验证）。
> 模板中 `<库名>`、`<生产表名>`、`<测试表名>` 为占位符，执行时替换为实际值。

---

## 一、字段数量对比

```sql
SELECT table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = '<库名>'
  AND table_name IN ('<生产表名>', '<测试表名>')
GROUP BY table_name
```

**输出格式**：

| table_name | column_count |
|------------|--------------|
| kcode_crm_ks_dku | 25 |
| kcode_crm_ks_dku_test | 27 |

---

## 二、获取两表字段列表

### 1. 生产表字段列表

```sql
SELECT column_name, data_type, column_comment
FROM information_schema.columns
WHERE table_schema = '<库名>' AND table_name = '<生产表名>'
ORDER BY ordinal_position
```

### 2. 测试表字段列表

```sql
SELECT column_name, data_type, column_comment
FROM information_schema.columns
WHERE table_schema = '<库名>' AND table_name = '<测试表名>'
ORDER BY ordinal_position
```

---

## 三、新增字段（测试表有、生产表没有）

```sql
SELECT t.column_name, t.data_type, t.column_comment
FROM information_schema.columns t
LEFT JOIN information_schema.columns p
  ON t.column_name = p.column_name
  AND p.table_schema = '<库名>' AND p.table_name = '<生产表名>'
WHERE t.table_schema = '<库名>' AND t.table_name = '<测试表名>'
  AND p.column_name IS NULL
```

**输出格式**：

| column_name | data_type | column_comment |
|-------------|-----------|----------------|
| new_field1 | varchar(255) | 新增字段1 |
| new_field2 | int | 新增字段2 |

---

## 四、删除字段（生产表有、测试表没有）

```sql
SELECT p.column_name, p.data_type, p.column_comment
FROM information_schema.columns p
LEFT JOIN information_schema.columns t
  ON p.column_name = t.column_name
  AND t.table_schema = '<库名>' AND t.table_name = '<测试表名>'
WHERE p.table_schema = '<库名>' AND p.table_name = '<生产表名>'
  AND t.column_name IS NULL
```

**输出格式**：

| column_name | data_type | column_comment |
|-------------|-----------|----------------|
| old_field1 | varchar(255) | 旧字段1 |

---

## 五、共同字段（两表都有）

```sql
SELECT p.column_name, p.data_type, p.column_comment
FROM information_schema.columns p
INNER JOIN information_schema.columns t
  ON p.column_name = t.column_name
  AND t.table_schema = '<库名>' AND t.table_name = '<测试表名>'
WHERE p.table_schema = '<库名>' AND p.table_name = '<生产表名>'
ORDER BY p.ordinal_position
```

---

## 六、结果判断

| 新增字段数 | 删除字段数 | 结论 | 激活能力 |
|-----------|-----------|------|----------|
| > 0 | = 0 | 仅新增字段 | 能力4（D1/D3） |
| = 0 | > 0 | 仅删除字段 | 能力4（D2） |
| > 0 | > 0 | 有增有减 | 能力4（D1/D2/D3） |
| = 0 | = 0 | 结构一致 | 不激活能力4 |

---

## 七、占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<库名>` | 数据库名称 | `ytrpt` |
| `<生产表名>` | 生产表名称（不含库名） | `kcode_crm_ks_dku` |
| `<测试表名>` | 测试表名称（不含库名） | `kcode_crm_ks_dku` |

---

## 八、注意事项

- 字段名比对区分大小写
- 仅比对字段名，不比对字段类型和注释的差异
- 若需要比对字段类型差异，可扩展 SQL 添加 data_type 比较
- 主键和分区字段也会出现在比对结果中，后续能力执行时需排除
