# HAR → eolinker caseData 字段映射表

## 一、接口识别规则（优先级从高到低）

| 优先级 | 目标接口 | URL 匹配规则（不区分大小写） |
|---|---|---|
| 1 | 明细列表接口 | 含 `list` |
| 2 | 日期接口 | 含 `date` / `queryDate` / `latestDate` |
| 3 | 趋势图接口 | 含 `trend` / `chart` / `series` |

> 用户已确认（2026-09-07）：明细列表用 `list` 匹配，**不要**用 `queryFakeSignByCondition`。
> 匹配失败：展示候选清单交用户手工指认。规则首跑校准后回写本文件。

## 二、HAR 字段 → caseData 映射

| HAR 字段 | eolinker 目标字段 | 转换规则 |
|---|---|---|
| `log.entries[].request.url` | `apiURI`（外层）+ `caseData.URL` | 域名部分替换为 `{{url}}` 环境变量 |
| `request.method` | `caseData.requestType` | GET→"0"，POST→"1" |
| `request.headers` | `caseData.headers` | 仅保留业务头（Content-Type 等），格式 `[{"headerName":"","headerValue":"","paramName":"","checkbox":true}]`；剔除 Cookie / Accept / Accept-Encoding / User-Agent / Referer 等浏览器头 |
| `request.postData.text` | `caseData.raw` | JSON body 原样保留，序列化时换行转义 `\n` |
| — | `caseData.apiRequestParamJsonType` | "0"（raw JSON） |
| — | `apiProtocol`（外层） | "0"（http） |
| `response.content.text` | （不入 caseData） | 用于 Step 2 预判断言取值路径 |

## 三、HAR 解析要点

- 路径：`har["log"]["entries"]`
- 过滤：仅保留业务域名（如 `api-csc`）下的 XHR/Fetch；`entry._resourceType` 为 xhr/fetch 时优先采用
- 去重：按 `method + url` 去重（驾驶舱页面常对日期接口多次轮询），保留最后一次（响应最新）
- 响应体：`entry.response.content.text`（可能为 base64 编码，`encoding == "base64"` 时需解码）；部分导出会丢弃响应体 → 走 SKILL.md Step 5 两阶段兜底

## 四、断言路径预判（从 HAR 响应体）

| 接口 | 预判目标 | 示例 |
|---|---|---|
| 日期接口 | 最新日期字段路径 | `data.dateList[-1]` / `data.latestDate` |
| 趋势图接口 | 趋势数组路径 + 数值字段名 | `data` + `value` / `data.trendList` + `num` |
| 明细列表接口 | 列表路径 + orgName 字段 | `data.list` + `orgName` |

预判结果替换 `references/assert-scripts.md` 中 `<DATE_PATH>` / `<TREND_PATH>` / `<VALUE_FIELD>` 占位符。
