# dwd.waybill_record_return_dd

- **表名**：dwd.waybill_record_return_dd
- **层级**：DWD
- **主键**：waybill_no
- **分区字段**：dt
- **数据来源**：D:\yto\wiki\dataware\tables\dwd.waybill_record_return_dd.md

## 字段列表

### 运单与包裹基础属性

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| waybill_no | string | 运单号 | 维度（主键） |
| exp_type | string | 实物类型 | 维度 |
| pkg_qty | string | 数量 | 指标 |
| express_content_code | string | 快件内容 | 维度 |
| weigh_weight | double | 最大重量 | 指标 |
| input_weight | string | 输入重量 | 指标 |
| pkg_length | double | 长 | 指标 |
| pkg_width | double | 宽 | 指标 |
| pkg_height | double | 高 | 指标 |
| volume_weight | double | 体积重 | 指标 |
| fee_weight | double | 计费重量 | 指标 |
| three_code | string | 三段码 | 维度 |

### 路由与网点流转信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| source_org_code | string | 始发网点 | 维度（关联键） |
| des_org_code | string | 目的网点 | 维度 |
| org_code | string | 操作网点编码 | 维度（关联键） |
| previous_org_code | string | 上一个网点 | 维度 |
| next_org_code | string | 下一个网点 | 维度 |
| container_no | string | 容器条码 | 维度 |
| line_no | string | 线路编号 | 维度 |
| frequency_no | string | 频次编号 | 维度 |
| vehicle_plate_no | string | 车牌号 | 维度 |
| route_code | string | 路由检查代码 | 维度 |
| aux_route_code | string | 辅助路由操作码 | 维度 |
| io_type | string | 收入发出类型 | 维度 |

### 费用与客户信息

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| fee_flag | string | 计费标识 | 维度 |
| fee_amt | double | 费用 | 指标 |
| trans_fee | double | 中转费 | 指标 |
| customer_code | string | 客户编码 | 维度 |
| customer_name | string | 客户名称 | 维度 |
| seller_id | string | 商家编码 | 维度 |
| sender | string | 发件人 | 维度 |
| sender_address | string | 发件地址 | 维度 |

### 状态、时效与业务标签

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| status | string | 状态 | 维度 |
| transfer_status | string | 转换状态 | 维度 |
| trace_status | string | 轨迹转换状态 | 维度 |
| effective_type_code | string | 时效 | 维度 |
| transport_type_code | string | 传输方式 | 维度 |
| cmp_flag | string | 计泡标志位 | 维度 |
| is_vip | string | 是否vip标识 | 维度 |
| accurate_arrival | string | 是否圆准达 | 维度 |
| secret_type | string | 隐私面单/业务类型 | 维度 |
| sub_secret_type | string | 隐私面单子类型 | 维度 |
| remark1 | string | 换单退回单号 | 维度 |
| in_out_flag | string | 进出标识 | 维度 |

### 操作人员与ETL元数据

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| create_time | string | 创建时间 | 维度 |
| upload_time | string | 上传时间 | 维度 |
| create_user_name | string | 创建人 | 维度 |
| modify_user_name | string | 修改人名称 | 维度 |
| device_type | string | 操作设备类型 | 维度 |
| op_code | string | 操作码 | 维度（关联键） |
| etl_extract_time | string | 数据处理时间 | 维度 |
| ref_id | string | 关联ID | 维度 |

## 关联维表

| 维表 | 关联键（本表） | 关联键（维表） | 取值字段 | 用途 |
|------|----------------|----------------|----------|------|
| dim.mdm_opcode_info_a | op_code | op_code | oper_type | 获取操作类型名称 |
| dim.t03_user_org_mdm_org | org_code | org_code | org_name, branch_name, region_name, transfer_name | 获取操作网点组织架构 |
| dim.t03_user_org_mdm_org | source_org_code | org_code | org_name | 获取始发网点名称 |
| dim.t03_user_org_mdm_org | des_org_code | org_code | org_name | 获取目的网点名称 |

## 业务说明

- 本表为退回件去表，33天去重后的退回件记录
- 用于逆向物流分析、异常件监控
