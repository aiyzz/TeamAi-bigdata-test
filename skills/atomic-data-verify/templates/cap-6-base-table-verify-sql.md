# 能力6：基准表溯源验证 SQL 模板

## 使用说明

- `<测试表>`：待验证的测试表全名（database.table）
- `<基准表>`：明细表全名（dwd.xxx）
- `<分区值>`：dt 分区值
- `<主键>`：测试表主键字段
- `<关联键>`：测试表与基准表的关联字段
- `<筛选条件>`：基准表的筛选表达式
- `<测试字段>`：待验证的字段名
- `<基准字段>`：基准表中对应的字段名
- `<维表字段>`：维表中对应的字段名
- `<转换表达式>`：C类字段的计算表达式
- `<常量值>`：D类字段的固定值
- `<源条件>`：E类字段的 CASE WHEN 条件
- `<映射值>`：E类字段的映射结果

---

## 性能优化要求

所有 SQL 必须遵循以下规范：
1. **分区裁剪**：子查询先过滤 dt 分区
2. **主键先过滤**：子查询只取需要的字段，避免 SELECT *
3. **LIMIT 限制**：差异明细查询加 LIMIT 100
4. **大表分批**：记录数 > 1000万时按主键范围分批

---

## SQL 0: 前置检查（容错）

```sql
-- 0.1 基准表分区存在性
-- 结果：cnt = 0 → 终止验证
SELECT COUNT(*) AS cnt
FROM <基准表>
WHERE dt = '<分区值>'
LIMIT 1;

-- 0.2 基准表数据延迟检查
-- 结果：latest_dt < 分区值 → 警告用户
SELECT MAX(dt) AS latest_dt
FROM <基准表>
WHERE dt >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 7 DAY), '%Y%m%d');

-- 0.3 测试表数据量
-- 结果：test_cnt = 0 → 终止验证
SELECT COUNT(*) AS test_cnt
FROM <测试表>
WHERE dt = '<分区值>';

-- 0.4 基准表数据量（筛选后）
-- 结果：base_cnt = 0 → 终止验证
SELECT COUNT(*) AS base_cnt
FROM <基准表>
WHERE dt = '<分区值>'
  AND <筛选条件>;
```

---

## SQL 1: 记录完整性验证（双向）

### 1.1 正向：测试表是否有基准表不存在的记录

```sql
-- 同口径
SELECT
  COUNT(*) AS test_cnt,
  SUM(CASE WHEN b.<主键> IS NOT NULL THEN 1 ELSE 0 END) AS matched_cnt,
  SUM(CASE WHEN b.<主键> IS NULL THEN 1 ELSE 0 END) AS unmatched_cnt
FROM (
  SELECT <关联键>, <主键>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <基准表>
  WHERE dt = '<分区值>'
) b ON t.<关联键> = b.<关联键>;
```

```sql
-- 子集口径（需筛选基准表）
SELECT
  COUNT(*) AS test_cnt,
  SUM(CASE WHEN b.<主键> IS NOT NULL THEN 1 ELSE 0 END) AS matched_cnt,
  SUM(CASE WHEN b.<主键> IS NULL THEN 1 ELSE 0 END) AS unmatched_cnt
FROM (
  SELECT <关联键>, <主键>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>;
```

### 1.2 反向：基准表记录是否都在测试表中（漏数据检测）

```sql
-- 同口径
SELECT
  COUNT(*) AS base_cnt,
  SUM(CASE WHEN t.<主键> IS NOT NULL THEN 1 ELSE 0 END) AS matched_cnt,
  SUM(CASE WHEN t.<主键> IS NULL THEN 1 ELSE 0 END) AS missing_cnt
FROM (
  SELECT <关联键>, <主键>
  FROM <基准表>
  WHERE dt = '<分区值>'
) b
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t ON b.<关联键> = t.<关联键>;
```

```sql
-- 子集口径（需筛选基准表）
SELECT
  COUNT(*) AS base_cnt,
  SUM(CASE WHEN t.<主键> IS NOT NULL THEN 1 ELSE 0 END) AS matched_cnt,
  SUM(CASE WHEN t.<主键> IS NULL THEN 1 ELSE 0 END) AS missing_cnt
FROM (
  SELECT <关联键>, <主键>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t ON b.<关联键> = t.<关联键>;
```

### 1.3 正向未匹配记录明细（测试表多出）

```sql
SELECT t.<主键>, t.<关键字段1>, t.<关键字段2>
FROM (
  SELECT <关联键>, <主键>, <关键字段1>, <关键字段2>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
WHERE b.<主键> IS NULL
LIMIT 100;
```

### 1.4 反向未匹配记录明细（测试表漏了）

```sql
SELECT b.<关联键>, b.<关键字段1>, b.<关键字段2>
FROM (
  SELECT <关联键>, <主键>, <关键字段1>, <关键字段2>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b
LEFT JOIN (
  SELECT <关联键>, <主键>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t ON b.<关联键> = t.<关联键>
WHERE t.<主键> IS NULL
LIMIT 100;
```

---

## SQL 2: A类 — 直接映射字段验证

### 2.1 差异记录查询

```sql
SELECT
  t.<主键>,
  t.<测试字段> AS test_val,
  b.<基准字段> AS base_val
FROM (
  SELECT <关联键>, <主键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <基准字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
WHERE COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
    <> COALESCE(CAST(NULLIF(b.<基准字段>, '') AS CHAR), 'XXT')
LIMIT 100;
```

### 2.2 差异统计

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         = COALESCE(CAST(NULLIF(b.<基准字段>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS match_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         <> COALESCE(CAST(NULLIF(b.<基准字段>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS diff_cnt
FROM (
  SELECT <关联键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <基准字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>;
```

---

## SQL 3: B类 — 维表关联取值验证

### 3.1 操作码维表关联（明细表.op_code → 维表.oper_type）

```sql
SELECT
  t.<主键>,
  t.<测试字段> AS test_val,
  dim_op.oper_type AS dim_val
FROM (
  SELECT <关联键>, <主键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, op_code
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
JOIN dim.mdm_opcode_info_a dim_op
  ON b.op_code = dim_op.op_code
WHERE COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
    <> COALESCE(CAST(NULLIF(dim_op.oper_type, '') AS CHAR), 'XXT')
LIMIT 100;
```

### 3.2 组织维表关联（明细表.org_code → 维表.org_name / branch_name / region_name / transfer_name）

```sql
SELECT
  t.<主键>,
  t.<测试字段> AS test_val,
  dim_org.<维表字段> AS dim_val
FROM (
  SELECT <关联键>, <主键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, org_code
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
JOIN (
  SELECT org_code, <维表字段>
  FROM dim.t03_user_org_mdm_org
  WHERE dt = '<分区值>'
) dim_org ON b.org_code = dim_org.org_code
WHERE COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
    <> COALESCE(CAST(NULLIF(dim_org.<维表字段>, '') AS CHAR), 'XXT')
LIMIT 100;
```

### 3.3 操作码维表 — 差异统计

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         = COALESCE(CAST(NULLIF(dim_op.oper_type, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS match_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         <> COALESCE(CAST(NULLIF(dim_op.oper_type, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS diff_cnt
FROM (
  SELECT <关联键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, op_code
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
JOIN dim.mdm_opcode_info_a dim_op
  ON b.op_code = dim_op.op_code;
```

### 3.4 组织维表 — 差异统计

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         = COALESCE(CAST(NULLIF(dim_org.<维表字段>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS match_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         <> COALESCE(CAST(NULLIF(dim_org.<维表字段>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS diff_cnt
FROM (
  SELECT <关联键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, org_code
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
JOIN (
  SELECT org_code, <维表字段>
  FROM dim.t03_user_org_mdm_org
  WHERE dt = '<分区值>'
) dim_org ON b.org_code = dim_org.org_code;
```

---

## SQL 4: C类 — 计算转换字段验证

### 4.1 差异记录查询

```sql
SELECT
  t.<主键>,
  t.<测试字段> AS test_val,
  <转换表达式> AS expected_val
FROM (
  SELECT <关联键>, <主键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <源字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
WHERE COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
    <> COALESCE(CAST(NULLIF(<转换表达式>, '') AS CHAR), 'XXT')
LIMIT 100;
```

### 4.2 差异统计

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         = COALESCE(CAST(NULLIF(<转换表达式>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS match_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         <> COALESCE(CAST(NULLIF(<转换表达式>, '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS diff_cnt
FROM (
  SELECT <关联键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <源字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>;
```

---

## SQL 5: D类 — 常量字段验证

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(CASE WHEN <测试字段> = '<常量值>' THEN 1 ELSE 0 END) AS match_cnt,
  SUM(CASE WHEN <测试字段> <> '<常量值>' OR <测试字段> IS NULL THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表>
WHERE dt = '<分区值>';
```

---

## SQL 6: E类 — 字典映射字段验证

### 6.1 差异记录查询

```sql
SELECT
  t.<主键>,
  t.<测试字段> AS test_val,
  CASE
    WHEN <源条件1> THEN '<映射值1>'
    WHEN <源条件2> THEN '<映射值2>'
    ELSE '<默认值>'
  END AS expected_val
FROM (
  SELECT <关联键>, <主键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <源字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>
WHERE COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
    <> COALESCE(CAST(NULLIF(
      CASE
        WHEN <源条件1> THEN '<映射值1>'
        WHEN <源条件2> THEN '<映射值2>'
        ELSE '<默认值>'
      END
    , '') AS CHAR), 'XXT')
LIMIT 100;
```

### 6.2 差异统计

```sql
SELECT
  COUNT(*) AS total_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         = COALESCE(CAST(NULLIF(
           CASE
             WHEN <源条件1> THEN '<映射值1>'
             WHEN <源条件2> THEN '<映射值2>'
             ELSE '<默认值>'
           END
         , '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS match_cnt,
  SUM(
    CASE
      WHEN COALESCE(CAST(NULLIF(t.<测试字段>, '') AS CHAR), 'XXT')
         <> COALESCE(CAST(NULLIF(
           CASE
             WHEN <源条件1> THEN '<映射值1>'
             WHEN <源条件2> THEN '<映射值2>'
             ELSE '<默认值>'
           END
         , '') AS CHAR), 'XXT')
      THEN 1 ELSE 0
    END
  ) AS diff_cnt
FROM (
  SELECT <关联键>, <测试字段>
  FROM <测试表>
  WHERE dt = '<分区值>'
) t
JOIN (
  SELECT <关联键>, <源字段>
  FROM <基准表>
  WHERE dt = '<分区值>'
    AND <筛选条件>
) b ON t.<关联键> = b.<关联键>;
```

---

## SQL 7: 全字段差异汇总

将所有可溯源字段的验证结果汇总为一张表：

```sql
-- A类字段
SELECT 'A类-直接映射' AS verify_type, '<字段名>' AS field_name, <统计>
FROM ...
UNION ALL
-- B类字段（维表关联）
SELECT 'B类-维表关联' AS verify_type, '<字段名>' AS field_name, <统计>
FROM ...
UNION ALL
-- C类字段（计算转换）
SELECT 'C类-计算转换' AS verify_type, '<字段名>' AS field_name, <统计>
FROM ...
UNION ALL
-- D类字段（常量）
SELECT 'D类-常量' AS verify_type, '<字段名>' AS field_name, <统计>
FROM ...
UNION ALL
-- E类字段（字典映射）
SELECT 'E类-字典映射' AS verify_type, '<字段名>' AS field_name, <统计>
FROM ...;
```
