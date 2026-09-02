# 能力1：验证不变更记录 SQL 模板

> 本文件为能力1（验证不变更记录）的 SQL 模板。
> 用于验证测试表中与生产表共同存在的记录，其字段值未被修改。
> 模板中 `<测试表>`、`<生产表>`、`<主键>`、`<分区值>`、`<field>` 为占位符，执行时替换为实际值。

---

## 一、统计共同记录数

```sql
SELECT count(*) AS common_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
```

**输出**：共同记录数 N。

---

## 二、单字段差异数统计

对共同存在的记录（INNER JOIN），统计单个字段的差异数：

```sql
SELECT
    '<field>' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.<field>,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.<field>,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
```

---

## 三、批量字段差异数统计（UNION ALL）

将所有待比对字段用 `UNION ALL` 合并为一条 SQL 执行：

```sql
SELECT
    '<field1>' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.<field1>,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.<field1>,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

SELECT
    '<field2>' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.<field2>,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.<field2>,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

-- ... 对每个待比对字段重复上述模式
```

**输出格式**：

| field_name | diff_cnt |
|------------|----------|
| kname | 0 |
| region_code | 3 |
| sale_emp_name | 5 |

**预期**：所有字段 diff_cnt = 0。

---

## 四、字段列表生成规则

从知识库 DDL 提取字段列表后，按以下规则生成待比对字段：

1. **提取所有字段名**：从 CREATE TABLE 语句中解析出所有列名
2. **排除以下字段**：
   - 主键字段（PRIMARY KEY 或 UNIQUE KEY 中定义的字段）
   - 分区字段（如 `dt`）
3. **对每个剩余字段**，生成一条 UNION ALL 子句

**示例**：假设表有字段 `id, name, status, created_time, dt`，主键为 `id`，分区字段为 `dt`。
待比对字段为 `name, status, created_time`，生成的 SQL 为：

```sql
SELECT 'name' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.name,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.name,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.id = b.id
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

SELECT 'status' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.status,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.status,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.id = b.id
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

SELECT 'created_time' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.created_time,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.created_time,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.id = b.id
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
```

---

## 五、差异明细查询

当字段比对发现 diff_cnt > 0 时，查询具体的差异行数据。

### 1. 单字段差异明细

```sql
SELECT
    a.<主键>,
    a.<差异字段> AS a_<差异字段>,
    b.<差异字段> AS b_<差异字段>
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE NVL(CAST(NULLIF(a.<差异字段>,'') AS STRING), 'XXT')
   <> NVL(CAST(NULLIF(b.<差异字段>,'') AS STRING), 'XXT')
AND a.dt = '<分区值>' AND b.dt = '<分区值>'
LIMIT 10
```

**输出格式**：

| 主键 | a_字段名 | b_字段名 |
|------|----------|----------|
| 1 | 张三 | 张三三 |
| 2 | 李四 | NULL |

---

### 2. 多字段差异明细（复合主键）

当 JOIN 键为复合主键时，调整 WHERE 条件：

```sql
SELECT
    a.<主键1>,
    a.<主键2>,
    a.<差异字段> AS a_<差异字段>,
    b.<差异字段> AS b_<差异字段>
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键1> = b.<主键1> AND a.<主键2> = b.<主键2>
WHERE NVL(CAST(NULLIF(a.<差异字段>,'') AS STRING), 'XXT')
   <> NVL(CAST(NULLIF(b.<差异字段>,'') AS STRING), 'XXT')
AND a.dt = '<分区值>' AND b.dt = '<分区值>'
LIMIT 10
```

---

## 六、归一化规则

| 场景 | 处理方式 | 说明 |
|------|----------|------|
| 字段值为 NULL | `NVL(..., 'XXT')` | NULL 归一化为哨兵值 |
| varchar/char/string 字段为空字符串 | `NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')` | 空串先转 NULL，再归一化 |
| 数值字段（int/bigint/decimal/float） | `NVL(CAST(field AS STRING), 'XXT')` | 不用 NULLIF，数值字段不存空串 |
| 字段类型不一致 | `CAST(... AS STRING)` | 统一转为字符串比较 |

哨兵值 `'XXT'` 应确保不出现在业务数据中，避免误判。

---

## 七、异常判定标准

| 检查项 | ❌ FAIL | ⚠️ WARN | ✅ PASS |
|--------|---------|---------|---------|
| 共同记录数 | = 0 | - | > 0 |
| 所有字段 diff_cnt | 所有字段相同且 > 0 | 部分字段 > 0 | 全部 = 0 |
| 差异行占比 | > 50% | > 10% | ≤ 10% |

### 差异行占比计算

```
差异行占比 = MAX(各字段 diff_cnt) / 共同记录数
```

### 结论判定

- 所有字段 diff_cnt = 0 → ✅ PASS（两表数据完全一致）
- 部分字段 diff_cnt > 0 → ⚠️ WARN，执行差异明细查询
- 所有字段 diff_cnt 相同且 > 0 → ❌ FAIL，可能是分区条件错误或 JOIN 键不当
- 差异行占比 > 50% → ❌ FAIL，两表数据差异过大

---

## 八、注意事项

- 大表务必加分区条件，避免全表扫描
- 字段数较多时（> 30），建议分批执行，每批 20-30 个字段
- INNER JOIN 仅比对两表共同存在的记录，不包含差异行
- 哨兵值 `'XXT'` 应选择业务数据中不会出现的值，避免误判
- NULL 和空字符串统一归一化为 `'XXT'`，避免 NULL = NULL 误判为一致
- **数值类型字段（int/bigint/decimal/float）不要套用 `NULLIF(field,'')`**：数值字段不存储空字符串，NULLIF 无意义且 Hive 会把 `''` 隐式转为数值（得 NULL）；应直接用 `NVL(CAST(field AS STRING),'XXT')`，仅 varchar/char/string 字段才用 `NULLIF(field,'')`。生成比对 SQL 前先从 schema 读取字段类型按此选择表达式
