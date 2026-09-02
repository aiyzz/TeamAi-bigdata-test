# kcode_crm_ks_dku_pro（生产表）

- **表名**：nike.kcode_crm_ks_dku_pro
- **表描述**：大客户业务量结果表-k码（生产环境基准表）

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
| first_tab_type | varchar(255) | 品牌：1;非品牌:2 | 维度（枚举） |
| customer_type | varchar(255) | 客户类型（模式-品牌） | 维度 |
| third_tab_type | varchar(255) | 含义乌商贸：1，不含义乌商贸：2 | 维度（枚举） |
| dt | varchar(255) | 分区字段 | 分区 |

## 分区信息

- **分区字段**：dt
- **分区格式**：yyyyMMdd

## 主键

- **主键**：kcode
