# kcode_crm_ks_dku

- **表名**：nike.kcode_crm_ks_dku
- **迁移来源**：dataware_table/nike.kcode_crm_ks_dku.md
- **最后更新**：迁移自动生成

# kcode_crm_ks_dku

- **表名**：nike.kcode_crm_ks_dku
- **表描述**：大客户业务量结果表-k码测试表

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

## ETL 逻辑确认

### 源表信息

| 源表 | 关联键 | 筛选条件 |
|------|--------|----------|
| nike.ods_jsc_t_market_direct_customer_dd | kcode_crm_ks_dku.kcode = ods_jsc_t_market_direct_customer_dd.k_code | settle_code LIKE 'ZK%' AND status = '1' AND up_time <= '{dt}' AND expire_time >= '{dt}' |

### 字段映射

| 源字段 | 目标字段 | 转换类型 | 转换逻辑 |
|--------|----------|----------|----------|
| k_code | kcode | 直接映射 | - |
| k_name | kname | 直接映射 | - |
| sales_emp_code | sale_emp_code | 直接映射 | - |
| sales_emp_name | sale_emp_name | 直接映射 | - |
| customer_classify | first_tab_type | 条件映射 | CASE WHEN customer_classify='BRAND' THEN '1' ELSE '2' END |
