# 数据类型一致性检查清单

> 检查指标的数据类型是否合理、阈值设置是否正确

---

## 检查项

### 指标类型检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| DERIVED 指标有计算公式 | ✅ | 派生指标必须有 formula 字段 |
| 指标 data_type 为数值类型 | ⚠️ | 应为 decimal/float/int/bigint |
| string 类型指标警告 | ⚠️ | 建议转换为数值类型 |

### 阈值检查

| 检查项 | 必填 | 说明 |
|--------|------|------|
| `diff_threshold` 存在 | ⚠️ | 差异阈值 |
| `diff_threshold` 为非负数 | ✅ | 必须 >= 0 |

---

## 检查方法

### 1. DERIVED 指标公式检查

```
对于每个 DERIVED 指标：
  如果 base_aggregation == "DERIVED"：
    检查 formula 字段是否存在
    不存在 → WARN
```

### 2. 数据类型检查

```
对于每个指标：
  如果 data_type == "string"：
    → WARN（建议转换为数值类型）
  如果 data_type in ["decimal", "float", "int", "bigint"]：
    → PASS
```

### 3. 阈值检查

```
检查 diff_threshold：
  如果不存在 → WARN（将使用默认值 0.0）
  如果存在但 < 0 → FAIL
  如果存在且 >= 0 → PASS
```

---

## 输出格式

```
【数据类型一致性检查】

| 检查项 | 状态 | 说明 |
|--------|------|------|
| DERIVED rate 有公式 | ✅ PASS | son_num / mother_num * 100000 |
| 指标 son_num 类型为 decimal | ✅ PASS | - |
| 指标 mother_num 类型为 decimal | ✅ PASS | - |
| diff_threshold = 0.0 | ✅ PASS | - |

统计：X 项通过 / Y 项警告 / Z 项失败
```

---

## 状态定义

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| ✅ PASS | 检查通过 | 继续 |
| ⚠️ WARN | 警告，非致命 | 可继续，但需关注 |
| ❌ FAIL | 失败，致命 | 必须修复后才能继续 |
