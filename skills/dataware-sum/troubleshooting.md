## 异常与边界条件处理

### 常见问题速查

| 问题 | 症状 | 解决方案 |
|------|------|---------|
| DDL 获取失败 | 连接超时或表不存在 | 手动粘贴 DDL 语句 |
| JSON 审核 FAIL | 审核工具返回 exit code 1 | 根据报告修复错误后重新审核 |
| SQL 生成后结果为空 | 测试 SQL 生成但查询无数据 | 1. 检查分区范围  2. 确认 join_keys  3. 降低 threshold |
| JOIN 返回笛卡尔积 | 双表验证结果数量异常大 | 检查 join_keys 是否包含足够的唯一性字段 |
| 权限错误 | 无法创建输出目录 | 确保有写权限，或修改输出路径 |

### Step 0 模式判断失败

AI 无法自动判断单表/双表模式时，询问用户：

```
检测到您提供了一张汇总表，请确认：
[1] 单表验证 - 验证汇总表内部层级一致性
[2] 双表验证 - 需要验证明细表数据
```

### Step 1 DDL 解析失败

**DDL 格式不标准：**
```
建议：
1. 使用 mysqldump --no-data 导出纯 DDL
2. 删除 ENGINE、CHARSET 等非必要部分（可选）
```

**解析后的 JSON 不符合预期：**
```
AI 展示 JSON → 用户确认后继续
如果用户说"不确认"：
  → 询问具体哪里不对
  → 根据反馈重新解析
  → 最多重试 3 次，然后转人工干预
```

### Step 2 审核失败

根据审核报告的错误类型修复：
- 结构缺失 → 补全 meta_info / dimension_definitions / metric_definitions
- 枚举值错误 → 检查 org_hierarchy.order 和 enum_values
- DERIVED 指标缺公式 → 为每个 DERIVED 添加 formula 字段

修复后重新审核。

### Step 3 SQL 执行失败

**SQL 语法错误：**
- NULLIF 函数是否被目标引擎支持（如不支持改用 CASE WHEN）
- 日期函数是否符合目标数仓规范

**性能问题（查询太慢）：**
- 确保 partition_field 已配置且 WHERE 条件命中分区
- 避免 SELECT *，只取需要的字段
