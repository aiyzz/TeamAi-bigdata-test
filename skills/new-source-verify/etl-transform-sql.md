# ETL 转换逻辑验证 SQL 模板

> 本文件为 Step 5（验证 ETL 转换逻辑）的 SQL 模板库。
> 核心原则：所有转换逻辑直接写入 WHERE 条件，避免子查询预计算；严格保留原始字段名；dt 分区条件独立显式声明。

---

## 零、过滤条件转换规则

> **需求文档是自然语言描述，需要结合上游表知识库（`dataware_table/*.md`）转换为 SQL 筛选逻辑。**

### 转换流程

```
需求文档（自然语言）  +  上游表知识库（字段名、类型、注释）
        ↓                          ↓
        └────────── 模型分析 ──────────┘
                        ↓
              SQL 过滤条件 / 转换表达式
```

### 转换示例

| 需求文档描述 | 上游表字段（来自知识库） | 转换后的 SQL 条件 |
|-------------|------------------------|------------------|
| "ZK开头的结算编码" | `settle_code` (结算编码) | `settle_code LIKE 'ZK%'` |
| "有效的直客K码" | `status` (状态), `up_time` (上线时间), `expire_time` (到期时间) | `status = '1' AND to_date(up_time) <= '${yyyy_mm_dd}' AND to_date(expire_time) >= '${yyyy_mm_dd}'` |
| "品牌客户" | `customer_classify` (客户分类) | `customer_classify = 'BRAND'` |
| "ZK888888归属总部" | `settle_org_code` (结算组织编码) | `settle_org_code = '888888'` |
| "大客户结算主表" | `mdm_big_customer_settle` (大客户结算) | `dim.mdm_big_customer_settle` |

### 转换步骤

1. **阅读需求文档**：提取业务规则的自然语言描述
2. **查阅上游表知识库**：在 `dataware_table/*.md` 中查找对应字段名和注释
3. **匹配语义**：将自然语言关键词与字段注释匹配（如"结算编码" → `settle_code`）
4. **生成 SQL 条件**：根据业务规则生成 WHERE 子句
5. **人工确认**：展示转换结果给用户确认

---

## 一、基础模板

```sql
SELECT
    a.<主键字段>,
    a.<源字段>,
    b.<目标字段>
FROM (
    SELECT *
    FROM <上游源表>
    WHERE dt = '<分区值>'
      AND <上游过滤条件>    -- 由需求文档+知识库转换而来
) a
LEFT JOIN <结果表> b
    ON a.<关联键> = b.<关联键>
    AND a.dt = b.dt
WHERE
    b.dt = '<分区值>'
    AND NVL(CAST(<转换表达式> AS STRING), '') <> NVL(CAST(b.<目标字段> AS STRING), '')
LIMIT 10
```

### 关键说明

| 要素 | 写法 | 作用 |
|------|------|------|
| 上游过滤条件 | 写在 a 的子查询 WHERE 中 | 由需求文档+知识库转换，只取需要验证的数据 |
| 转换表达式 | `NVL(CAST(<转换表达式> AS STRING), '')` | 直接在 WHERE 中复现 ETL 逻辑，不创建中间字段 |
| 分区条件 | a 的分区在子查询中过滤，b 的分区在外层 WHERE 过滤 | 各自独立声明 |
| NULL 安全 | `NVL(CAST(... AS STRING), '')` | 统一将 NULL 转为空字符串比对 |

---

## 二、转换类型模板

### 1. 条件映射（CASE WHEN）

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

---

### 2. 空值填充（COALESCE / IF）

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

---

### 3. 字段拼接（CONCAT）

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

---

### 4. 关联取值（维表映射）

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

---

### 5. 固定值（硬编码）

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

## 三、批量验证模板

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

## 四、使用规范

### 必须遵守的 4 条规则

1. **上游过滤条件必须声明**
   - a 表使用子查询，包含 `dt = '<分区值>'` 和 `<上游过滤条件>`
   - 上游过滤条件由需求文档（自然语言）+ 上游表知识库（`dataware_table/*.md`）转换而来
   - 转换后需人工确认条件是否正确

2. **WHERE 条件分层**
   ```sql
   -- a 的分区和过滤在子查询中
   FROM (SELECT * FROM <上游源表> WHERE dt = '<分区值>' AND <上游过滤条件>) a
   -- b 的分区在外层 WHERE
   WHERE b.dt = '<分区值>'
     AND [NVL(CAST(转换表达式)) <> NVL(CAST(目标字段))]  -- 差异条件独立成行
   ```

3. **转换表达式写法**
   - 由需求文档（自然语言）+ 上游表知识库转换而来
   - 用 `NVL(CAST(... AS STRING), '')` 包裹整个表达式
   - 示例：需求"品牌客户映射为1" + 知识库字段 `customer_classify` → `CASE WHEN customer_classify='BRAND' THEN '1' ELSE '2' END`

4. **分区字段 dt 强制声明**
   - 上游表在子查询中声明 `dt = '<分区值>'`
   - 结果表在外层 WHERE 声明 `b.dt = '<分区值>'`
   - 禁止省略为 `a.dt = b.dt`（避免分区错位时漏检）

---

## 五、典型错误写法（避免）

```sql
-- 错误1：上游表缺少过滤条件（可能混入不需要的数据）
FROM <上游源表> a  -- 未过滤 status、settle_code 等条件

-- 错误2：转换逻辑写在 JOIN 条件（导致无法定位差异）
LEFT JOIN b ON ... AND CAST(a.status AS STRING) = CAST(b.status_flag AS STRING)

-- 错误3：省略 dt 分区条件
WHERE NVL(CAST(...)) <> NVL(CAST(...))  -- 未过滤分区，可能混入历史数据

-- 错误4：重命名字段（违背保留原始字段名原则）
SELECT a.status AS source_value, b.status_flag AS target_value ...
```

---

## 六、异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| 单字段 diff_cnt | = 0 | > 0 | ETL 转换逻辑有误 |
| 批量验证各字段 diff_cnt | = 0 | > 0 | 字段转换结果不一致 |
| LIMIT 10 返回行数 | = 0 | > 0 | 存在转换差异 |
