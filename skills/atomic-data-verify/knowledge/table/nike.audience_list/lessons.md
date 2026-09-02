# audience_list 踩坑记录

- **迁移来源**：knowledge/verify-lessons.md
- **最后更新**：迁移自动生成


### 3. int/bigint 字段的 NULL 处理

**问题**：模板中对所有字段使用 `NULLIF(field, '')` 处理，但 int/bigint 类型字段不会存储空字符串，使用 `NULLIF(field, '')` 无意义且可能导致类型转换错误。

**解决**：
- int/bigint 字段：直接使用 `COALESCE(CAST(field AS CHAR), 'XXT')`
- varchar 字段：保留 `COALESCE(CAST(NULLIF(field, '') AS CHAR), 'XXT')`

**教训**：执行字段比对时，需根据字段类型选择合适的 NULL 处理方式。

