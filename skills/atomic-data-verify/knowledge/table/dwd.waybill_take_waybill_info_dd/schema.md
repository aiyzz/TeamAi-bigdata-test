# dwd.waybill_take_waybill_info_dd

- **表名**：dwd.waybill_take_waybill_info_dd
- **层级**：DWD
- **主键**：waybill_no
- **分区字段**：dt
- **数据来源**：D:\yto\wiki\dataware\tables\dwd.waybill_take_waybill_info_dd.md

## 字段列表

### 运单与订单基础属性

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| waybill_no | string | 运单号码 | 维度（主键） |
| order_logistics_code | string | 订单编号 | 维度 |
| face_type | string | 面单类型 | 维度 |
| exp_type | string | 实物类型 | 维度 |
| return_waybill_no | string | 回单号码 | 维度 |
| datoubi | string | 三段码 | 维度 |
| business_id | string | 商家id | 维度 |
| get_waybill_time | string | 拉单时间 | 维度 |
| is_scatter | string | 是否散单 | 维度 |
| is_city_waybill | string | 是否同城件 | 维度 |
| platform_vip | string | 平台VIP | 维度 |
| is_vip | string | 是否vip标识 | 维度 |

### 包裹重量与尺寸信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| weigh_weight | double | 称入重量 | 指标 |
| input_weight | string | 输入重量 | 指标 |
| pkg_length | double | 长 | 指标 |
| pkg_width | double | 宽 | 指标 |
| pkg_height | double | 高 | 指标 |
| volume_weight | double | 体积重 | 指标 |

### 寄件人与收件人信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| sender_name | string | 寄件人姓名 | 维度 |
| receiver_name | string | 收件人姓名 | 维度 |
| sender_mobile_phone | string | 寄件人联系手机 | 维度 |
| receiver_mobile_phone | string | 收件人联系手机 | 维度 |
| sender_tel | string | 寄件人固定电话 | 维度 |
| receiver_tel | string | 收件人固定电话 | 维度 |
| send_detail_address | string | 寄件地址附加 | 维度 |
| receiver_app | string | 收件地址附加 | 维度 |
| send_province_code | string | 寄件地址省份 | 维度 |
| receiver_province_code | string | 收件地址省份 | 维度 |

### 揽收环节信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| pick_up_time | string | 取件时间 | 维度 |
| taking_upload_time | string | 揽收上传时间 | 维度 |
| pick_emp_name | string | 取件人姓名 | 维度 |
| taking_emp_name | string | 揽收收派员姓名 | 维度 |
| source_org_code | string | 揽收网点 | 维度（关联键） |
| taking_op_code | string | 揽收操作码 | 维度 |
| customer_code | string | 客户编号 | 维度 |
| customer_name | string | 客户名称 | 维度 |
| create_time | string | 取件揽收最早时间 | 维度 |
| take_modify_user_name | string | 揽收修改人名称 | 维度 |

### 派件与签收环节信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| handon_emp_name | string | 派件收派员姓名 | 维度 |
| signature_reciever_signoff | string | 签收人 | 维度 |
| handon_upload_time | string | 派件上传时间 | 维度 |
| signature_upload_time | string | 签收上传时间 | 维度 |
| signature_signoff_type_code | string | 签收类型 | 维度 |
| signature_op_code | string | 签收操作码 | 维度 |
| stage_emp_name | string | 驿站签收收派员姓名 | 维度 |
| stage_signoff_type_code | string | 驿站签收类型 | 维度 |
| stage_upload_time | string | 驿站签收上传时间 | 维度 |
| stage_op_code | string | 驿站签收操作码 | 维度 |
| end_org_code | string | 目的网点 | 维度 |
| signature_delivery_fail_reason | string | 派送失败原因描述 | 维度 |

### 特殊标记与业务标签

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| is_yzd | string | 是否圆准达 | 维度 |
| is_cod | string | 是否COD | 维度 |
| is_hk | string | 是否航空 | 维度 |
| waybill_flag | string | 时效件标记 | 维度 |
| is_return | string | 是否退回 | 维度 |
| is_issue | string | 是否问题件 | 维度 |
| remark1 | string | 面单隐私类型 | 维度 |
| order_channel_code | string | 渠道代码 | 维度 |

### ETL 元数据信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| etl_tx_dt | string | 数据时间 | 维度 |
| etl_modified_time | string | 数据记录更新时间 | 维度 |
| etl_extract_time | string | 数据抽取时间 | 维度 |
| etl_source_sys_cd | string | 源系统名称 | 维度 |
| etl_source_table | string | 源表名称 | 维度 |
| etl_job_name | string | 调度任务名称 | 维度 |

## 关联维表

| 维表 | 关联键（本表） | 关联键（维表） | 取值字段 | 用途 |
|------|----------------|----------------|----------|------|
| dim.t03_user_org_mdm_org | source_org_code | org_code | org_name, branch_name, region_name, transfer_name | 获取揽收网点组织架构 |
| dim.t03_user_org_mdm_org | end_org_code | org_code | org_name | 获取目的网点名称 |

## 业务说明

- 本表为揽收口径运单信息表，已揽收的运单才会出现在此表
- 无需通过 op_code 维表筛选，本表本身就是揽收场景
