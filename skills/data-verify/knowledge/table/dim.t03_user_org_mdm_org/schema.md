# dim.t03_user_org_mdm_org

- **表名**：dim.t03_user_org_mdm_org
- **层级**：DIM
- **主键**：org_code
- **分区字段**：dt

## 字段列表

### 机构基本属性与层级

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| org_code | string | 网点编码 | 维度（主键） |
| org_name | string | 网点中文名称 | 维度 |
| short_name | string | 组织机构简称 | 维度 |
| english_name | string | 网点英文名称 | 维度 |
| org_type | string | 组织机构类型 | 维度 |
| sub_type | string | 子类型 | 维度 |
| levels | string | 组织机构等级 | 维度 |
| parent_id | string | 父组织机构编码 | 维度 |
| whole_org_id | string | 全路径组织机构标识 | 维度 |
| whole_org_name | string | 全路径组织机构名称 | 维度 |
| is_local | string | 是否本部 | 维度 |
| is_branch | string | 是否分公司 | 维度 |
| regular_chain | string | 是否直营 | 维度 |
| is_direct_center | string | 是否属直营中心 | 维度 |
| is_direct_branch | string | 是否直营分公司 | 维度 |
| operate_type | string | 企业经营形式 | 维度 |

### 管辖与行政归属

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| head_code | string | 总部代码 | 维度 |
| head_name | string | 总部名称 | 维度 |
| manage_area_code | string | 管区代码 | 维度 |
| manage_area_name | string | 管区名称 | 维度 |
| region_code | string | 省区代码 | 维度 |
| region_name | string | 省区名称 | 维度 |
| transfer_code | string | 转运中心代码 | 维度 |
| transfer_name | string | 转运中心名称 | 维度 |
| branch_code | string | 分公司代码 | 维度 |
| branch_name | string | 分公司名称 | 维度 |
| zone_code | string | 片区代码 | 维度 |
| zone_name | string | 片区名称 | 维度 |
| grid_code | string | 网格小区代码 | 维度 |
| grid_name | string | 网格小区名称 | 维度 |

### 财务、结算与预警

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| balance | double | 当前余额 | 指标 |
| credit_upper | double | 信用额度 | 指标 |
| settlement_center | string | 所属结算网点 | 维度 |
| settlement_org | string | 所属结算网点代码 | 维度 |
| can_agency_fund | string | 是否代收款 | 维度 |
| agency_fund_upper | double | 代收款上限 | 指标 |
| can_post_pay | string | 是否到付款 | 维度 |
| post_pay_upper | double | 到付款上限 | 指标 |
| first_alarm_amount | double | 一级预警金额 | 指标 |
| second_alarm_amount | double | 二级预警金额 | 指标 |
| balance_alarm_control | string | 是否启用余额控制 | 维度 |
| alarm_control | string | 是否启用预警 | 维度 |

### 联系方式与状态

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| address | string | 地址 | 维度 |
| postal_code | string | 邮编 | 维度 |
| manager_name | string | 经理姓名 | 维度 |
| manager_phone | string | 经理电话 | 维度 |
| other_contact_info | string | 其他联系方式 | 维度 |
| org_website | string | 网点网址 | 维度 |
| used | string | 是否启用 | 维度 |
| status | string | 数据状态 | 维度 |
| org_status | string | 机构状态 | 维度 |
| display | string | 是否显示 | 维度 |
| create_time | string | 创建时间 | 维度 |
| modify_time | string | 修改时间 | 维度 |

### ETL 元数据信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| etl_tx_dt | string | 数据时间 | 维度 |
| etl_modified_time | string | 数据记录更新时间 | 维度 |
| etl_extract_time | string | 数据抽取时间 | 维度 |
| etl_source_sys_cd | string | 源系统名称 | 维度 |
| etl_source_table | string | 源表名称 | 维度 |
| etl_job_name | string | 调度任务名称 | 维度 |

## 组织层级类型

| org_type | 含义 | 取值字段 |
|----------|------|----------|
| REGION_MANAGE | 省区 | region_name |
| BRANCH | 分公司 | branch_name |
| TRANSFER_CENTER | 中心 | transfer_name |
| SUB_DEPARTMENT | 分部 | org_name |
| GRID | 片区 | org_name |

## 常见筛选场景

| 场景 | 筛选条件 |
|------|----------|
| 按省区统计 | org_type = 'REGION_MANAGE' |
| 按中心统计 | org_type = 'TRANSFER_CENTER' |
| 按分公司统计 | org_type = 'BRANCH' |
| 按分部统计 | org_type = 'SUB_DEPARTMENT' |
| 按片区统计 | org_type = 'GRID' |

## 组织层级关系

总部 → 管区 → 省区 → 转运中心  → 城市片区（小区） → 分公司

## 被关联关系

| 明细表 | 关联键 | 取值字段 | 用途 |
|--------|--------|----------|------|
| dwd.operate_waybill_record_dd | org_code | org_name, branch_name, region_name, transfer_name | 获取操作网点组织架构 |
| dwd.operate_waybill_record_dd | source_org_code | org_name | 获取始发网点名称 |
| dwd.operate_waybill_record_dd | des_org_code | org_name | 获取目的网点名称 |
| dwd.operate_pkg_record_dd | org_code | org_name, branch_name, region_name, transfer_name | 获取包操作网点信息 |
| dwd.operate_pkg_record_dd | source_org_code | org_name | 获取始发网点名称 |
| dwd.operate_pkg_record_dd | des_org_code | org_name | 获取目的网点名称 |
| dwd.waybill_take_waybill_info_dd | source_org_code | org_name, branch_name, region_name, transfer_name | 获取揽收网点组织架构 |
| dwd.waybill_take_waybill_info_dd | end_org_code | org_name | 获取目的网点名称 |
| dwd.waybill_sign_waybill_info_dd | source_org_code | org_name, branch_name, region_name, transfer_name | 获取揽收网点组织架构 |
| dwd.waybill_sign_waybill_info_dd | end_org_code | org_name | 获取目的网点名称 |
| dwd.waybill_record_return_dd | org_code | org_name, branch_name, region_name, transfer_name | 获取操作网点组织架构 |
| dwd.waybill_record_return_dd | source_org_code | org_name | 获取始发网点名称 |
| dwd.waybill_record_return_dd | des_org_code | org_name | 获取目的网点名称 |
