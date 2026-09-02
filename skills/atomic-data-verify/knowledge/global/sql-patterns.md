# SQL 语法模式

## MySQL 语法注意事项

### 1. NVL 函数

MySQL 不支持 NVL 函数，需使用 COALESCE 替代：

```sql
-- Oracle/Hive
NVL(field, 'default')

-- MySQL
COALESCE(field, 'default')
```

### 2. CAST 类型转换

MySQL 不支持 `CAST(... AS STRING)`，需使用 `CAST(... AS CHAR)`：

```sql
-- Hive
CAST(field AS STRING)

-- MySQL
CAST(field AS CHAR)
```

### 3. NULLIF 函数

MySQL 支持 NULLIF 函数，可用于将空字符串转为 NULL：

```sql
NULLIF(field, '')
```

### 4. 归一化模式

将 NULL 和空字符串统一归一化为哨兵值：

```sql
-- Hive
NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')

-- MySQL（varchar 字段）
COALESCE(CAST(NULLIF(field, '') AS CHAR), 'XXT')

-- MySQL（int/bigint 字段，无需 NULLIF）
COALESCE(CAST(field AS CHAR), 'XXT')
```

### 5. int/bigint 字段的 NULL 处理

int/bigint 类型字段不会存储空字符串，使用 `NULLIF(field, '')` 无意义且可能导致类型转换错误。

**正确做法**：
- int/bigint 字段：`COALESCE(CAST(field AS CHAR), 'XXT')`
- varchar 字段：`COALESCE(CAST(NULLIF(field, '') AS CHAR), 'XXT')`

**来源**：2026-06-18 nike.audience_list 验证
