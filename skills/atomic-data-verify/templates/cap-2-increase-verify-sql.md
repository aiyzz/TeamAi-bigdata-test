# 能力2：验证增加记录 SQL 模板

> 本文件为能力2（验证增加记录）的 SQL 模板。
> 用于验证测试表中新增的数据是否符合预期：来源可追溯、筛选条件正确。
> 模板中 `<测试表>`、`<生产表>`、`<上游表>`、`<主键字段>`、`<关联字段>`、`<分区值>`、`<筛选条件>`、`<筛选字段>` 为占位符，执行时替换为实际值。

---

## 一、来源追溯匹配验证

> 验证新增记录是否全部来自上游表。

```sql
SELECT
  CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END AS match_status,
  COUNT(*) AS cnt
FROM <测试表> t
LEFT JOIN <上游表> o
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE WHEN o.<关联字段> IS NOT NULL THEN '匹配' ELSE '未匹配' END
```

**预期结果**：匹配数 = 新增数，未匹配数 = 0

**输出格式**：

| match_status | cnt |
|--------------|-----|
| 匹配 | 100 |
| 未匹配 | 0 |

---

## 二、筛选条件符合性验证

> 验证新增记录是否全部符合筛选条件。

```sql
SELECT
  CASE
    WHEN <筛选条件> THEN '符合条件'
    ELSE '不符合条件'
  END AS filter_status,
  COUNT(*) AS cnt
FROM <测试表> t
INNER JOIN <上游表> o
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY CASE
    WHEN <筛选条件> THEN '符合条件'
    ELSE '不符合条件'
  END
```

**预期结果**：符合条件数 = 新增数，不符合条件数 = 0

**输出格式**：

| filter_status | cnt |
|---------------|-----|
| 符合条件 | 100 |
| 不符合条件 | 0 |

---

## 三、不符合条件数据排查

> 当筛选条件符合性验证发现不符合条件数据时，查询具体明细。

```sql
SELECT
  t.<主键字段>,
  o.<筛选字段1>,
  o.<筛选字段2>
FROM <测试表> t
INNER JOIN <上游表> o
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
  AND NOT (<筛选条件>)
LIMIT 20
```

**预期结果**：0 条记录

---

## 四、新增数据来源特征明细

> 分析新增记录在筛选字段上的分布。

```sql
SELECT
  <筛选字段1>,
  <筛选字段2>,
  COUNT(*) AS cnt
FROM <测试表> t
INNER JOIN <上游表> o
  ON t.<关联字段> = o.<关联字段> AND t.dt = o.dt
WHERE t.dt = '<分区值>'
  AND NOT EXISTS (
    SELECT 1 FROM <生产表> p
    WHERE p.<主键字段> = t.<主键字段> AND p.dt = t.dt
  )
GROUP BY <筛选字段1>, <筛选字段2>
ORDER BY cnt DESC
```

**输出格式**：

| 筛选字段1 | 筛选字段2 | cnt |
|-----------|-----------|-----|
| 值A | 值X | 50 |
| 值B | 值Y | 30 |
| 值C | 值Z | 20 |

---

## 五、异常判定标准

| 检查项 | 预期 | ❌ FAIL 条件 | 说明 |
|--------|------|-------------|------|
| 来源匹配数 | = 新增数 | < 新增数 | 存在无法追溯来源的记录 |
| 未匹配数 | = 0 | > 0 | 存在无法追溯来源的记录 |
| 符合条件数 | = 新增数 | < 新增数 | 存在不符合筛选条件的记录 |
| 不符合条件数 | = 0 | > 0 | 存在不符合筛选条件的记录 |

---

## 六、占位符说明

| 占位符 | 替换为 | 示例 |
|--------|--------|------|
| `<测试表>` | 测试表完整名称 | `temp.kcode_crm_ks_dku` |
| `<生产表>` | 生产表完整名称 | `ytrpt.kcode_crm_ks_dku` |
| `<上游表>` | 新增数据的来源表 | `ytrpt.ods_jsc_t_market_direct_customer_dd` |
| `<主键字段>` | 测试表的主键字段 | `kcode` |
| `<关联字段>` | 测试表与上游表的关联字段 | `k_code` |
| `<分区值>` | 分区日期 | `20260618` |
| `<筛选条件>` | 新增数据应满足的筛选逻辑 | `settle_code LIKE 'ZK%' AND status = '1'` |
| `<筛选字段>` | 用于分析分布的字段 | `settle_code`, `status` |

---

## 七、注意事项

- 大表务必加分区条件，避免全表扫描
- `NOT EXISTS` 子查询用于排除生产表已有的记录，只关注新增部分
- 筛选条件可能涉及多个字段的组合，需仔细核对业务逻辑
- 若上游表有多条记录对应同一条新增记录，可能需要先去重再关联
- LIMIT 默认 20，仅展示排查明细，若需统计总数可额外执行 `SELECT COUNT(*)`
