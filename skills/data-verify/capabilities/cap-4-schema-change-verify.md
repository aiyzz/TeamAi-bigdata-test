# 能力 4：验证字段增减

> 验证表结构变更（新增字段、删除字段）的正确性：原有字段未被破坏、新增字段数据正确。

---

## 触发条件

| 条件 | 说明 |
|------|------|
| 测试表与生产表字段列表不一致 | 存在新增或删除的字段 |
| 需求文档提到「增加字段」「删除字段」「结构变更」 | 业务预期结构变更 |

---

## 输入

| 参数 | 必填 | 说明 | 来源 |
|------|------|------|------|
| 生产表名 | 是 | 基准表 | 知识库 |
| 测试表名 | 是 | 变更后的表 | 知识库 |
| 主键 | 是 | JOIN 键 | 知识库 |
| 分区值 | 否 | 如有分区字段则必填 | Step 0 自动识别 |
| 新增来源表 | D1/D3 必填 | 新增字段的来源表 | Step 3.2 用户确认 |
| 关联键 | D1/D3 必填 | 测试表与源表的关联字段 | Step 3.2 用户确认 |
| 筛选条件 | D1/D3 必填 | 从源表筛选数据的条件 | Step 3.2 用户确认 |
| 字段映射 | D1/D3 必填 | 源字段→目标字段的映射关系 | Step 3.2 用户确认 |
| ETL 逻辑说明 | D3 必填 | 新增字段的转换逻辑 | Step 3.2 用户确认 |

---

## 子场景识别

| 子场景 | 说明 | 触发条件 |
|--------|------|----------|
| D1 — 增加字段（直接映射） | 新增字段直接取自来源表 | 有新增字段 + 来源表 |
| D2 — 删除字段 | 测试表删除了某些字段 | 有删除字段 |
| D3 — 增加字段（ETL 转换） | 新增字段经 ETL 转换 | 有新增字段 + ETL 逻辑 |

---

## SQL 模板

- 主流程：`templates/common/field-structure-compare-sql.md`（字段结构比对，主流程执行）
- 能力专用：`templates/cap-4-schema-change-sql.md`（字段增减验证、ETL 转换验证）

---

## 验证步骤

### Step 1: 字段变更清单

从知识库 DDL 提取两表字段列表，自动比对：

```markdown
### 新增字段（测试表有、生产表没有）
| 字段名 | 类型 | 注释 | 分类 |

### 删除字段（生产表有、测试表没有）
| 字段名 | 类型 | 注释 | 分类 |

### 共同字段（两表都有）
| 字段名 | 类型 | 分类 |
```

### Step 2: 数据量一致性验证

结构变更不应改变数据量：

```sql
SELECT '生产表' AS tbl, COUNT(*) AS cnt FROM <生产表> WHERE dt = '<分区值>'
UNION ALL
SELECT '测试表' AS tbl, COUNT(*) AS cnt FROM <测试表> WHERE dt = '<分区值>'
```

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

### Step 3: 原有字段保护验证

对共同字段（排除主键和分区字段），按 `cap-4-schema-change-sql.md` 二 批量比对：

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

**预期**：所有共同字段 diff_cnt = 0

### Step 4: 新增字段验证

**D1 — 直接映射**：
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

**D3 — ETL 转换**：按 `cap-4-schema-change-sql.md` 四 逐字段验证。

**新增字段质量检查**：
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

### Step 5: 删除字段确认

```sql
SELECT COUNT(*) AS cnt
FROM information_schema.columns
WHERE table_schema = '<库名>'
  AND table_name = '<测试表>'
  AND column_name = '<删除字段>'
```

**预期**：cnt = 0（字段已删除）

---

## 验证标准

| 验证项 | 预期 | 状态 |
|--------|------|------|
| 数据量一致 | test_only = 0, prod_only = 0 | ✅ / ❌ |
| 原有字段 diff_cnt | 全部 = 0 | ✅ / ❌ > 0 |
| 新增字段 diff_cnt（直接映射） | = 0 | ✅ / ❌ > 0 |
| 新增字段 diff_cnt（ETL 转换） | = 0 | ✅ / ❌ > 0 |
| 新增字段空值占比 | ≤ 50% | ⚠️ > 50% / ✅ ≤ 50% |
| 删除字段已确认 | cnt = 0 | ✅ / ❌ > 0 |

---

## 输出格式

```markdown
## 字段增减验证

### 字段变更清单
#### 新增字段
| 字段名 | 类型 | 注释 | 分类 |

#### 删除字段
| 字段名 | 类型 | 注释 | 分类 |

### 数据量一致性
| 环境 | 记录数 |
|------|--------|

### 原有字段保护
| 字段 | 差异数 | 状态 |
|------|--------|------|

### 新增字段验证
| 字段 | 来源 | 匹配数 | 差异数 | 空值占比 | 状态 |
|------|------|--------|--------|----------|------|

### 删除字段确认
| 字段 | 是否已删除 | 状态 |
|------|-----------|------|
```
