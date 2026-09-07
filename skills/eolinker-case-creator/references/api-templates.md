# eolinker API 参数模板

> 依据：`C:\Users\闫再再\Desktop\eolinker创建用例流程.md`（行号指该文件）
> 所有请求为 form-data，需携带 header：Authorization / Pragma / Cookie

## 一、addTestCase（添加用例名）

`POST /index.php/automatedTest/AutomatedTestCase/addTestCase`（文档 L32）

| 参数 | 取值 | 依据 |
|---|---|---|
| spaceKey | 6mU5k3qa57e02888554eda5b7e9814c323cde54f75bb980 | L37 |
| projectHashKey | uatgvbLb09dab49a8b0eef3ee1b1c813d2e5b1fc48ce910 | L38 |
| module | "0" | L39 |
| caseName | **用户输入** | L40 |
| groupID | **默认 394**（出港运能成本菜单分组） | L41 |
| priority | "0" | L42 |
| caseStyle | general | L43 |
| uuid | "" | L44 |
| caseTag | "" | L45 |
| caseType | "0" | L46 |

**返回体提取 `caseID`**（文档 L109 示例为 "16404"），供 addSingleCase 使用。

## 二、addSingleCase（添加单用例 · 新增语义）

`POST /index.php/automatedTest/AutomatedTestCaseSingle/addSingleCase`（文档 L87）

> ⚠️ 每次调用新增一个单用例，不覆盖。断言首次创建即注入；修正需先删除再重建。

### 2.1 外层参数固定模板

| 参数 | 固定值 | 依据 |
|---|---|---|
| apiType | http | L92 |
| spaceKey | 6mU5k3qa...980 | L93 |
| projectHashKey | uatgvbLb...910 | L94 |
| apiName | 日期接口 / 趋势图 / 明细列表（分别命名） | L95 |
| apiURI | `{{url}}/api-csc/...`（域名替换为环境变量） | L96 |
| apiProtocol | "0" | L97 |
| apiRequestType | "0" | L98 |
| caseData | 见 2.2，JSON 字符串 | L99 |
| caseID | addTestCase 返回值 | L109 |
| advancedSetting | `{"requestRedirect":1,"checkSSL":0,"sendEoToken":1,"sendNocacheToken":0,"messageEncoding":"utf-8","messageSeparatorSetting":"none","httpsVersion":"followProject","httpVersion":"followProject"}` | L110 |
| retrySetting | `{"enable":false,"times":3,"interval":10000}` | L111 |
| customInfo | `{"caseNote":"","proto":"","interfaceName":"","methodName":""}` | L112 |
| statusCodeVerification | `{"checkStatus":true,"statusCode":"200"}` | L113 |
| responseResultVerification | `{"checkStatus":false,"paramMatch":"json","jsonResultVerification":{"resultType":"object","matchRule":"allElement"},"matchRule":[]}` | L114 |
| responseTimeVerification | `{"checkStatus":true,"projectTimeoutSetting":"project","timeoutLimit":5000,"timeoutLimitType":"totalTime"}` | L115 |
| responseHeaderVerification | `{"checkStatus":false,"matchRule":[]}` | L116 |
| responseHeader | [] | L117 |
| resultParam | [] | L118 |
| resultParamType | json | L119 |
| resultParamJsonType | object | L120 |
| judgeSetting | "1" | L121 |
| delayTime | "0" | L122 |
| module | "0" | L123 |
| stepType | "0" | L124 |
| beforeScriptMode | "2" | L125 |
| beforeScriptList | [] | L126 |
| afterScriptMode | "2" | L127 |
| afterScriptList | **首建即注入默认断言**（见 assert-scripts.md） | L128 |

### 2.2 caseData JSON 字符串结构（文档 L99-108 示例）

```json
{
  "messageEncoding": "utf-8",
  "messageSeparatorSetting": "none",
  "headers": [
    {"headerName": "Content-Type", "headerValue": "application/json", "paramName": "", "checkbox": true}
  ],
  "params": [],
  "URL": "{{url}}/api-csc/...",
  "requestType": "1",
  "raw": "{...JSON body 原样，内部换行转义 \\n...}",
  "apiRequestType": 0,
  "httpHeader": 0,
  "urlParam": [],
  "restfulParam": [],
  "auth": {"status": "0"},
  "apiRequestParamJsonType": "0",
  "script": {"before": "", "after": "", "prepare": "", "type": "0"},
  "keepGoing": 1
}
```

要点：
- `URL` 域名部分替换为 `{{url}}` 环境变量
- `requestType`：GET→"0"，POST→"1"
- `raw` 为 HAR `request.postData.text` 原样保留（序列化时换行转义）
- headers 剔除 Cookie / Accept-Encoding 等浏览器头

## 三、登录接口（Step 1，拿 JWT）

`POST /userCenter/common/sso/login`（content-type: application/json）

```json
{"keepLogin":1,"username":"02004619","type":1,"password":"MAksLAvvCZ7M1fxSaTQtzg==","client":0,"appType":0}
```

header：`Cookie: uvId=<uuid>`、`Pragma: no-cache`、`Origin/Referer`。

返回：`{"success":true,"code":0,"data":{"jwt":"<三段JWT>","rjwt":"...","userId":195}}`。

后续请求统一带：`Authorization: <data.jwt>` + `Pragma: no-cache` + `Cookie: uvId=<uuid>`。

## 四、测试任务调试（Step 5，统一方式）

### 4.1 addTask（建「{菜单名}-自动调试」任务）

`POST /index.php/automatedTest/AutomatedTestTask/addTask`（form-data）

| 字段 | 取值 | 备注 |
|---|---|---|
| taskName | `{菜单名}-自动调试` | |
| groupID | `119` | 394 报 `200301 no permission` |
| envID | `80` | 生产 GPT预生产 |
| caseFilter | `3` | 指定用例 |
| caseID | `caseID[0][caseID]=<id>` + `caseID[0][retries]=1` | **对象数组**，否则 `100012` |
| taskTime | `taskTime[]=10:00` | HH:MM，不能空 |
| taskCycle/taskDate/taskLoop | `0` / `taskDate[]=0` / `0` | 不填会报 `no permission`（走权限分支） |
| retrySetting | `{"enable":false,"times":3,"interval":10000}` | JSON 串 |

返回 `taskID`。

### 4.2 testTask（触发运行）

`POST /index.php/automatedTest/AutomatedTestTask/testTask`（spaceKey + projectHashKey + taskID）。

### 4.3 轮询 getTaskList

`POST /index.php/automatedTest/AutomatedTestTask/getTaskList`（pageNo/limit）→ 找 taskID 的 `testStatus`(success/error) / `testResult`(1/2)。

### 4.4 V2 报告（open API，header：`eo-secret-key` + `Authorization: Basic aGFjOkYqWENIQ3dW`）

| 端点 | 用途 | 关键参数 |
|---|---|---|
| `POST /v2/api_studio/automated_test/report/search` | 报告列表 | project_id/space_id/report_type=timed_task/start_time/end_time |
| `POST /v2/api_studio/automated_test/report/get` | 报告统计 | report_id/report_type → failure_case_list + single_case 计数 |

报告详情 zip 由 `report_download_url`（内网 `http://10.130.10.230/...zip`）下载解压，单用例错误在 `data/scene/0/0.js`（errorList）与 `data/caseSurveyList.js`（reportStatus）。

### 4.5 deleteTask（清理临时任务）

`POST /index.php/automatedTest/AutomatedTestTask/deleteTask`（spaceKey + projectHashKey + **`taskID[]=<id>`**，数组形式，否则 `100400 参数错误`）。

## 五、已确认结论（2026-09-07 首跑探测）

| 项 | 结论 |
|---|---|
| `/api/automatedTest/...` | 直接调报 `class not found`，必须用 `/index.php/automatedTest/...` |
| deleteSingleCase | **不存在**（多个 action 名均 `action not found`）；改断言只能 `deleteTestCase` 整条重建 |
| addSingleCase 带 connID | 仍为**新增**（返回新 connID），不覆盖 |
| V3 运行接口 | 不可用（open API 无 run 端点），统一走 addTask/testTask |
