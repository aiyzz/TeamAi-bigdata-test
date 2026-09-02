# dwd.waybill_sign_waybill_external_track_dd

- **表名**：dwd.waybill_sign_waybill_external_track_dd
- **层级**：DWD
- **主键**：waybill_no
- **分区字段**：dt
- **数据来源**：D:\yto\wiki\dataware\tables\dwd.waybill_sign_waybill_external_track_dd.md

## 字段列表

### 订单与揽收基础信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| waybill_no | string | 单号 | 维度（主键） |
| order_logistics_code | string | 订单编号 | 维度 |
| customer_name | string | 客户名称 | 维度 |
| seller_name | string | 店铺名称 | 维度 |
| order_channel_code | string | 渠道编码 | 维度 |
| order_channel_name | string | 渠道类型 | 维度 |
| order_create_time | string | 订单时间 | 维度 |
| mat_create_time | string | 拉单时间 | 维度 |
| subscribe_create_time | string | 订阅时间 | 维度 |
| take_earlist_time | string | 最早揽收时间 | 维度 |
| pick_up_time | string | 取件时间 | 维度 |
| take_time | string | 揽收时间 | 维度 |
| take_org_name | string | 揽收网点名称 | 维度 |
| take_weigh_weight | string | 揽收重量 | 指标 |

### 始发端流转详情

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| start_branch_code1 | string | 始发第一个分公司 | 维度 |
| start_depart_time1_bra | string | 始发第一个分公司发车时间 | 维度 |
| start_center_code1 | string | 经转顺序第一个中心 | 维度 |
| start_arrive_time1 | string | 经转顺序第一个中心到车时间 | 维度 |
| start_down_time1 | string | 经转顺序第一个中心下车时间 | 维度 |
| start_upcar_time1 | string | 经转顺序第一个中心上车时间 | 维度 |
| start_depart_time1 | string | 经转顺序第一个中心发车时间 | 维度 |
| tran_num | string | 经过中心个数 | 指标 |
| org_num | string | 经过网点个数 | 指标 |

### 末端派送与签收详情

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| end_center_code1 | string | 经转倒序第一个中心 | 维度 |
| end_arrive_time1 | string | 经转倒序第一个中心到车时间 | 维度 |
| end_down_time1 | string | 经转倒序第一个中心下车时间 | 维度 |
| end_depart_time1 | string | 经转倒序第一个中心发车时间 | 维度 |
| handon_time | string | 派件时间 | 维度 |
| handon_emp_name | string | 小件员名称 | 维度 |
| stage_org_code | string | 入库网点 | 维度 |
| stage_create_time | string | 入库时间 | 维度 |
| sign_time | string | 签收网点 | 维度 |
| sign_earliest_time | string | 签收最早时间 | 维度 |

### 全链路时效指标

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| out_tak_dura | string | 订单揽收时长 | 指标 |
| out_takcent_dura | string | 揽收-中心时长 | 指标 |
| out_in_dura | string | 出港时长 | 指标 |
| in_cent_dura | string | 中心-派件时长 | 指标 |
| in_disp_dura | string | 派件-签收时长 | 指标 |
| is_scatter | string | 是否散单 | 维度 |

### 业务标签与ETL元数据

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| is_yzd | string | 是否圆准达 | 维度 |
| is_cod | string | 是否cod | 维度 |
| is_hk | string | 是否航空 | 维度 |
| waybill_flag | string | 运单标记 | 维度 |
| is_return | string | 是否退回 | 维度 |
| is_issue | string | 是否问题件 | 维度 |
| bak_1~bak_5 | string | 备用字段 | 维度 |
| etl_extract_time | string | 数据加工时间 | 维度 |

## 业务说明

- 本表为外部轨迹表（签收口径），面向快递客户查看运单轨迹
- 数据来源：外部平台（PDD、京东、抖音、快手）
