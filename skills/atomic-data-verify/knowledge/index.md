# 知识索引

- **最后更新**：2026-06-21

## 表列表

### DWD 明细表（基准表）

| 数据库 | 表名 | 层级 | 包含文件 | 业务含义 |
|--------|------|------|----------|----------|
| dwd | operate_waybill_record_dd | DWD | schema.md | 运单操作明细（拆包后票件） |
| dwd | operate_pkg_record_dd | DWD | schema.md | 包操作明细 |
| dwd | waybill_take_waybill_info_dd | DWD | schema.md | 揽收口径运单信息 |
| dwd | waybill_sign_waybill_info_dd | DWD | schema.md | 签收口径运单信息 |
| dwd | waybill_sign_waybill_track_dd | DWD | schema.md | 运单轨迹（内部） |
| dwd | waybill_sign_waybill_external_track_dd | DWD | schema.md | 运单轨迹（外部） |
| dwd | waybill_record_return_dd | DWD | schema.md | 退回件去重表 |

### DIM 维度表

| 数据库 | 表名 | 层级 | 包含文件 | 业务含义 |
|--------|------|------|----------|----------|
| dim | mdm_opcode_info_a | DIM | schema.md | 操作码字典（约390条） |
| dim | t03_user_org_mdm_org | DIM | schema.md | 组织机构（140+字段） |

### 历史表

| 数据库 | 表名 | 包含文件 |
|--------|------|----------|
| nike | audience_list | lessons.md, schema.md |
| nike | kcode_crm_ks_dku | lessons.md, schema.md |
| nike | kcode_crm_ks_dku_pro | schema.md |
| nike | ods_jsc_t_market_direct_customer_dd | schema.md |
