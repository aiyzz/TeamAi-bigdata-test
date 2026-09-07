# 默认断言脚本库

afterScriptList 元素结构（文档 L128-149）：

```json
[{
  "stepName": "自定义脚本",
  "stepType": 3,
  "script": "<JS 代码，\\r\\n 为换行>",
  "stepOrder": 0
}]
```

> 占位符说明：`<DATE_PATH>` / `<TREND_PATH>` / `<VALUE_FIELD>` 由 Step 2 从 HAR 响应体预判后替换（如 `data.dateList`、`data`、`value`）。

## 一、日期接口断言

按 `sumType` 区分两种数据粒度（从日期接口 body 的 `sumType` 字段判断，`D`=日数据、`M`=月数据）：

### 1.1 日数据（sumType=D）：最新日期 = T-1

```javascript
// 服务端返回的数据信息
eo.info(eo.http.responseParam);
eo.http.responseParam = JSON.parse(eo.http.responseParam);
var resp = eo.http.responseParam;
// 断言路径由 HAR 响应预判替换（示例假设 resp.<DATE_PATH> 为日期数组）
var dateList = resp.<DATE_PATH>;
var latestDate = dateList[dateList.length - 1];
// 动态计算 T-1（昨天，格式 yyyy-MM-dd，不硬编码）
var d = new Date();
d.setDate(d.getDate() - 1);
var t1 = d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2);
eo.assert(latestDate === t1, "最新日期应为T-1(" + t1 + ")，实际为 " + latestDate);
```

> 若日期字段是单值而非数组（如 `data.object2json.date`），直接取 `resp.<DATE_PATH>`，跳过 `dateList[dateList.length-1]`。

### 1.2 月数据（sumType=M）：最新月份 = 当月（T 月）

```javascript
// 服务端返回的数据信息
eo.info(eo.http.responseParam);
eo.http.responseParam = JSON.parse(eo.http.responseParam);
var resp = eo.http.responseParam;
// 断言路径由 HAR 响应预判替换（月数据通常返回 "yyyy-MM"）
var latestMonth = resp.<DATE_PATH>;
eo.info('最新月份: ' + latestMonth);
var d = new Date();
var cur = d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2);
eo.assert(latestMonth === cur, "最新月份应为当月(" + cur + ")，实际为 " + latestMonth);
```

## 二、趋势图接口断言：数据不为 0 且不为空

```javascript
eo.info(eo.http.responseParam);
eo.http.responseParam = JSON.parse(eo.http.responseParam);
var resp = eo.http.responseParam;
// 断言路径由 HAR 响应预判替换（示例假设 resp.<TREND_PATH> 为趋势数组）
var trend = resp.<TREND_PATH>;
eo.assert(trend && trend.length > 0, "趋势图数据不应为空");
var nonZero = trend.some(function (item) {
    return Number(item.<VALUE_FIELD>) !== 0;
});
eo.assert(nonZero, "趋势图数据不应全为0");
```

## 三、明细列表断言：组织名不重复（平台内置函数，已验证）

```javascript
// 服务端返回的数据信息
eo.info(eo.http.responseParam);
eo.http.responseParam = JSON.parse(eo.http.responseParam);
// 使用过滤后的数据进行明细重复判断
eo.userFunction.getListRepetitionAssert(eo.http.responseParam, "orgName");
```

> 依据：文档 L131-148。`eo.userFunction.getListRepetitionAssert(参数, "orgName")` 为平台内置重复断言函数。

## 四、降级策略

- `eo.assert` 不可用时（首跑用 `eo.assert(true, "probe")` 探测），日期/趋势图断言降级为：

```javascript
if (!(断言条件)) {
    throw new Error("断言失败：期望 ...，实际 ...");
}
```

- 明细列表断言不依赖 eo.assert，直接可用。
