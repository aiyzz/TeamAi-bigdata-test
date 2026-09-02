# SQL 初稿

## 基础信息

| 项目 | 内容 |
|------|------|
| 生产表 | nike.audience_list |
| 测试表 | nike.audience_list_copy |
| 分区值 | 无分区字段 |
| 复合主键 | id + name |
| 激活能力 | 能力0（数据质量检查）, 能力1（不变更记录验证） |

---

## 主流程 SQL

### 1.1 空表前置检查
```sql
SELECT '测试表' AS tbl, count(*) AS cnt FROM nike.audience_list_copy
UNION ALL
SELECT '生产表' AS tbl, count(*) AS cnt FROM nike.audience_list
```

### 1.2 主键唯一性
```sql
SELECT id, name, count(*) AS cnt
FROM nike.audience_list_copy
GROUP BY id, name
HAVING count(*) > 1
```

### 1.3 差异行统计
```sql
-- 新增条数
SELECT count(*) AS added_cnt
FROM nike.audience_list_copy a
LEFT JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name
WHERE b.id IS NULL
```
```sql
-- 减少条数
SELECT count(*) AS removed_cnt
FROM nike.audience_list_copy a
RIGHT JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name
WHERE a.id IS NULL
```

### 1.4 字段结构比对
```sql
SELECT table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'nike'
  AND table_name IN ('audience_list', 'audience_list_copy')
GROUP BY table_name
```

---

## 能力0：数据质量检查 SQL

### 0.1 维度字段空值占比
```sql
SELECT 'id' AS field_name, count(*) AS total, sum(case when id is null then 1 else 0 end) AS null_cnt, round(sum(case when id is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'name' AS field_name, count(*) AS total, sum(case when name is null or name = '' then 1 else 0 end) AS null_cnt, round(sum(case when name is null or name = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'creator_id' AS field_name, count(*) AS total, sum(case when creator_id is null then 1 else 0 end) AS null_cnt, round(sum(case when creator_id is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'status' AS field_name, count(*) AS total, sum(case when status is null then 1 else 0 end) AS null_cnt, round(sum(case when status is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'created_time' AS field_name, count(*) AS total, sum(case when created_time is null then 1 else 0 end) AS null_cnt, round(sum(case when created_time is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'is_sharing' AS field_name, count(*) AS total, sum(case when is_sharing is null then 1 else 0 end) AS null_cnt, round(sum(case when is_sharing is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'audience_id' AS field_name, count(*) AS total, sum(case when audience_id is null then 1 else 0 end) AS null_cnt, round(sum(case when audience_id is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'creator_name' AS field_name, count(*) AS total, sum(case when creator_name is null or creator_name = '' then 1 else 0 end) AS null_cnt, round(sum(case when creator_name is null or creator_name = '' then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
UNION ALL
SELECT 'appid' AS field_name, count(*) AS total, sum(case when appid is null then 1 else 0 end) AS null_cnt, round(sum(case when appid is null then 1 else 0 end) * 100.0 / count(*), 2) AS null_pct FROM nike.audience_list_copy
```

### 0.2 枚举值分布 - status
```sql
SELECT
    status,
    count(*) AS cnt,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE WHEN status = 1 THEN '有效' ELSE '未知值' END AS value_desc
FROM nike.audience_list_copy
GROUP BY status
ORDER BY cnt DESC
```

### 0.3 枚举值分布 - is_sharing
```sql
SELECT
    is_sharing,
    count(*) AS cnt,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) AS pct,
    CASE
        WHEN is_sharing = 0 THEN '不共享'
        WHEN is_sharing = 1 THEN '共享'
        ELSE '未知值'
    END AS value_desc
FROM nike.audience_list_copy
GROUP BY is_sharing
ORDER BY cnt DESC
```

---

## 能力1：不变更记录验证 SQL

### 1.1 共同记录数
```sql
SELECT count(*) AS common_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name
```

### 1.2 批量字段差异数统计
```sql
SELECT 'creator_id' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.creator_id,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.creator_id,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'status' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.status,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.status,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'created_time' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.created_time,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.created_time,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'is_sharing' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.is_sharing,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.is_sharing,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'audience_id' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.audience_id,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.audience_id,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'creator_name' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.creator_name,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.creator_name,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name

UNION ALL

SELECT 'appid' AS field_name,
    SUM(CASE WHEN COALESCE(CAST(NULLIF(a.appid,'') AS CHAR), 'XXT')
           <> COALESCE(CAST(NULLIF(b.appid,'') AS CHAR), 'XXT') THEN 1 ELSE 0 END) AS diff_cnt
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name
```

### 1.3 差异明细查询（按需执行）
```sql
-- 当某个字段 diff_cnt > 0 时执行
SELECT
    a.id, a.name,
    a.<差异字段> AS a_value,
    b.<差异字段> AS b_value
FROM nike.audience_list_copy a
INNER JOIN nike.audience_list b ON a.id = b.id AND a.name = b.name
WHERE COALESCE(CAST(NULLIF(a.<差异字段>,'') AS CHAR), 'XXT')
   <> COALESCE(CAST(NULLIF(b.<差异字段>,'') AS CHAR), 'XXT')
LIMIT 10
```
