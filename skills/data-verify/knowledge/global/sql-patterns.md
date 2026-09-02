# SQL 语法模式

> 本技能统一使用 **Hive SQL** 语法。所有生成的验证 SQL 均按 Hive 规范编写。

---

## 一、Hive 语法要点

### 1. NVL 函数

Hive 支持 `NVL(field, default)`，用于 NULL 值替换（等价于 Oracle 的 NVL）：

```sql
NVL(field, 'default')
```

> 不要使用 `COALESCE` 写归一化表达式——统一用 `NVL`，保持全技能风格一致。
> （注：Hive 也支持 COALESCE，但本技能的 NULL 归一化一律用 NVL。）

### 2. CAST 类型转换

Hive 使用 `CAST(... AS STRING)` 将任意类型转为字符串：

```sql
CAST(field AS STRING)
```

> 不要使用 `CAST(... AS CHAR)`（那是 MySQL 写法）。

### 3. NULLIF 函数

Hive 支持 `NULLIF(a, b)`：当 a = b 时返回 NULL，否则返回 a。用于把空字符串转为 NULL：

```sql
NULLIF(field, '')
```

---

## 二、归一化模式（NULL 与空字符串统一）

字段比对时，需将 NULL 和空字符串统一归一化为哨兵值 `'XXT'`，避免 `NULL = NULL` 误判为一致。

### 通用模式

```sql
-- varchar 字段（先空串转 NULL，再归一化）
NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')

-- int/bigint/decimal/float 字段（不会存空字符串，无需 NULLIF）
NVL(CAST(field AS STRING), 'XXT')
```

### 哨兵值选择

- 使用 `'XXT'` 作为 NULL 的哨兵值
- 确保哨兵值不出现在业务数据中
- NULL 和空字符串统一归一化为哨兵值

---

## 三、int/bigint 字段的 NULL 处理（重要）

int/bigint/decimal/float 类型字段不会存储空字符串，对它们使用 `NULLIF(field, '')` 无意义，且 Hive 会把 `''` 隐式转为数值（得到 NULL），造成无谓的类型转换，甚至行为异常。

**正确做法（按字段类型选择）**：

| 字段类型 | 归一化表达式 |
|----------|--------------|
| varchar / char / string | `NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')` |
| int / bigint | `NVL(CAST(field AS STRING), 'XXT')` |
| decimal / float / double | `NVL(CAST(field AS STRING), 'XXT')` |

> 生成字段比对 SQL 时，必须先从 schema 读取字段类型，再按上表选择对应表达式，不要对所有字段套用同一个 NULLIF 模板。

**来源**：2026-06-18 nike.audience_list 验证
