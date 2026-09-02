# audience_list

- **表名**：nike.audience_list
- **迁移来源**：dataware_table/nike.audience_list.md
- **最后更新**：迁移自动生成

# audience_list

- **表名**：nike.audience_list
- **表描述**：人群列表表

## 字段列表

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| id | int | 人群ID | 维度（复合主键） |
| name | varchar(255) | 人群名称 | 维度（复合主键） |
| creator_id | int | 创建者ID | 维度 |
| status | int | 状态 | 维度（枚举） |
| created_time | bigint | 创建时间 | 维度 |
| is_sharing | int | 是否共享 | 维度（枚举） |
| audience_id | bigint | 受众ID | 维度 |
| creator_name | varchar(50) | 创建者名称 | 维度 |
| appid | int | 应用ID | 维度 |

## 分区信息

- **分区字段**：无

## 主键

- **复合主键**：id + name

## 枚举值映射

| 字段 | 值 | 业务含义 |
|------|-----|----------|
| status | 1 | 有效 |
| is_sharing | 0 | 不共享 |
| is_sharing | 1 | 共享 |
