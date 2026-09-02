# 结构规范性检查清单

> 检查 JSON 配置文件的结构是否完整、必填字段是否存在

---

## 检查项

### 基础结构检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `meta_info` 存在 | ✅ | 配置元信息 |
| `meta_info.table_name` 存在 | ✅ | 格式：`库名.表名` |
| `meta_info.partition_field` 存在 | ✅ | 分区字段名，避免全表扫描 |
| `meta_info.mode` 存在 | ✅ | `single_table` 或 `double_table` |
| `dimension_definitions` 存在 | ✅ | 维度定义 |
| `dimension_definitions.org_hierarchy` 存在 | ✅ | 组织层级定义 |
| `dimension_definitions.org_hierarchy.order` 存在 | ✅ | 层级顺序，至少 2 个 |
| `dimension_definitions.org_hierarchy.level_field` 存在 | ✅ | 层级字段名（如 org_type） |
| `metric_definitions` 存在且非空 | ✅ | 指标定义列表 |
| `hierarchy_logic` 存在且非空 | ✅ | 层级验证逻辑 |
| `diff_threshold` 存在 | ⚠️ | 差异阈值，默认 0.0 |

### 双表模式额外检查（仅 mode=double_table）

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `meta_info.detail_table_name` 存在 | ✅ | 明细表名，格式：`库名.表名` |
| `detail_summary_mapping` 存在 | ✅ | 明细与汇总的映射关系 |
| `detail_summary_mapping.join_keys` 存在 | ✅ | JOIN 关联字段 |
| `detail_summary_mapping.metric_mapping` 存在 | ✅ | 指标映射关系 |
| `detail_summary_mapping.group_by_mapping` 存在 | ✅ | 分组字段映射 |

---

## 检查方法

1. 读取 JSON 配置文件
2. 逐项检查上述字段是否存在
3. 记录检查结果

---

## 输出格式

```
【结构规范性检查】

| 检查项 | 状态 | 说明 |
|--------|------|------|
| meta_info 存在 | ✅ PASS | - |
| meta_info.table_name 存在 | ✅ PASS | nike.app_direct_customer_operation_damage |
| meta_info.partition_field 存在 | ✅ PASS | dt |
| dimension_definitions 存在 | ✅ PASS | - |
| org_hierarchy.order 存在 | ✅ PASS | 7 个层级 |
| metric_definitions 存在 | ✅ PASS | 6 个指标 |
| hierarchy_logic 存在 | ✅ PASS | 6 条规则 |

统计：X 项通过 / Y 项警告 / Z 项失败
```

---

## 状态定义

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| ✅ PASS | 检查通过 | 继续 |
| ⚠️ WARN | 警告，非致命 | 可继续，但需关注 |
| ❌ FAIL | 失败，致命 | 必须修复后才能继续 |
