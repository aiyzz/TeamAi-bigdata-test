# ods_jsc_t_market_direct_customer_dd（新增来源表）

- **表名**：nike.ods_jsc_t_market_direct_customer_dd
- **表描述**：直营市场客户信息(新表) — 直客名单数据来源

## 字段列表

| 字段名 | 类型 | 注释 | 分类 |
|--------|------|------|------|
| id | varchar(255) | 主键ID | 主键 |
| market_settle_id | varchar(255) | 直营市场客户结算编码ID | 维度 |
| k_code | varchar(255) | 客户编码 | 维度 |
| k_name | varchar(255) | 客户名称 | 维度 |
| major_contract_name | varchar(255) | 合同主体名称 | 维度 |
| org_code | varchar(255) | 客户所属网点编码 | 维度 |
| org_name | varchar(255) | 客户所属网点名称 | 维度 |
| settle_type | varchar(255) | 客户结算模式 A模式 B模式 | 维度 |
| settle_org_code | varchar(255) | 结算网点代码 | 维度 |
| settle_org_name | varchar(255) | 结算网点名称 | 维度 |
| customer_classify | varchar(255) | 客户分类 BRAND 品牌客户 NONBRAND 非品牌客户 | 维度（枚举） |
| operate_org_type | varchar(255) | 代操作公司类型(1-全网 2-特定一个网点) | 维度 |
| operate_org_code | varchar(255) | 代操作分公司编码 | 维度 |
| operate_org_name | varchar(255) | 代操作分公司名称 | 维度 |
| billing_node | varchar(255) | 运费计费节点 SIGN-签收 COLLECT-揽收 CENTER_COLLECT-中心下车 | 维度 |
| settle_cost | varchar(255) | 结算费用 DELIVERY_COST-快递费 DELIVERY_OP_COST-快递费和操作费 | 维度 |
| material_billing | varchar(255) | 物料发放计费 NEED_PAY:计费 DO_NOT_PAY-不计费 | 维度 |
| weight_type | varchar(255) | 重量取值模式 TRANSFER/COLLECT_WEIGHT/CENTER | 维度 |
| package_back | varchar(255) | 退回件 NEED_PAY:计费 DO_NOT_PAY-不计费 | 维度 |
| up_time | varchar(255) | 启用时间 | 维度 |
| expire_time | varchar(255) | 到期时间 | 维度 |
| settle_interval | varchar(255) | 结算周期 DAYS/MONTHS/WEEKS/HALF_MONTHS | 维度 |
| paper_ratio | varchar(255) | 热敏纸配比 1:1 1:0 1:N | 维度 |
| sales_emp_code | varchar(255) | 销售员工号 | 维度 |
| sales_emp_name | varchar(255) | 销售员名称 | 维度 |
| has_sales_emp | varchar(255) | 是否有销售员 | 维度 |
| settle_code | varchar(255) | 结算编码 | 维度（关键筛选字段） |
| settle_name | varchar(255) | 结算名称 | 维度 |
| file_paths | text | 附件路径 json 字符串 | 其他 |
| is_deleted | varchar(255) | 是否删除 0-正常 1-删除 | 维度 |
| create_at | varchar(255) | 创建时间 | 其他 |
| create_by | varchar(255) | 创建人 | 其他 |
| create_by_name | varchar(255) | 创建人名称 | 其他 |
| update_at | varchar(255) | 修改时间 | 其他 |
| update_by | varchar(255) | 修改人 | 其他 |
| update_by_name | varchar(255) | 最后操作人名称 | 其他 |
| push_status | varchar(255) | 推送客商状态 0-未推送 1-推送 | 维度 |
| push_time | varchar(255) | 推送客商时间 | 其他 |
| synch_log | varchar(255) | 同步客商系统标记 初始0 同步一次+1 | 其他 |
| status | varchar(255) | 审核状态 0 待审核 1 审核通过 2 驳回 3作废 | 维度（枚举，关键筛选字段） |
| status_cause | varchar(255) | 审核原因 | 其他 |
| approver | varchar(255) | 审批人 | 其他 |
| approver_date | varchar(255) | 审批时间 | 其他 |
| is_company | varchar(255) | true:机构客户 false:非机构客户 | 维度 |
| approver_tmp | varchar(255) | OA审批人,中间状态 | 其他 |
| market_mdm_id | varchar(255) | 主数据历史数据id | 其他 |
| check_update_time | varchar(255) | 修改社会统一信用代码等时间 | 其他 |
| source | varchar(255) | 数据来源(web-页面新建) | 维度 |
| dt | varchar(255) | HIVE分区 | 分区 |

## 分区信息

- **分区字段**：dt
- **分区格式**：yyyyMMdd

## 筛选逻辑（基于需求）

新增到直客名单的筛选条件：
1. `settle_code LIKE 'ZK%'` — 结算编码以 ZK 开头
2. `status = '1'` — 审核通过
3. `up_time <= 当前日期 AND expire_time >= 当前日期` — 在有效期内
4. `is_deleted = '0'` — 未删除

筛选结果标记为「总对总」模式（k_type 对应值需确认）
