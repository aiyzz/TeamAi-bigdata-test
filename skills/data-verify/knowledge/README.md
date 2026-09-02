# 知识库说明

本目录用于存储数据验证过程中积累的知识，采用分层存储结构。

## 目录结构

```
knowledge/
├── README.md               # 本文件
├── index.md                # 知识索引
│
├── global/                 # 全局知识（每次都加载）
│   ├── sql-patterns.md     # SQL 语法模式（MySQL/Hive差异等）
│   └── verify-rules.md     # 验数通用规则（状态判定、NULL处理等）
│
├── table/                  # 按表分组（只加载当前表）
│   └── {database}.{table}/
│       ├── schema.md       # 表结构 + ETL逻辑
│       ├── data-patterns.md # 数据规律
│       └── lessons.md      # 踩坑记录
│
└── archive/                # 归档区（超过90天的记录）
    └── {YYYY-MM}/
```

## 加载策略

| 层级 | 加载时机 | 说明 |
|------|----------|------|
| global/ | 每次验证 | SQL语法、通用规则 |
| table/{db}.{table}/ | 验证该表时 | 表结构、数据规律、踩坑记录 |
| archive/ | 不自动加载 | 需要时手动查询 |

## 文件说明

### global/sql-patterns.md
SQL 语法模式，包括：
- MySQL/Hive/Oracle 语法差异
- NULL 处理规则
- 类型转换规则

### global/verify-rules.md
验数通用规则，包括：
- 状态判定标准（FAIL/WARN/PASS）
- 字段比对规则
- JOIN 膨胀防护
- 验证范围控制

### table/{db}.{table}/schema.md
表结构信息，包括：
- 字段列表和分类（维度/指标/分区）
- 分区信息
- 主键
- ETL 逻辑（源表、关联键、筛选条件、字段映射）

### table/{db}.{table}/data-patterns.md
数据规律，包括：
- 枚举值分布
- ETL 空值填充规则
- 已知数据特征
- 历史验证结果

### table/{db}.{table}/lessons.md
踩坑记录，包括：
- 已解决问题
- 待验证假设
- 已废弃知识

## 更新规则

1. **先读取再写入**：写入前先读取现有文件内容
2. **去重检查**：检查新知识是否已存在（按标题和内容相似度）
3. **按状态分类**：已解决/待解决/待验证
4. **追加而非覆盖**：新内容追加到文件末尾
5. **更新索引**：更新 `index.md`

## 归档策略

| 条件 | 归档动作 |
|------|----------|
| lessons.md 中的记录超过 90 天 | 移动到 archive/{YYYY-MM}/ |
| 已标记为"已解决"的记录超过 30 天 | 移动到归档区 |
| data-patterns.md 中的历史验证结果超过 180 天 | 删除（保留摘要） |

## 迁移说明

从旧结构迁移的文件：
- `dataware_table/{db}.{table}.md` → `table/{db}.{table}/schema.md`
- `sql-patterns.md` → `global/sql-patterns.md`
- `data-patterns.md` → `table/{db}.{table}/data-patterns.md`
- `verify-lessons.md` → `table/{db}.{table}/lessons.md` + `global/verify-rules.md`
