# 差异行统计 SQL 模板

> 本文件为主流程的差异行统计 SQL 模板，由 skill 主流程直接执行。
> 用于判断数据量变化方向，决定激活能力2（增加记录）还是能力3（减少记录）。
> 模板中 `<测试表>`、`<生产表>`、`<主键>`、`<分区值>` 为占位符，执行时替换为实际值。

---

## 一、新旧表记录数对比

```sql
SELECT '测试' AS env, count(*) AS cnt
FROM <测试表> WHERE dt = '<分区值>'
UNION ALL
SELECT '生产' AS env, count(*) AS cnt
FROM <生产表> WHERE dt = '<分区值>'
```

**输出**：测试表 N 条，生产表 M 条。

---

## 二、新增条数（测试有、生产没有）

```sql
SELECT count(*) AS added_cnt
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

---

## 三、减少条数（生产有、测试没有）

```sql
SELECT count(*) AS removed_cnt
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
```

---

## 四、新增记录明细

```sql
SELECT a.<主键>
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
LIMIT 10
```

---

## 五、减少记录明细

```sql
SELECT b.<主键>
FROM <测试表> a
RIGHT JOIN <生产表> b ON a.<主键> = b.<主键> AND a.dt = '<分区值>'
WHERE b.dt = '<分区值>' AND a.<主键> IS NULL
LIMIT 10
```

---

## 六、结果判断

| added_cnt | removed_cnt | 结论 | 激活能力 |
|-----------|-------------|------|----------|
| > 0 | = 0 | 纯增加 | 能力2 |
| > 0 | > 0 | 有增有减 | 能力2 + 能力3 |
| = 0 | = 0 | 数据量一致 | 能力1 |
| = 0 | > 0 | 纯减少 | 能力3 |

---

## 七、占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<测试表>` | 测试表完整名称 | `temp.kcode_crm_ks_dku` |
| `<生产表>` | 生产表完整名称 | `ytrpt.kcode_crm_ks_dku` |
| `<主键>` | JOIN 键字段名 | `kcode` |
| `<分区值>` | 分区日期 | `20260618` |

---

## 八、注意事项

- 大表务必加分区条件，避免全表扫描
- LEFT JOIN 以测试表为主表，RIGHT JOIN 以生产表为主表
- LIMIT 默认 10，仅展示差异行的主键值
- 若需统计总差异数，可额外执行 `SELECT COUNT(*)` 版本
