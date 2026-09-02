# 能力 1：验证不变更记录

> 优化需求的核心能力。验证测试表中与生产表共同存在的记录，其字段值未被修改。

---

## 触发条件

| 条件 | 说明 |
|------|------|
| 需求类型为「优化需求」 | 新增数据来源、扩展模型表等，原有数据应保持不变 |
| 测试表与生产表存在共同记录 | 主键交集 > 0 |
| 需求文档未说明原有数据会被修改 | 若需求明确会修改某些字段，则不触发或部分排除 |

### 典型场景

- 结果表新增数据来源，原有记录应保持不变
- 模型表扩展，新增维度/指标，原有字段值不变
- 数据量增加的优化需求（能力2 验证新增部分，本能力验证原有部分）

---

## 输入

| 参数 | 必填 | 说明 |
|------|------|------|
| 生产表名 | 是 | 基准表 |
| 测试表名 | 是 | 优化后的表 |
| 主键 | 是 | JOIN 键 |
| 分区值 | 否 | 如有分区字段则必填 |
| 共同字段列表 | 自动 | 排除主键和分区字段后的所有共同字段 |

---

## SQL 模板

引用 `templates/cap-1-unchanged-verify-sql.md`。

---

## 验证步骤

### Step 1: 统计共同记录数

```sql
SELECT count(*) AS common_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'
```

### Step 2: 批量字段级比对

从知识库提取共同字段列表（排除主键和分区字段），按 `field-compare-sql.md` 二.2 生成 UNION ALL 批量比对 SQL：

```sql
SELECT
    '<field>' AS field_name,
    SUM(CASE WHEN NVL(CAST(NULLIF(a.<field>,'') AS STRING), 'XXT')
           <> NVL(CAST(NULLIF(b.<field>,'') AS STRING), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM <测试表> a
INNER JOIN <生产表> b ON a.<主键> = b.<主键>
WHERE a.dt = '<分区值>' AND b.dt = '<分区值>'

UNION ALL
-- 对每个共同字段重复上述模式
```

### Step 3: 差异明细查询

对 diff_cnt > 0 的字段，按 `field-compare-sql.md` 三.1 查询差异明细：

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

---

## 验证标准

| 结果 | 状态 | 说明 |
|------|------|------|
| 所有字段 diff_cnt = 0 | ✅ PASS | 原有记录完全一致 |
| 部分字段 diff_cnt > 0 | ⚠️ WARN | 存在差异，需查看明细 |
| 所有字段 diff_cnt 相同且 > 0 | ❌ FAIL | 可能分区条件错误或 JOIN 键不当 |
| 差异行占比 > 50% | ❌ FAIL | 两表数据差异过大 |

---

## 输出格式

```markdown
## 不变更记录验证

- 共同记录数：N

| 字段 | 差异数 | 状态 |
|------|--------|------|
| field1 | 0 | ✅ |
| field2 | 3 | ⚠️ |

### 差异明细（field2，共 3 条，显示前 10 条）
| 主键 | a_field2 | b_field2 |
|------|----------|----------|
```
