# 数据质量校验 SQL 模板

> 本文件为数据质量校验的 SQL 模板库，供 Step 1 调用。
> 模板中 `<测试表>`、`<分区值>`、`<field>`、`<主键>`、`<枚举字段>` 为占位符，执行时替换为实际值。

---

## 一、维度字段校验

### 1. 主键唯一性

校验主键是否存在重复记录。

```sql
SELECT <主键>, count(*) AS cnt
FROM <测试表>
WHERE dt = '<分区值>'
GROUP BY <主键>
HAVING count(*) > 1
```

**预期**：0 条重复。

---

### 2. 空值占比

对单个维度字段统计空值和空字符串占比。

```sql
SELECT
    '<field>' AS field_name,
    count(*) AS total,
    sum(case when <field> is null or <field> = '' then 1 else 0 end) AS null_cnt,
    round(sum(case when <field> is null or <field> = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct
FROM <测试表>
WHERE dt = '<分区值>'
```

**批量执行**：对维度字段列表中的每个字段生成一条上述 SQL，用 `UNION ALL` 合并为一条执行。

**异常判定**：空值占比 > 5% 标记警告。

---

### 3. 维度值分布 TOP 20

查看维度字段的取值分布，识别集中度过高的异常。

```sql
SELECT <field>, count(*) AS cnt,
       round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct
FROM <测试表>
WHERE dt = '<分区值>'
GROUP BY <field>
ORDER BY cnt DESC
LIMIT 20
```

**执行范围**：对关键维度字段（如 sale_emp_code, region_name, customer_type）各执行一次。

**异常判定**：单值占比 > 50% 标记警告。

---

### 4. 枚举值校验

检查枚举字段的取值是否在预期范围内。

```sql
SELECT <枚举字段>, count(*) AS cnt
FROM <测试表>
WHERE dt = '<分区值>'
GROUP BY <枚举字段>
```

**校验方式**：将返回值与预期枚举范围比对（如 first_tab_type 只能是 '1'/'2'，sum_type 只能 be 'D'/'M'/'Y'）。

**异常判定**：出现预期外取值即异常。

---

## 二、指标字段校验

### 1. 空值和零值占比

```sql
SELECT
    '<field>' AS field_name,
    count(*) AS total,
    sum(case when <field> is null then 1 else 0 end) AS null_cnt,
    sum(case when <field> = 0 then 1 else 0 end) AS zero_cnt,
    round((sum(case when <field> is null then 1 else 0 end) + sum(case when <field> = 0 then 1 else 0 end)) * 100.0 / count(*), 2) AS null_zero_pct
FROM <测试表>
WHERE dt = '<分区值>'
```

**异常判定**：空值+零值占比 > 30% 标记警告。

---

### 2. 统计分布

```sql
SELECT
    '<field>' AS field_name,
    min(<field>) AS min_val,
    max(<field>) AS max_val,
    round(avg(<field>), 2) AS avg_val,
    percentile(cast(<field> AS bigint), 0.5) AS median_val
FROM <测试表>
WHERE dt = '<分区值>'
```

**异常判定**：MIN < 0 对数量金额类字段标记异常。

---

### 3. 范围校验

数量、金额类指标必须 > 0。

```sql
SELECT
    '<field>' AS field_name,
    count(*) AS total,
    sum(case when <field> <= 0 then 1 else 0 end) AS invalid_cnt,
    round(sum(case when <field> <= 0 then 1 else 0 end) * 100.0 / count(*), 2) AS invalid_pct
FROM <测试表>
WHERE dt = '<分区值>'
  AND <field> IS NOT NULL
```

**适用字段**：根据 COMMENT 自动识别，含"数量""金额""count""sum"等关键词的字段。

**排除字段**：差值类（如同比增减量）、比率类字段允许负值或零。

**异常判定**：invalid_cnt > 0 即异常。

---

## 三、异常判定标准汇总

### 状态定义

| 状态 | 标记 | 含义 |
|------|------|------|
| ❌ FAIL | ❌ | 严重问题，数据不可信 |
| ⚠️ WARN | ⚠️ | 警告项，需关注 |
| ✅ PASS | ✅ | 通过 |

### 判定规则

| 校验维度 | ❌ FAIL | ⚠️ WARN | ✅ PASS |
|----------|---------|---------|---------|
| **主键唯一性** | 重复记录 > 0 | - | 重复记录 = 0 |
| **主键空值** | 主键字段空值 > 0 | - | 空值 = 0 |
| **维度字段空值** | - | 非主键字段空值 > 5% | 空值占比 ≤ 5% |
| **维度值分布** | - | 单值占比 > 50% | 单值占比 ≤ 50% |
| **枚举值校验** | 出现预期外取值 | - | 全部在预期范围 |
| **指标空值零值** | - | 空值+零值占比 > 30% | 占比 ≤ 30% |
| **指标统计分布** | MIN < 0（数量金额类） | - | MIN ≥ 0 |
| **指标范围校验** | invalid_cnt > 0 | - | invalid_cnt = 0 |

### 结论判定

- 存在任何 ❌ FAIL → **整体结论：不通过 ❌**
- 仅存在 ⚠️ WARN → **整体结论：通过（附警告） ✅⚠️**
- 全部 ✅ PASS → **整体结论：通过 ✅**
