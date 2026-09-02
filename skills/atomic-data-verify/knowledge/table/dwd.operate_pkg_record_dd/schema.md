# dwd.operate_pkg_record_dd

- **表名**：dwd.operate_pkg_record_dd
- **层级**：DWD
- **主键**：pkg_no + create_time + org_code
- **分区字段**：dt, op_code

## 字段列表

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| pkg_no | string | 包签号 | 维度（主键） |
| create_time | string | 创建时间 | 维度（主键） |
| org_code | string | 操作网点编码 | 维度（主键/关联键） |
| org_type | string | 操作网点类型 | 维度 |
| product_type | string | 产品类型 | 维度 |
| weigh_weight | double | 称入重量 | 指标 |
| input_weight | string | 输入重量 | 指标 |
| volume_weight | double | 体积重 | 指标 |
| cmp_flag | string | 计泡标志位 | 维度 |
| pkg_length | double | 长 | 指标 |
| pkg_width | double | 宽 | 指标 |
| pkg_height | double | 高 | 指标 |
| pack_type | string | 建包类型 | 维度 |
| source_org_code | string | 始发网点 | 维度 |
| des_org_code | string | 目的网点 | 维度 |
| previous_org_code | string | 上一个网点 | 维度 |
| next_org_code | string | 下一个网点 | 维度 |
| container_no | string | 容器条码 | 维度 |
| truck_no | string | 车签条码 | 维度 |
| eco_bag | string | 环保袋芯号 | 维度 |
| aux_route_code | string | 辅助路由操作码 | 维度 |
| first_code | string | 建包一段码 | 维度 |
| transfer_type | string | 运输类型 | 维度 |
| upload_time | string | 上传时间 | 维度 |
| create_user_name | string | 创建人 | 维度 |
| emp_name | string | 业务员 | 维度 |
| create_terminal | string | 创建终端 | 维度 |
| device_type | string | 操作设备类型 | 维度 |
| io_type | string | 收入发出类型 | 维度 |
| bill_source_org_code | string | 面单发放地 | 维度 |
| etl_extract_time | string | 数据抽取时间 | 维度 |

## 关联维表

| 维表 | 关联键（本表） | 关联键（维表） | 取值字段 | 用途 |
|------|----------------|----------------|----------|------|
| dim.mdm_opcode_info_a | op_code | op_code | oper_type | 筛选业务类型/获取操作名称 |
| dim.t03_user_org_mdm_org | org_code | org_code | org_name, branch_name, region_name, transfer_name | 获取操作网点组织架构 |
| dim.t03_user_org_mdm_org | source_org_code | org_code | org_name | 获取始发网点名称 |
| dim.t03_user_org_mdm_org | des_org_code | org_code | org_name | 获取目的网点名称 |

## 常见筛选场景

| 场景 | 筛选条件 |
|------|----------|
| 建包记录 | op_code IN ('110','113') |
| 拆包记录 | op_code IN ('181','180') |
| 转运中心操作 | org_type = 'TRANSFER_CENTER' |
