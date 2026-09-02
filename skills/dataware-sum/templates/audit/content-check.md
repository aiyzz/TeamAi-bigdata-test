# 内容正确性检查清单

> 检查 JSON 配置文件的内容是否正确、逻辑是否一致

---

## 检查项

### 指标定义检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `metric_definitions.code` 唯一性 | ✅ | 无重复的指标编码 |
| DERIVED 指标有 `formula` 字段 | ✅ | 派生指标必须有计算公式 |
| DERIVED 公式变量引用正确 | ✅ | 公式中引用的变量都在 metric_definitions 中定义 |
| DERIVED 公式无循环引用 | ✅ | 指标之间不能互相引用形成环 |

### 层级逻辑检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `hierarchy_logic.target_level` 在 order 中 | ✅ | 目标层级必须在 org_hierarchy.order 中 |
| `hierarchy_logic.org_levels` 在 order 中 | ✅ | 子级层级必须在 org_hierarchy.order 中 |
| ROLLUP_SUM 层级顺序正确 | ✅ | 父级在 order 中的索引 < 子级的索引 |
| `group_by_fields` 非空 | ✅ | 分组字段不能为空 |

### 维度字段一致性检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `group_by_fields` 字段值一致 | ⚠️ | 字段在父子层级的值应一致（如 brand_name） |
| 时间粒度枚举值有效 | ⚠️ | 应包含 D/M 或 日/月 |

### 双表模式额外检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `metric_mapping.summary_field` 存在 | ✅ | 必须在 metric_definitions 中存在 |
| `metric_mapping.detail_aggregation` 存在 | ✅ | 必须有聚合表达式 |
| `join_keys` 与 `group_by_mapping` 对齐 | ⚠️ | join_keys 应出现在 group_by_mapping 中 |
| 包含 `COMPARE_DETAIL_SUMMARY` 条目 | ⚠️ | 双表模式应有明细与汇总的对比逻辑 |

---

## 检查方法

### 1. 指标编码唯一性

```
提取所有 metric_definitions.code
检查是否有重复
重复 → FAIL
```

### 2. DERIVED 公式变量引用

```
对于每个 DERIVED 指标：
  提取公式中的变量名（正则：[a-zA-Z_][a-zA-Z0-9_]*）
  检查变量是否在 metric_definitions.code 中
  未定义的变量 → FAIL
```

### 3. DERIVED 公式循环引用

```
构建指标依赖图：
  DERIVED 指标 A 依赖 B → 添加边 A→B

检测是否有环：
  使用 DFS 或拓扑排序
  有环 → FAIL
```

### 4. ROLLUP_SUM 层级顺序

```
获取 org_hierarchy.order 列表（从高到低）

对于每个 ROLLUP_SUM 条目：
  target_index = order.index(target_level)
  source_index = order.index(org_levels[0])
  
  如果 target_index >= source_index：
    → FAIL（父级应排在子级前面，索引应更小）
```

### 5. group_by_fields 字段一致性

```
对于 group_by_fields 中的字段：
  查询父子层级的字段值
  如果值不一致（如父级=''，子级='非品牌'）：
    → WARN（建议从 group_by_fields 中排除）
```

---

## 输出格式

```
【内容正确性检查】

| 检查项 | 状态 | 说明 |
|--------|------|------|
| metric_definitions code 唯一 | ✅ PASS | 6 个指标无重复 |
| DERIVED rate 公式变量正确 | ✅ PASS | son_num, mother_num 已定义 |
| DERIVED rate 无循环引用 | ✅ PASS | - |
| ROLLUP_SUM: HEAD > REGION_MANAGE | ✅ PASS | index 0 < 1 |
| ROLLUP_SUM: REGION_MANAGE > TRANSFER_CENTER | ✅ PASS | index 1 < 2 |
| group_by_fields 包含 brand_name | ⚠️ WARN | 不同层级值可能不一致 |

统计：X 项通过 / Y 项警告 / Z 项失败
```

---

## 常见问题

### 问题 1: DERIVED 公式变量未定义

**现象**：`公式引用了未定义的变量: xxx`

**原因**：公式中使用了 `metric_definitions` 中不存在的指标编码

**修复**：检查公式中的变量名是否与 `metric_definitions.code` 一致

---

### 问题 2: ROLLUP_SUM 层级顺序错误

**现象**：`ROLLUP_SUM: target 'BRANCH' (index=4) 应排在 source 'CUSTOMER' (index=5) 前面`

**原因**：`org_hierarchy.order` 的顺序是从高到低，父级索引应小于子级

**修复**：检查 `org_hierarchy.order` 的顺序是否正确

---

### 问题 3: group_by_fields 字段值不一致

**现象**：`group_by_fields 中的 brand_name 在父子层级值不一致`

**原因**：BRANCH 层级 brand_name=''，CUSTOMER 层级 brand_name='非品牌'

**修复**：从 `group_by_fields` 中排除不一致的字段，或修复数据源
