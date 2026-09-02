# 知识沉淀分层存储优化设计

## 一、问题现状

### 当前结构

```
.claude/skills/atomic-data-verify/
├── dataware_table/              # 表DDL及字段分类（独立目录）
│   ├── nike.kcode_crm_ks_dku.md
│   └── nike.kcode_crm_ks_dku_pro.md
└── knowledge/
    ├── README.md
    ├── sql-patterns.md          # SQL语法模式（全局）
    ├── data-patterns.md         # 数据规律（按表混合）
    └── verify-lessons.md        # 验数踩坑记录（按表混合）
```

### 问题

| 问题 | 原因 | 影响 |
|------|------|------|
| 内容冗余 | 每次验证都追加，不检查重复 | 文件膨胀，有价值信息被淹没 |
| 初始化慢 | 每次加载全部知识 | 与当前表无关的知识也被读取 |
| 难以维护 | 所有表的知识混在一起 | 难以清理、归档、按表查询 |
| 目录分散 | `dataware_table/` 和 `knowledge/` 分离 | 表信息分散在两个位置，难以管理 |

---

## 二、分层存储设计

### 2.1 目录结构

**合并策略**：将 `dataware_table/` 的内容合并到 `knowledge/table/{db}.{table}/schema.md`，删除 `dataware_table/` 目录。

```
.claude/skills/atomic-data-verify/
└── knowledge/
    ├── README.md                    # 知识库说明（保留）
    │
    ├── global/                      # 全局知识（每次初始化都加载）
    │   ├── sql-patterns.md          # SQL语法模式（MySQL/Hive差异等）
    │   └── verify-rules.md          # 验数通用规则（状态判定、NULL处理等）
    │
    ├── table/                       # 按表分组（只加载当前表）
    │   └── {database}.{table}/      # 每个表一个目录
    │       ├── schema.md            # 表结构 + ETL逻辑（合并原dataware_table）
    │       ├── data-patterns.md     # 该表的数据规律
    │       └── lessons.md           # 该表的踩坑记录
    │
    ├── archive/                     # 归档区（超过90天的记录）
    │   └── {YYYY-MM}/               # 按月归档
    │       └── {database}.{table}/
    │           └── lessons.md
    │
    └── index.md                     # 知识索引（可选，用于快速检索）

# 删除的目录
# ❌ dataware_table/ （内容已合并到 knowledge/table/{db}.{table}/schema.md）
```

### 2.2 文件命名规范

| 层级 | 命名规则 | 示例 |
|------|----------|------|
| 全局知识 | 固定文件名 | `global/sql-patterns.md` |
| 表级目录 | `{database}.{table}` | `table/nike.kcode_crm_ks_dku/` |
| 表级文件 | 固定文件名 | `table/nike.kcode_crm_ks_dku/lessons.md` |
| 归档目录 | `{YYYY-MM}` | `archive/2026-06/` |

---

## 三、文件内容格式

### 3.1 全局知识：global/sql-patterns.md

```markdown
# SQL 语法模式

## Hive 语法注意事项

### 1. NVL 函数
Hive 支持 NVL，统一用 NVL 做 NULL 归一化：
- Hive: NVL(field, 'default')

### 2. CAST 类型转换
Hive 使用 CAST(... AS STRING)（不要用 CAST(... AS CHAR)）

### 3. int/bigint 字段的 NULL 处理
- int/bigint/decimal/float: NVL(CAST(field AS STRING), 'XXT')（无需 NULLIF）
- varchar: NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')

---

## 数据库类型检查清单

执行SQL前必须检查：
1. 目标数据库类型（MySQL/Hive/Oracle）
2. 根据类型调整语法
3. 特别注意：NVL、CAST、日期函数
```

### 3.2 全局知识：global/verify-rules.md

```markdown
# 验数通用规则

## 状态判定规则

| 检查项 | ❌ FAIL | ⚠️ WARN | ✅ PASS |
|--------|---------|---------|---------|
| 主键唯一性 | 重复 > 0 | - | 重复 = 0 |
| 维度空值占比 | - | > 5% | ≤ 5% |
| 指标空值零值占比 | - | > 30% | ≤ 30% |
| 字段比对差异 | diff_cnt > 0 | - | diff_cnt = 0 |
| 来源追溯匹配 | 匹配率 < 100% | - | 匹配率 = 100% |
| 筛选条件符合 | 不符合条件 > 0 | - | 不符合条件 = 0 |

**整体结论判定**：
- 存在任何 ❌ FAIL → 不通过 ❌
- 仅存在 ⚠️ WARN → 通过（附警告） ✅⚠️
- 全部 ✅ PASS → 通过 ✅

---

## NULL 处理规则

### 字段比对时的归一化模式

| 字段类型 | 处理方式 |
|----------|----------|
| varchar / char / string | NVL(CAST(NULLIF(field, '') AS STRING), 'XXT') |
| int / bigint | NVL(CAST(field AS STRING), 'XXT') |
| decimal / float / double | NVL(CAST(field AS STRING), 'XXT') |

### 哨兵值选择

- 使用 'XXT' 作为 NULL 的哨兵值
- 确保哨兵值不出现在业务数据中
- NULL 和空字符串统一归一化为哨兵值

---

## JOIN 膨胀防护

当上游表可能有重复记录时，使用子查询去重：

```sql
LEFT JOIN (
  SELECT key_field, target_field, dt
  FROM upstream_table
  WHERE dt = '{partition}' AND {filter}
  GROUP BY key_field, target_field, dt
) src ON t.key = src.key_field AND t.dt = src.dt
```

---

## 验证范围控制

当用户要求"只验证新增记录"时，添加 NOT EXISTS 排除共同记录：

```sql
WHERE t.dt = '{partition}'
  AND NOT EXISTS (
    SELECT 1 FROM production_table p
    WHERE p.pk = t.pk AND p.dt = t.dt
  )
```
```

### 3.3 表级知识：table/{database}.{table}/schema.md

> 合并原 `dataware_table/{database}.{table}.md` 的内容，包含完整的表结构和ETL逻辑。

```markdown
# {table_name}

- **表名**：{database}.{table_name}
- **表描述**：{COMMENT}
- **最后更新**：{YYYY-MM-DD}

## 字段列表

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| rpt_date | varchar(255) | 日期 | 维度 |
| sum_type | varchar(255) | 日期维度 d:日 m：月 y：年 | 维度 |
| vip_id | varchar(255) | vip客户代码 | 维度 |
| vip_name | varchar(255) | vip客户姓名 | 维度 |
| kcode | varchar(255) | 客户代码 | 维度（主键） |
| kname | varchar(255) | 客户姓名 | 维度 |
| taking_num | varchar(255) | 业务量 | 指标 |
| taking_num_ly | varchar(255) | 去年同期业务量 | 指标 |
| last_num | varchar(255) | 上一期业务量 | 指标 |
| k_type | varchar(255) | 客户模式 | 维度 |
| region_code | varchar(255) | 省区编码 | 维度 |
| region_name | varchar(255) | 省区名称 | 维度 |
| department_code | varchar(255) | 市场部/营销组编码 | 维度 |
| department_name | varchar(255) | 市场部/营销组名称 | 维度 |
| first_tab_type | varchar(255) | 品牌：1;非品牌:2 | 维度 |
| customer_type | varchar(255) | 客户类型（模式-品牌） | 维度 |
| third_tab_type | varchar(255) | 含义乌商贸：1，不含义乌商贸：2 | 维度 |
| sale_emp_code | varchar(255) | 销售员工号 | 维度 |
| sale_emp_name | varchar(255) | 销售员名称 | 维度 |
| dt | varchar(255) | 分区字段 | 分区 |

## 分区信息

- **分区字段**：dt
- **分区格式**：yyyyMMdd

## 主键

- **主键**：kcode

## ETL 逻辑

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| nike.ods_jsc_t_market_direct_customer_dd | kcode = k_code | settle_code LIKE 'ZK%' AND status = '1' AND up_time <= '{dt}' AND expire_time >= '{dt}' |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| k_code | kcode | 直接映射 | - |
| k_name | kname | 直接映射 | - |
| sales_emp_code | sale_emp_code | 直接映射 | - |
| sales_emp_name | sale_emp_name | 直接映射 | - |
| customer_classify | first_tab_type | 条件映射 | CASE WHEN customer_classify='BRAND' THEN '1' ELSE '2' END |

### 空值填充规则

- sales_emp_code 为空时，填充为 'other'
- sales_emp_name 为空时，填充为 '其他'
```

### 3.4 表级知识：table/{database}.{table}/data-patterns.md

```markdown
# {table_name} 数据规律

- **最后更新**：{YYYY-MM-DD}

## 枚举值分布

| 字段 | 值 | 占比 | 业务含义 |
|------|-----|------|----------|
| first_tab_type | 1 | 8.03% | 品牌客户 |
| first_tab_type | 2 | 91.97% | 非品牌客户 |
| k_type | 总对总 | 99.26% | 总对总 |

## ETL 空值填充规则

- sales_emp_code 为空时，填充为 'other'
- sales_emp_name 为空时，填充为 '其他'

## 已知数据特征

- 新增数据主要来源：nike.ods_xxx
- 筛选条件：settle_code LIKE 'ZK%' AND status = '1'
- 客户模式：主要为"总对总"

## 历史验证结果

| 日期 | 测试表记录数 | 生产表记录数 | 新增数 | 结论 |
|------|-------------|-------------|--------|------|
| 2026-06-19 | 3638 | 3498 | 140 | ❌ FAIL |
| 2026-06-18 | 3498 | 3498 | 0 | ✅ PASS |
```

### 3.5 表级知识：table/{database}.{table}/lessons.md

```markdown
# {table_name} 踩坑记录

- **最后更新**：{YYYY-MM-DD}

## 已解决问题

### 1. 筛选条件边界情况（2026-06-19）

**问题**：settle_code LIKE 'ZK%' 不匹配 Z2 开头的值

**发现**：K25082775 的 settle_code 为 'Z25016365'

**结论**：这是预期行为，LIKE 'ZK%' 只匹配 ZK 开头

**状态**：✅ 已确认，非Bug

---

### 2. taking_num 差异（2026-06-19）

**问题**：K100528843 的 taking_num 不一致（测试97.0，生产100.0）

**原因**：待调查

**状态**：⏳ 待解决

---

## 待验证假设

（空）

---

## 已废弃知识

（空）
```

---

## 四、初始化逻辑

### 4.1 读取流程

```python
def initialize_knowledge(database, table):
    knowledge = {}
    
    # 1. 加载全局知识（每次都加载）
    knowledge['global'] = {
        'sql_patterns': read_file('knowledge/global/sql-patterns.md'),
        'verify_rules': read_file('knowledge/global/verify-rules.md')
    }
    
    # 2. 加载表级知识（只加载当前表）
    table_path = f'knowledge/table/{database}.{table}'
    if exists(table_path):
        knowledge['table'] = {
            'schema': read_file(f'{table_path}/schema.md'),
            'data_patterns': read_file(f'{table_path}/data-patterns.md'),
            'lessons': read_file(f'{table_path}/lessons.md')
        }
    else:
        # 首次验证该表，创建目录
        create_directory(table_path)
        knowledge['table'] = {
            'schema': None,
            'data_patterns': None,
            'lessons': None
        }
    
    # 3. 加载索引（可选，用于快速检索）
    knowledge['index'] = read_file('knowledge/index.md')
    
    return knowledge
```

### 4.2 加载对比

| 场景 | 当前方案 | 优化方案 |
|------|----------|----------|
| 验证表A | 加载全部知识（~100KB） | 加载全局+表A（~20KB） |
| 验证表B | 加载全部知识（~100KB） | 加载全局+表B（~20KB） |
| 首次验证表C | 加载全部知识（~100KB） | 加载全局（~10KB） |

**性能提升**：约 5-10 倍（取决于表数量）

---

## 五、写入逻辑

### 5.1 写入流程

```python
def write_knowledge(database, table, category, content):
    """
    写入知识沉淀
    
    Args:
        database: 数据库名
        table: 表名
        category: 分类 ('schema', 'data_patterns', 'lessons')
        content: 内容
    """
    table_path = f'knowledge/table/{database}.{table}'
    
    # 1. 确保目录存在
    create_directory(table_path)
    
    # 2. 读取现有内容
    file_path = f'{table_path}/{category}.md'
    existing = read_file(file_path) if exists(file_path) else ''
    
    # 3. 去重检查
    if is_duplicate(existing, content):
        print(f"知识已存在，跳过写入")
        return
    
    # 4. 追加写入
    append_file(file_path, content)
    
    # 5. 更新索引（可选）
    update_index(database, table, category)
```

### 5.2 去重策略

```python
def is_duplicate(existing_content, new_content):
    """
    检查新内容是否与现有内容重复
    
    策略：
    1. 精确匹配：检查标题是否已存在
    2. 相似度匹配：检查内容相似度 > 80%
    """
    # 提取新内容的标题
    new_title = extract_title(new_content)
    
    # 检查标题是否已存在
    if new_title in existing_content:
        return True
    
    # 检查内容相似度（可选）
    if similarity(existing_content, new_content) > 0.8:
        return True
    
    return False
```

### 5.3 写入时机

| 时机 | 写入内容 | 写入位置 |
|------|----------|----------|
| Step 0 获取表结构 | 表DDL、字段分类 | `table/{db}.{table}/schema.md` |
| Step 1 主流程执行 | 枚举值分布、数据特征 | `table/{db}.{table}/data-patterns.md` |
| Step 8 知识沉淀 | 新发现的教训、规律 | `table/{db}.{table}/lessons.md` |
| 全局发现 | SQL语法差异、通用规则 | `global/sql-patterns.md` |

---

## 六、归档逻辑

### 6.1 归档策略

| 条件 | 归档动作 |
|------|----------|
| lessons.md 中的记录超过 90 天 | 移动到 `archive/{YYYY-MM}/{db}.{table}/lessons.md` |
| 已标记为"已解决"的记录超过 30 天 | 移动到归档区 |
| data-patterns.md 中的历史验证结果超过 180 天 | 删除（保留摘要） |

### 6.2 归档流程

```python
def archive_knowledge():
    """
    定期归档过期知识
    建议每月执行一次
    """
    today = datetime.now()
    
    # 遍历所有表
    for table_dir in list_directories('knowledge/table'):
        db, table = parse_table_dir(table_dir)
        
        # 归档 lessons.md
        lessons_path = f'{table_dir}/lessons.md'
        if exists(lessons_path):
            content = read_file(lessons_path)
            
            # 分离已解决和待解决的记录
            resolved, pending = split_by_status(content)
            
            # 归档已解决且超过30天的记录
            archived = []
            for record in resolved:
                if (today - record.date).days > 30:
                    archived.append(record)
            
            # 写入归档区
            if archived:
                archive_path = f'knowledge/archive/{today.strftime("%Y-%m")}/{db}.{table}/lessons.md'
                write_file(archive_path, '\n'.join(archived))
            
            # 更新原文件，只保留待解决和近期已解决的
            remaining = [r for r in resolved if r not in archived] + pending
            write_file(lessons_path, '\n'.join(remaining))
        
        # 清理 data-patterns.md 中的历史验证结果
        patterns_path = f'{table_dir}/data-patterns.md'
        if exists(patterns_path):
            content = read_file(patterns_path)
            # 删除超过180天的验证结果
            cleaned = remove_old_verification_results(content, days=180)
            write_file(patterns_path, cleaned)
```

### 6.3 手动归档命令

```bash
# 归档所有过期知识
python scripts/archive_knowledge.py

# 归档指定表的知识
python scripts/archive_knowledge.py --table nike.kcode_crm_ks_dku

# 查看归档统计
python scripts/archive_knowledge.py --stats
```

---

## 七、索引机制（可选）

### 7.1 索引文件格式：knowledge/index.md

```markdown
# 知识索引

- **最后更新**：2026-06-19
- **表数量**：5

## 表列表

| 数据库 | 表名 | 最后验证 | 验证次数 | 状态 |
|--------|------|----------|----------|------|
| nike | kcode_crm_ks_dku | 2026-06-19 | 3 | ❌ FAIL |
| nike | audience_list | 2026-06-18 | 1 | ✅ PASS |
| ytrpt | kcode_crm_ks_dku_pro | 2026-06-15 | 2 | ⚠️ WARN |

## 全局知识统计

| 文件 | 记录数 | 最后更新 |
|------|--------|----------|
| sql-patterns.md | 5 | 2026-06-18 |
| verify-rules.md | 6 | 2026-06-19 |

## 最近踩坑记录

| 日期 | 表名 | 问题 | 状态 |
|------|------|------|------|
| 2026-06-19 | kcode_crm_ks_dku | taking_num差异 | 待解决 |
| 2026-06-19 | kcode_crm_ks_dku | 筛选条件边界 | 已确认 |
| 2026-06-18 | audience_list | int字段NULL处理 | 已解决 |
```

### 7.2 索引更新逻辑

```python
def update_index(database, table, category):
    """
    更新知识索引
    """
    index = read_file('knowledge/index.md')
    
    # 更新表最后验证日期
    update_table_record(index, database, table, date=today)
    
    # 更新全局知识统计
    if category in ['sql-patterns', 'verify-rules']:
        update_global_stats(index, category)
    
    # 更新最近踩坑记录
    if category == 'lessons':
        add_recent_lesson(index, database, table, lesson)
    
    write_file('knowledge/index.md', index)
```

---

## 八、迁移方案

### 8.1 从现有结构迁移

```bash
# 1. 创建新目录结构
mkdir -p knowledge/global
mkdir -p knowledge/table/nike.kcode_crm_ks_dku
mkdir -p knowledge/table/nike.kcode_crm_ks_dku_pro
mkdir -p knowledge/table/nike.audience_list
mkdir -p knowledge/archive

# 2. 迁移全局知识
mv knowledge/sql-patterns.md knowledge/global/

# 3. 从 verify-lessons.md 提取通用规则
# 手动提取或使用脚本提取通用部分到 knowledge/global/verify-rules.md

# 4. 迁移 dataware_table 到 knowledge/table/
# 将 dataware_table/*.md 移动到对应的 knowledge/table/{db}.{table}/schema.md
mv dataware_table/nike.kcode_crm_ks_dku.md knowledge/table/nike.kcode_crm_ks_dku/schema.md
mv dataware_table/nike.kcode_crm_ks_dku_pro.md knowledge/table/nike.kcode_crm_ks_dku_pro/schema.md

# 5. 按表拆分现有知识（data-patterns.md 和 verify-lessons.md）
python scripts/migrate_knowledge.py

# 6. 删除空的 dataware_table 目录
rmdir dataware_table

# 7. 创建索引
python scripts/create_index.py
```

### 8.2 迁移映射关系

| 原路径 | 新路径 | 说明 |
|--------|--------|------|
| `dataware_table/{db}.{table}.md` | `knowledge/table/{db}.{table}/schema.md` | 直接移动 |
| `knowledge/sql-patterns.md` | `knowledge/global/sql-patterns.md` | 移动 |
| `knowledge/data-patterns.md` | `knowledge/table/{db}.{table}/data-patterns.md` | 按表拆分 |
| `knowledge/verify-lessons.md` | `knowledge/table/{db}.{table}/lessons.md` | 按表拆分 |
| （从verify-lessons.md提取） | `knowledge/global/verify-rules.md` | 提取通用规则 |

### 8.3 迁移脚本：scripts/migrate_knowledge.py

```python
"""
从现有知识结构迁移到分层结构
"""

import re
import shutil
from pathlib import Path

def migrate():
    """
    完整迁移流程
    """
    print("开始迁移...")
    
    # 1. 创建新目录结构
    create_directories()
    
    # 2. 迁移 dataware_table 到 knowledge/table/{db}.{table}/schema.md
    migrate_dataware_table()
    
    # 3. 迁移全局知识
    migrate_global_knowledge()
    
    # 4. 按表拆分 data-patterns.md
    migrate_data_patterns()
    
    # 5. 按表拆分 verify-lessons.md 并提取通用规则
    migrate_verify_lessons()
    
    # 6. 创建索引
    create_index()
    
    # 7. 清理旧文件（可选，建议先备份）
    # cleanup_old_files()
    
    print("迁移完成！")

def create_directories():
    """创建新目录结构"""
    dirs = [
        'knowledge/global',
        'knowledge/archive',
    ]
    for d in dirs:
        Path(d).mkdir(parents=True, exist_ok=True)
    print("目录结构创建完成")

def migrate_dataware_table():
    """
    迁移 dataware_table 到 knowledge/table/{db}.{table}/schema.md
    """
    dataware_dir = Path('dataware_table')
    if not dataware_dir.exists():
        print("dataware_table 目录不存在，跳过")
        return
    
    for file in dataware_dir.glob('*.md'):
        # 解析文件名：{database}.{table}.md
        parts = file.stem.split('.', 1)
        if len(parts) != 2:
            print(f"跳过无法解析的文件: {file.name}")
            continue
        
        db, table = parts
        
        # 创建目标目录
        target_dir = Path(f'knowledge/table/{db}.{table}')
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # 读取原文件内容
        content = file.read_text(encoding='utf-8')
        
        # 添加元信息
        header = f"""# {table}

- **表名**：{db}.{table}
- **迁移来源**：dataware_table/{file.name}
- **最后更新**：迁移自动生成

"""
        # 写入新位置
        target_file = target_dir / 'schema.md'
        target_file.write_text(header + content, encoding='utf-8')
        
        print(f"迁移: {file.name} -> {target_file}")
    
    print("dataware_table 迁移完成")

def migrate_global_knowledge():
    """迁移全局知识"""
    # 迁移 sql-patterns.md
    src = Path('knowledge/sql-patterns.md')
    dst = Path('knowledge/global/sql-patterns.md')
    if src.exists():
        shutil.copy2(src, dst)
        print(f"迁移: {src} -> {dst}")

def migrate_data_patterns():
    """按表拆分 data-patterns.md"""
    src = Path('knowledge/data-patterns.md')
    if not src.exists():
        print("data-patterns.md 不存在，跳过")
        return
    
    content = src.read_text(encoding='utf-8')
    tables = split_by_table_header(content)
    
    for table_name, table_content in tables.items():
        db, table = parse_table_name(table_name)
        target_dir = Path(f'knowledge/table/{db}/{table}')
        target_dir.mkdir(parents=True, exist_ok=True)
        
        target_file = target_dir / 'data-patterns.md'
        target_file.write_text(table_content, encoding='utf-8')
        print(f"拆分: {table_name} -> {target_file}")

def migrate_verify_lessons():
    """按表拆分 verify-lessons.md，提取通用规则"""
    src = Path('knowledge/verify-lessons.md')
    if not src.exists():
        print("verify-lessons.md 不存在，跳过")
        return
    
    content = src.read_text(encoding='utf-8')
    
    # 提取通用规则（MySQL语法、NULL处理等）
    global_rules = extract_global_rules(content)
    global_file = Path('knowledge/global/verify-rules.md')
    global_file.write_text(global_rules, encoding='utf-8')
    print(f"提取通用规则 -> {global_file}")
    
    # 按表拆分
    tables = split_by_table_header(content)
    for table_name, table_content in tables.items():
        db, table = parse_table_name(table_name)
        target_dir = Path(f'knowledge/table/{db}/{table}')
        target_dir.mkdir(parents=True, exist_ok=True)
        
        target_file = target_dir / 'lessons.md'
        target_file.write_text(table_content, encoding='utf-8')
        print(f"拆分: {table_name} -> {target_file}")

def split_by_table_header(content):
    """
    按表名标题拆分内容
    匹配格式：## YYYY-MM-DD: {table_name} 验证
    """
    tables = {}
    current_table = None
    current_content = []
    
    for line in content.split('\n'):
        match = re.match(r'^## (\d{4}-\d{2}-\d{2}): (\S+) 验证', line)
        if match:
            if current_table:
                if current_table not in tables:
                    tables[current_table] = []
                tables[current_table].append('\n'.join(current_content))
            
            current_table = match.group(2)
            current_content = []
        else:
            current_content.append(line)
    
    if current_table:
        if current_table not in tables:
            tables[current_table] = []
        tables[current_table].append('\n'.join(current_content))
    
    # 合并同一表的多段内容
    return {k: '\n'.join(v) for k, v in tables.items()}

def parse_table_name(table_name):
    """
    解析表名，返回 (database, table)
    输入格式: database.table 或 database.table_name
    """
    parts = table_name.split('.', 1)
    if len(parts) == 2:
        return parts[0], parts[1]
    else:
        return 'unknown', table_name

def extract_global_rules(content):
    """
    从 verify-lessons.md 提取通用规则
    """
    rules = """# 验数通用规则

## 状态判定规则

| 检查项 | ❌ FAIL | ⚠️ WARN | ✅ PASS |
|--------|---------|---------|---------|
| 主键唯一性 | 重复 > 0 | - | 重复 = 0 |
| 维度空值占比 | - | > 5% | ≤ 5% |
| 指标空值零值占比 | - | > 30% | ≤ 30% |
| 字段比对差异 | diff_cnt > 0 | - | diff_cnt = 0 |
| 来源追溯匹配 | 匹配率 < 100% | - | 匹配率 = 100% |
| 筛选条件符合 | 不符合条件 > 0 | - | 不符合条件 = 0 |

**整体结论判定**：
- 存在任何 ❌ FAIL → 不通过 ❌
- 仅存在 ⚠️ WARN → 通过（附警告） ✅⚠️
- 全部 ✅ PASS → 通过 ✅

---

## NULL 处理规则

### 字段比对时的归一化模式

| 字段类型 | 处理方式 |
|----------|----------|
| varchar / char / string | NVL(CAST(NULLIF(field, '') AS STRING), 'XXT') |
| int / bigint | NVL(CAST(field AS STRING), 'XXT') |
| decimal / float / double | NVL(CAST(field AS STRING), 'XXT') |

### 哨兵值选择

- 使用 'XXT' 作为 NULL 的哨兵值
- 确保哨兵值不出现在业务数据中
- NULL 和空字符串统一归一化为哨兵值

---

## Hive 语法注意事项

### 1. NVL 函数
Hive 支持 NVL，统一用 NVL 做 NULL 归一化：
- Hive: NVL(field, 'default')

### 2. CAST 类型转换
Hive 使用 CAST(... AS STRING)（不要用 CAST(... AS CHAR)）

### 3. int/bigint 字段的 NULL 处理
- int/bigint/decimal/float: NVL(CAST(field AS STRING), 'XXT')（无需 NULLIF）
- varchar: NVL(CAST(NULLIF(field, '') AS STRING), 'XXT')

---

## JOIN 膨胀防护

当上游表可能有重复记录时，使用子查询去重：

```sql
LEFT JOIN (
  SELECT key_field, target_field, dt
  FROM upstream_table
  WHERE dt = '{partition}' AND {filter}
  GROUP BY key_field, target_field, dt
) src ON t.key = src.key_field AND t.dt = src.dt
```

---

## 验证范围控制

当用户要求"只验证新增记录"时，添加 NOT EXISTS 排除共同记录：

```sql
WHERE t.dt = '{partition}'
  AND NOT EXISTS (
    SELECT 1 FROM production_table p
    WHERE p.pk = t.pk AND p.dt = t.dt
  )
```
"""
    return rules

def create_index():
    """创建知识索引"""
    # 遍历所有表目录，生成索引
    index_content = """# 知识索引

- **最后更新**：自动生成

## 表列表

| 数据库 | 表名 | 包含文件 |
|--------|------|----------|
"""
    
    table_dir = Path('knowledge/table')
    if table_dir.exists():
        for db_dir in sorted(table_dir.iterdir()):
            if db_dir.is_dir():
                for table_dir in sorted(db_dir.iterdir()):
                    if table_dir.is_dir():
                        files = [f.name for f in table_dir.glob('*.md')]
                        index_content += f"| {db_dir.name} | {table_dir.name} | {', '.join(files)} |\n"
    
    Path('knowledge/index.md').write_text(index_content, encoding='utf-8')
    print("索引创建完成")

if __name__ == '__main__':
    migrate()
```

---

## 九、skill 主文件修改

### 9.1 修改初始化逻辑

在 `skill.md` 的初始化部分：

```markdown
## 初始化：读取知识沉淀

在开始验证前，先读取相关知识沉淀文件：

```bash
# 读取顺序
1. knowledge/global/verify-rules.md    # 全局验数规则（每次都加载）
2. knowledge/global/sql-patterns.md    # SQL语法模式（每次都加载）
3. knowledge/table/{database}.{table}/schema.md      # 当前表结构（如有）
4. knowledge/table/{database}.{table}/data-patterns.md # 当前表数据规律（如有）
5. knowledge/table/{database}.{table}/lessons.md       # 当前表踩坑记录（如有）
```

**加载策略**：
- 全局知识：每次都加载
- 表级知识：只加载当前验证的表
- 归档知识：不加载（需要时手动查询）
```

### 9.2 修改知识沉淀逻辑

在 `skill.md` 的 Step 8 部分：

```markdown
## Step 8: 知识沉淀

本次验证过程中发现的新知识，按以下规则写入：

### 写入位置

| 知识类型 | 写入位置 |
|----------|----------|
| SQL语法问题 | `knowledge/global/sql-patterns.md` |
| 通用验数规则 | `knowledge/global/verify-rules.md` |
| 表结构信息 | `knowledge/table/{db}.{table}/schema.md` |
| 数据规律 | `knowledge/table/{db}.{table}/data-patterns.md` |
| 踩坑记录 | `knowledge/table/{db}.{table}/lessons.md` |

### 写入规则

1. **先读取再写入**：写入前先读取现有内容
2. **去重检查**：检查新知识是否已存在
3. **按状态分类**：已解决/待解决/待验证
4. **追加而非覆盖**：新内容追加到文件末尾
5. **更新索引**：更新 `knowledge/index.md`
```

---

## 十、效果评估

### 10.1 性能对比

| 指标 | 当前方案 | 优化方案 | 提升 |
|------|----------|----------|------|
| 初始化读取量 | ~100KB + dataware_table | ~20KB | 5-10x |
| 写入时检查 | 无 | 去重检查 | 减少冗余 |
| 文件数量 | 分散在2个目录 | 统一在knowledge/ | 更易维护 |
| 归档机制 | 无 | 自动归档 | 控制增长 |
| 目录结构 | dataware_table + knowledge | 仅 knowledge | 更简洁 |

### 10.2 维护性对比

| 指标 | 当前方案 | 优化方案 |
|------|----------|----------|
| 按表查询 | 需要全文搜索 | 直接定位目录 |
| 清理过期知识 | 手动编辑 | 自动归档 |
| 新增表 | 混合在现有文件 | 独立目录 |
| 知识迁移 | 困难 | 简单（目录移动） |

### 10.3 存储增长预测

| 时间 | 当前方案 | 优化方案 |
|------|----------|----------|
| 1个月后 | ~300KB | ~50KB（活跃）+ ~250KB（归档） |
| 3个月后 | ~1MB | ~100KB（活跃）+ ~900KB（归档） |
| 1年后 | ~5MB | ~200KB（活跃）+ ~4.8MB（归档） |

---

## 十一、实施计划

### 阶段1：目录结构调整 + 迁移（1天）

- [ ] 创建新目录结构（global/, table/, archive/）
- [ ] 编写迁移脚本（migrate_knowledge.py）
- [ ] 执行迁移：
  - [ ] 迁移 dataware_table/ → knowledge/table/{db}.{table}/schema.md
  - [ ] 迁移 knowledge/sql-patterns.md → knowledge/global/
  - [ ] 拆分 knowledge/data-patterns.md → knowledge/table/
  - [ ] 拆分 knowledge/verify-lessons.md → knowledge/table/ + knowledge/global/
- [ ] 验证迁移结果
- [ ] 删除旧目录（dataware_table/、旧的knowledge文件）

### 阶段2：修改skill逻辑（2天）

- [ ] 修改初始化逻辑（读取 global/ + 当前表目录）
- [ ] 修改写入逻辑（加入去重检查）
- [ ] 修改归档逻辑
- [ ] 测试新流程

### 阶段3：索引和归档（1天）

- [ ] 实现索引机制（index.md）
- [ ] 实现归档脚本（archive_knowledge.py）
- [ ] 设置定时任务（可选）

### 阶段4：文档和培训（0.5天）

- [ ] 更新 README.md
- [ ] 更新 skill.md 中的路径引用
- [ ] 编写使用指南
- [ ] 通知团队成员

**总工期**：约 4.5 天

---

## 十二、风险和应对

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 迁移过程中数据丢失 | 知识丢失 | 迁移前备份整个目录，迁移后逐文件验证 |
| dataware_table 路径引用 | skill.md 中的路径失效 | 全局搜索 `dataware_table` 并替换 |
| 去重逻辑误判 | 丢失有价值知识 | 保留原始文件备份，支持回滚 |
| 归档过早 | 需要时找不到 | 归档前确认，支持恢复 |
| 目录结构变更 | 其他skill或脚本引用失效 | 全局搜索相关路径并更新 |

### 关键检查点

迁移完成后必须检查：
1. [ ] skill.md 中所有 `dataware_table` 引用已更新
2. [ ] skill.md 中所有 `knowledge/sql-patterns.md` 引用已更新
3. [ ] skill.md 中所有 `knowledge/data-patterns.md` 引用已更新
4. [ ] skill.md 中所有 `knowledge/verify-lessons.md` 引用已更新
5. [ ] 新的初始化逻辑能正确读取知识文件
6. [ ] 新的写入逻辑能正确写入知识文件

---

## 附录

### A. 完整目录结构示例（迁移后）

```
.claude/skills/atomic-data-verify/
├── skill.md
├── capabilities/
├── templates/
├── report/
│
└── knowledge/
    ├── README.md
    ├── index.md
    ├── optimization-design.md
    │
    ├── global/
    │   ├── sql-patterns.md          # 从 knowledge/ 迁移
    │   └── verify-rules.md          # 从 verify-lessons.md 提取
    │
    ├── table/
    │   ├── nike.kcode_crm_ks_dku/
    │   │   ├── schema.md            # 从 dataware_table/ 迁移
    │   │   ├── data-patterns.md     # 从 knowledge/ 拆分
    │   │   └── lessons.md           # 从 verify-lessons.md 拆分
    │   │
    │   ├── nike.kcode_crm_ks_dku_pro/
    │   │   ├── schema.md            # 从 dataware_table/ 迁移
    │   │   ├── data-patterns.md
    │   │   └── lessons.md
    │   │
    │   └── nike.audience_list/
    │       ├── schema.md
    │       ├── data-patterns.md
    │       └── lessons.md
    │
    └── archive/
        └── 2026-06/

# 已删除的目录
# ❌ dataware_table/
# ❌ knowledge/sql-patterns.md
# ❌ knowledge/data-patterns.md
# ❌ knowledge/verify-lessons.md
```

### B. 快速命令参考

```bash
# 查看某表的知识
cat knowledge/table/nike.kcode_crm_ks_dku/lessons.md

# 查看归档知识
ls knowledge/archive/

# 执行归档
python scripts/archive_knowledge.py

# 重建索引
python scripts/create_index.py

# 查看知识统计
python scripts/knowledge_stats.py
```
