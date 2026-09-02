# 能力4：验证字段增减 SQL 模板

> 本文件为能力4（验证字段增减）的 SQL 模板。
> 用于验证表结构变更（新增字段、删除字段）的正确性：原有字段未被破坏、新增字段数据正确。
> 模板中 `<测试表>`、`<生产表>`、`<主键>`、`<分区值>`、`<新增字段>`、`<新增来源表>`、`<关联键>`、`<上游源表>`、`<转换表达式>`、`<目标字段>` 为占位符，执行时替换为实际值。

---

## 一、数据量一致性验证

> 结构变更不应改变数据量。

### 1. 记录数对比

```sql
SELECT '生产表' AS tbl, COUNT(*) AS cnt FROM <生产表> WHERE dt = '<分区值>'
UNION ALL
SELECT '测试表' AS tbl, COUNT(*) AS cnt FROM <测试表> WHERE dt = '<分区值>'
```

### 2. 差异记录数

```sql
SELECT COUNT(*) AS test_only_cnt
FROM <测试表> t
LEFT JOIN <生产表> pro ON t.<主键> = pro.<主键> AND t.dt = pro.dt
WHERE t.dt = '<分区值>' AND pro.<主键> IS NULL

UNION ALL

SELECT COUNT(*) AS prod_only_cnt
FROM <测试表> t
RIGHT JOIN <生产表> pro ON t.<主键> = pro.<主键> AND t.dt = pro.dt
WHERE pro.dt = '<分区值>' AND t.<主键> IS NULL
```

**预期**：test_only_cnt = 0，prod_only_cnt = 0

---

## 二、原有字段保护验证

> 验证共同字段（两表都有的字段）的值未被修改。

### 1. 单字段差异数统计

```sql
SELECT
  '<field>' AS field_name,
  SUM(CASE WHEN t.<field> != pro.<field>
       OR (t.<field> IS NULL AND pro.<field> IS NOT NULL)
       OR (t.<field> IS NOT NULL AND pro.<field> IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> t
JOIN <生产表> pro ON t.<主键> = pro.<主键> AND t.dt = pro.dt
WHERE t.dt = '<分区值>'
```

### 2. 批量字段差异数统计（UNION ALL）

```sql
SELECT
  '<field1>' AS field_name,
  SUM(CASE WHEN t.<field1> != pro.<field1>
       OR (t.<field1> IS NULL AND pro.<field1> IS NOT NULL)
       OR (t.<field1> IS NOT NULL AND pro.<field1> IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> t
JOIN <生产表> pro ON t.<主键> = pro.<主键> AND t.dt = pro.dt
WHERE t.dt = '<分区值>'

UNION ALL

SELECT
  '<field2>' AS field_name,
  SUM(CASE WHEN t.<field2> != pro.<field2>
       OR (t.<field2> IS NULL AND pro.<field2> IS NOT NULL)
       OR (t.<field2> IS NOT NULL AND pro.<field2> IS NULL)
       THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> t
JOIN <生产表> pro ON t.<主键> = pro.<主键> AND t.dt = pro.dt
WHERE t.dt = '<分区值>'

-- ... 对每个共同字段重复上述模式
```

**预期**：所有共同字段 diff_cnt = 0

---

## 三、新增字段验证 — 直接映射（D1）

> 适用场景：新增字段直接取自来源表，无转换逻辑。

```sql
SELECT
  '<新增字段>' AS field_name,
  SUM(CASE WHEN NVL(CAST(t.<新增字段> AS STRING), '')
        <> NVL(CAST(src.<来源字段> AS STRING), '')
       THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> t
LEFT JOIN <新增来源表> src ON t.<关联键> = src.<关联键> AND src.dt = '<分区值>'
WHERE t.dt = '<分区值>'
```

**预期**：diff_cnt = 0

---

## 四、新增字段验证 — ETL 转换（D3）

> 适用场景：新增字段经 ETL 转换逻辑处理。

### 1. 基础模板

```sql
SELECT
    a.<主键字段>,
    a.<源字段>,
    b.<目标字段>
FROM (
    SELECT *
    FROM <上游源表>
    WHERE dt = '<分区值>'
      AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST(<转换表达式> AS STRING), '') <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

**关键说明**：

| 要素 | 写法 | 作用 |
|------|------|------|
| 上游过滤条件 | 写在 a 的子查询 WHERE 中 | 由需求文档+知识库转换，只取需要验证的数据 |
| 转换表达式 | `NVL(CAST(<转换表达式> AS STRING), '')` | 直接在 WHERE 中复现 ETL 逻辑 |
| 分区条件 | a 的分区在子查询中过滤，b 的分区在外层 WHERE 过滤 | 各自独立声明 |
| NULL 安全 | `NVL(CAST(... AS STRING), '')` | 统一将 NULL 转为空字符串比对 |

---

### 2. 转换类型模板

#### 2.1 条件映射（CASE WHEN）

```sql
SELECT a.<主键>, a.<源字段>, b.<目标字段>
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST(CASE WHEN a.<条件字段> = '<值>' THEN '<结果1>' ELSE '<结果2>' END AS STRING), '')
        <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

#### 2.2 空值填充（COALESCE / IF）

```sql
SELECT a.<主键>, a.<源字段>, b.<目标字段>
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST(COALESCE(a.<源字段>, '<默认值>') AS STRING), '')
        <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

#### 2.3 字段拼接（CONCAT）

```sql
SELECT a.<主键>, a.<字段1>, a.<字段2>, b.<目标字段>
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST(CONCAT(COALESCE(a.<字段1>, ''), '-', COALESCE(a.<字段2>, '')) AS STRING), '')
        <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

#### 2.4 关联取值（维表映射）

```sql
SELECT a.<主键>, a.<关联字段>, b.<目标字段>
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST((
        SELECT <取值字段>
        FROM <维表>
        WHERE <维表关联键> = a.<关联字段>
        LIMIT 1
    ) AS STRING), '')
        <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

#### 2.5 固定值（硬编码）

```sql
SELECT a.<主键>, b.<目标字段>
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST('<固定值>' AS STRING), '')
        <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

---

### 3. 批量验证模板

将多个转换字段用 UNION ALL 合并为一条执行：

```sql
SELECT '<字段1>' AS field_name,
    sum(case when NVL(CAST(<转换表达式1> AS STRING), '') <> NVL(CAST(b.<目标字段1> AS STRING), '') then 1 else 0 end) AS diff_cnt
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
JOIN <结果表> b ON a.<关联键> = b.<关联键>
WHERE b.dt = '<分区值>'

UNION ALL

SELECT '<字段2>' AS field_name,
    sum(case when NVL(CAST(<转换表达式2> AS STRING), '') <> NVL(CAST(b.<目标字段2> AS STRING), '') then 1 else 0 end) AS diff_cnt
FROM (
    SELECT * FROM <上游源表>
    WHERE dt = '<分区值>' AND <上游过滤条件>
) a
JOIN <结果表> b ON a.<关联键> = b.<关联键>
WHERE b.dt = '<分区值>'

UNION ALL

-- ... 继续添加其他字段
```

---

## 五、新增字段质量检查

```sql
SELECT
  '<新增字段>' AS field_name,
  COUNT(*) AS total,
  SUM(CASE WHEN <新增字段> IS NULL OR <新增字段> = '' THEN 1 ELSE 0 END) AS null_cnt,
  ROUND(SUM(CASE WHEN <新增字段> IS NULL OR <新增字段> = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_pct
FROM <测试表>
WHERE dt = '<分区值>'
```

**预期**：新增字段空值占比 ≤ 50%（> 50% 可能是映射失败）

---

## 六、删除字段确认

```sql
SELECT COUNT(*) AS cnt
FROM information_schema.columns
WHERE table_schema = '<库名>'
  AND table_name = '<测试表>'
  AND column_name = '<删除字段>'
```

**预期**：cnt = 0（字段已删除）

---

## 七、ETL 转换规则说明

### 过滤条件转换规则

需求文档是自然语言描述，需要结合上游表知识库转换为 SQL 筛选逻辑：

| 需求文档描述 | 上游表字段（来自知识库） | 转换后的 SQL 条件 |
|-------------|------------------------|------------------|
| "ZK开头的结算编码" | `settle_code` (结算编码) | `settle_code LIKE 'ZK%'` |
| "有效的直客K码" | `status` (状态), `up_time` (上线时间), `expire_time` (到期时间) | `status = '1' AND to_date(up_time) <= '${yyyy_mm_dd}' AND to_date(expire_time) >= '${yyyy_mm_dd}'` |
| "品牌客户" | `customer_classify` (客户分类) | `customer_classify = 'BRAND'` |

### 转换步骤

1. **阅读需求文档**：提取业务规则的自然语言描述
2. **查阅上游表知识库**：在 `knowledge/*.md` 中查找对应字段名和注释
3. **匹配语义**：将自然语言关键词与字段注释匹配
4. **生成 SQL 条件**：根据业务规则生成 WHERE 子句
5. **人工确认**：展示转换结果给用户确认

---

## 八、必须遵守的规则

1. **上游过滤条件必须声明**
   - a 表使用子查询，包含 `dt = '<分区值>'` 和 `<上游过滤条件>`

2. **WHERE 条件分层**
   ```sql
   -- a 的分区和过滤在子查询中
   FROM (SELECT * FROM <上游源表> WHERE dt = '<分区值>' AND <上游过滤条件>) a
   -- b 的分区在外层 WHERE
   WHERE b.dt = '<分区值>'
     AND [NVL(CAST(转换表达式)) <> NVL(CAST(目标字段))]
   ```

3. **转换表达式写法**
   - 用 `NVL(CAST(... AS STRING), '')` 包裹整个表达式

4. **分区字段 dt 强制声明**
   - 上游表在子查询中声明 `dt = '<分区值>'`
   - 结果表在外层 WHERE 声明 `b.dt = '<分区值>'`
   - 禁止省略为 `a.dt = b.dt`

---

## 九、典型错误写法（避免）

```sql
-- 错误1：上游表缺少过滤条件
FROM <上游源表> a  -- 未过滤 status、settle_code 等条件

-- 错误2：转换逻辑写在 JOIN 条件
LEFT JOIN b ON ... AND CAST(a.status AS STRING) = CAST(b.status_flag AS STRING)

-- 错误3：省略 dt 分区条件
WHERE NVL(CAST(...)) <> NVL(CAST(...))  -- 未过滤分区

-- 错误4：重命名字段
SELECT a.status AS source_value, b.status_flag AS target_value ...
```

---

## 十、异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| 数据量一致 | test_only = 0, prod_only = 0 | ≠ 0 | 结构变更不应改变数据量 |
| 原有字段 diff_cnt | 全部 = 0 | > 0 | 原有字段值被修改 |
| 新增字段 diff_cnt（直接映射） | = 0 | > 0 | 映射逻辑有误 |
| 新增字段 diff_cnt（ETL 转换） | = 0 | > 0 | ETL 转换逻辑有误 |
| 新增字段空值占比 | ≤ 50% | > 50% | 可能是映射失败 |
| 删除字段已确认 | cnt = 0 | > 0 | 字段未删除 |

---

## 十一、注意事项

- 大表务必加分区条件，避免全表扫描
- 字段数较多时（> 30），建议分批执行，每批 20-30 个字段
- 原有字段保护验证需排除新增字段和删除字段
- ETL 转换逻辑需从需求文档和上游表知识库中提取
- 临时表使用后及时清理：`DROP TABLE IF EXISTS temp.tmp_xxx`
