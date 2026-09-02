# 字段比对 SQL 模板

> 本文件为 Step 4（验证原有数据未被破坏）的 SQL 模板库。
> 参考 field-compare skill 的 sql_gen.py 脚本，将 Python 生成逻辑抽象为纯 SQL 模板。
> 模板中 `<生产表>`、`<测试表>`、`<主键>`、`<分区值>`、`<field>` 为占位符，执行时替换为实际值。

---

## 一、主键级比对

### 1. 生产有而测试没有的记录数

```sql
SELECT count(*) AS missing_cnt
FROM <生产表> a
LEFT JOIN <测试表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

**预期**：0 条。

---

### 2. 测试有而生产没有的记录数

```sql
SELECT count(*) AS extra_cnt
FROM <测试表> a
LEFT JOIN <生产表> b ON a.<主键> = b.<主键> AND b.dt = '<分区值>'
WHERE a.dt = '<分区值>' AND b.<主键> IS NULL
```

**预期**：0 条（新增数据来源场景中，此值 > 0 为预期增量）。

---

## 二、字段级比对（共同记录）

### 1. 单字段差异数统计

对共同存在的记录（INNER JOIN），统计单个字段的差异数：

```sql
SELECT
    '<field>' AS field_name,
    sum(case when nvl(cast(a.<field> AS string), 'XXT') <> nvl(cast(b.<field> AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM <生产表> a
INNER JOIN <测试表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
```

---

### 2. 批量字段差异数统计

将所有字段的比对用 `UNION ALL` 合并为一条执行：

```sql
SELECT
    '<field1>' AS field_name,
    sum(case when nvl(cast(a.<field1> AS string), 'XXT') <> nvl(cast(b.<field1> AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM <生产表> a
INNER JOIN <测试表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

SELECT
    '<field2>' AS field_name,
    sum(case when nvl(cast(a.<field2> AS string), 'XXT') <> nvl(cast(b.<field2> AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM <生产表> a
INNER JOIN <测试表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL

-- ... 继续添加其他字段
```

**输出格式**：

| field_name | diff_cnt |
|------------|----------|
| kname | 0 |
| region_code | 3 |
| sale_emp_name | 5 |

**预期**：所有字段 diff_cnt = 0。

---

### 3. 差异明细查询（diff_cnt > 0 时）

对有差异的字段，查询前 10 条差异明细：

```sql
SELECT
    a.<主键>,
    a.<field> AS prod_val,
    b.<field> AS test_val
FROM <生产表> a
INNER JOIN <测试表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
  AND nvl(cast(a.<field> AS string), 'XXT') <> nvl(cast(b.<field> AS string), 'XXT')
LIMIT 10
```

---

## 三、批量生成技巧

### 模板变量替换

将上述模板中的占位符替换为实际值：

| 占位符 | 替换为 |
|--------|--------|
| `<生产表>` | 如 `ytrpt.kcode_crm_ks_dku` |
| `<测试表>` | 如 `temp.kcode_crm_ks_dku` |
| `<主键>` | 如 `kcode` |
| `<分区值>` | 如 `20260614` |
| `<field>` | 如 `kname`, `region_code` 等 |

### 生成批量 SQL 的步骤

1. 从 `dataware_table/` 知识库读取表的字段列表
2. 排除主键字段和分区字段
3. 对每个字段生成一条 UNION ALL 子句
4. 拼接为完整 SQL

### SQL 拼接示例

假设字段列表为 `kname, region_code, sale_emp_code`，生成的 SQL 为：

```sql
SELECT 'kname' AS field_name,
    sum(case when nvl(cast(a.kname AS string), 'XXT') <> nvl(cast(b.kname AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM ytrpt.kcode_crm_ks_dku a
INNER JOIN temp.kcode_crm_ks_dku b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'region_code' AS field_name,
    sum(case when nvl(cast(a.region_code AS string), 'XXT') <> nvl(cast(b.region_code AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM ytrpt.kcode_crm_ks_dku a
INNER JOIN temp.kcode_crm_ks_dku b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'

UNION ALL

SELECT 'sale_emp_code' AS field_name,
    sum(case when nvl(cast(a.sale_emp_code AS string), 'XXT') <> nvl(cast(b.sale_emp_code AS string), 'XXT') then 1 else 0 end) AS diff_cnt
FROM ytrpt.kcode_crm_ks_dku a
INNER JOIN temp.kcode_crm_ks_dku b ON a.kcode = b.kcode
WHERE a.dt = '20260614' AND b.dt = '20260614'
```

---

## 四、异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| missing_cnt（生产有测试没有） | = 0 | > 0 | 原有数据被删除 |
| extra_cnt（测试有生产没有） | = 新增条数 | ≠ 新增条数 | 新增数据数量不一致 |
| 各字段 diff_cnt | = 0 | > 0 | 原有数据被修改 |

---

## 五、注意事项

- 哨兵值 `'XXT'` 应选择业务数据中不会出现的值，避免误判
- NULL 和空字符串统一归一化为 `'XXT'`，避免 NULL = NULL 误判为一致
- 大表务必加分区条件，避免全表扫描
- 字段数较多时，建议每 20-30 个字段一批执行，避免 SQL 过长
