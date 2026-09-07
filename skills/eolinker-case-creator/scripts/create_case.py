#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eolinker-case-creator Step 3~4：addTestCase + addSingleCase ×3（断言首建注入）

用法：
    python create_case.py <har路径> <caseName> [groupID]
默认 groupID=394（出港运能成本）。自动调用 login.py 登录拿鉴权。
断言路径常量见下方 ASSERT_*，按 HAR 响应结构预判后可改。
"""
import json
import re
import ssl
import sys
import urllib.parse
import urllib.request

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
import login  # noqa: E402

SPACE_KEY = "6mU5k3qa57e02888554eda5b7e9814c323cde54f75bb980"
PROJECT_HASH_KEY = "uatgvbLb09dab49a8b0eef3ee1b1c813d2e5b1fc48ce910"

# ===== 断言取值路径（按目标菜单 HAR 响应预判后修改） =====
ASSERT_DATE_PATH = "data.object2json.date"      # 日期接口最新日期（单值）
ASSERT_TREND_XDATA = "data.object2json.xdata"   # 趋势图 X 轴
ASSERT_TREND_YDATA = "data.object2json.ydata"   # 趋势图数值（数组套数组，取 [0]）
ASSERT_LIST_FIELD = "orgName"                    # 明细列表去重字段

# 识别规则（趋势图兜底 queryLine）
RULES = [
    ("list",  re.compile(r"list", re.I), "明细列表"),
    ("date",  re.compile(r"date|queryDate|latestDate", re.I), "日期接口"),
    ("trend", re.compile(r"trend|chart|series|queryLine", re.I), "趋势图"),
]

STRIP_HEADERS = {"cookie", "accept", "accept-encoding", "accept-language",
                 "user-agent", "referer", "origin", "host", "connection",
                 "content-length", "cache-control", "pragma"}

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE


def post(session, path, data):
    body = urllib.parse.urlencode(data).encode("utf-8")
    req = urllib.request.Request(session["base"] + path, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("Authorization", session["jwt"])
    req.add_header("Pragma", "no-cache")
    req.add_header("Cookie", "uvId=" + session["uvId"])
    with urllib.request.urlopen(req, timeout=60, context=CTX) as resp:
        return resp.status, resp.read().decode("utf-8", "replace")


def pick_entries(har):
    """按 RULES 识别三个接口（去重，取首个）。"""
    picked = {"date": None, "trend": None, "list": None}
    for e in har["log"]["entries"]:
        url = e["request"]["url"]
        for key, rx, _name in RULES:
            if key not in picked or picked[key] is None:
                if rx.search(url):
                    picked[key] = e
                    break
    return picked


def analyze_variations(har, url):
    """分析同一 URL 多次调用的 body 参数差异，返回 {field: {"unique_values":[...], "count":N}}。"""
    bodies = []
    for e in har["log"]["entries"]:
        if e["request"]["url"] == url:
            text = (e["request"].get("postData") or {}).get("text") or ""
            try:
                obj = json.loads(text)
                if isinstance(obj, dict):
                    bodies.append(obj)
            except Exception:
                pass
    if len(bodies) < 2:
        return {}
    field_values = {}
    for b in bodies:
        for k, v in b.items():
            field_values.setdefault(k, set())
            field_values[k].add(json.dumps(v, ensure_ascii=False, sort_keys=True))
    variations = {}
    for k, vs in field_values.items():
        if len(vs) > 1:
            variations[k] = {"unique_values": sorted(vs), "count": len(vs)}
    return variations


def parametrize_raw(case_data, variations):
    """参数化 raw 中的字段：queryDate→{{date}}，其余参数化字段→$dc{字段名}。"""
    raw = case_data.get("raw") or ""
    try:
        obj = json.loads(raw)
    except Exception:
        return case_data
    if not isinstance(obj, dict):
        return case_data
    for k in list(obj.keys()):
        if k == "queryDate":
            obj[k] = "{{date}}"
        elif k in variations:
            obj[k] = "$dc{" + k + "}"
    case_data["raw"] = json.dumps(obj, ensure_ascii=False)
    return case_data


def build_case_data(entry):
    req = entry["request"]
    url = req["url"]
    # 去掉业务域名，只保留 path（含端口前缀段）
    path = re.sub(r"^https?://[^/]+", "", url)
    headers = []
    for h in req.get("headers") or []:
        if h.get("name", "").lower() in STRIP_HEADERS:
            continue
        headers.append({"headerName": h.get("name", ""), "headerValue": h.get("value", ""),
                        "paramName": "", "checkbox": True})
    return {
        "messageEncoding": "utf-8", "messageSeparatorSetting": "none",
        "headers": headers, "params": [],
        "URL": "{{url}}" + path,
        "requestType": "1",
        "raw": (req.get("postData") or {}).get("text") or "",
        "apiRequestType": 0, "httpHeader": 0, "urlParam": [], "restfulParam": [],
        "auth": {"status": "0"}, "apiRequestParamJsonType": "0",
        "script": {"before": "", "after": "", "prepare": "", "type": "0"},
        "keepGoing": 1,
    }


ASSERT_HELPER = ("function _eoAssert(c,m){"
                 " if(typeof eo.assert==='function'){eo.assert(c,m);}"
                 " else if(!c){throw new Error('断言失败：'+m);} }")


def date_script(sum_type="D"):
    """日期接口断言：D=日数据(最新日期=T-1)，M=月数据(最新月份=当月 T月)。"""
    if str(sum_type).upper() == "M":
        return month_script()
    return day_script()


def day_script():
    p = ASSERT_DATE_PATH
    return "\r\n".join([
        "eo.info(eo.http.responseParam);",
        "eo.http.responseParam = JSON.parse(eo.http.responseParam);",
        "var resp = eo.http.responseParam;",
        ASSERT_HELPER,
        "var latestDate = resp." + p + ";",
        "eo.info('最新日期: ' + latestDate);",
        "function _f(d){return d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2);}",
        "var d=new Date(); d.setDate(d.getDate()-1); var t1=_f(d);",
        "_eoAssert(!!latestDate, '未获取到最新日期');",
        "_eoAssert(latestDate===t1, '最新日期应为T-1('+t1+')，实际为 '+latestDate);",
    ])


def month_script():
    p = ASSERT_DATE_PATH
    return "\r\n".join([
        "eo.info(eo.http.responseParam);",
        "eo.http.responseParam = JSON.parse(eo.http.responseParam);",
        "var resp = eo.http.responseParam;",
        ASSERT_HELPER,
        "var latestMonth = resp." + p + ";",   # 如 "2026-09"
        "eo.info('最新月份: ' + latestMonth);",
        "var d=new Date();",
        "var cur=d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2);",
        "_eoAssert(!!latestMonth, '未获取到最新月份');",
        "_eoAssert(latestMonth===cur, '最新月份应为当月('+cur+')，实际为 '+latestMonth);",
    ])


def trend_script():
    x, y = ASSERT_TREND_XDATA, ASSERT_TREND_YDATA
    return "\r\n".join([
        "eo.info(eo.http.responseParam);",
        "eo.http.responseParam = JSON.parse(eo.http.responseParam);",
        "var resp = eo.http.responseParam;",
        ASSERT_HELPER,
        "var xd = resp." + x + " || [];",
        "var yd = resp." + y + " || [];",
        "_eoAssert(xd.length>0, '趋势图X轴不应为空');",
        "_eoAssert(yd.length>0, '趋势图数据不应为空');",
        "var s = yd[0] || [];",
        "_eoAssert(s.length>0, '趋势图数值序列不应为空');",
        "_eoAssert(s.some(function(v){return Number(v)!==0;}), '趋势图数据不应全为0');",
    ])


def list_script():
    f = ASSERT_LIST_FIELD
    return "\r\n".join([
        "eo.info(eo.http.responseParam);",
        "eo.http.responseParam = JSON.parse(eo.http.responseParam);",
        'eo.userFunction.getListRepetitionAssert(eo.http.responseParam, "%s");' % f,
    ])


def after(script):
    return json.dumps([{"stepName": "自定义脚本", "stepType": 3,
                        "script": script, "stepOrder": 0}], ensure_ascii=False)


def add_single(session, case_id, api_name, case_data, script):
    data = [
        ("apiType", "http"), ("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY),
        ("apiName", api_name), ("apiURI", case_data["URL"]),
        ("apiProtocol", "0"), ("apiRequestType", "0"),
        ("caseData", json.dumps(case_data, ensure_ascii=False)),
        ("caseID", case_id),
        ("advancedSetting", '{"requestRedirect":1,"checkSSL":0,"sendEoToken":1,"sendNocacheToken":0,"messageEncoding":"utf-8","messageSeparatorSetting":"none","httpsVersion":"followProject","httpVersion":"followProject"}'),
        ("retrySetting", '{"enable":false,"times":3,"interval":10000}'),
        ("customInfo", '{"caseNote":"","proto":"","interfaceName":"","methodName":""}'),
        ("statusCodeVerification", '{"checkStatus":true,"statusCode":"200"}'),
        ("responseResultVerification", '{"checkStatus":false,"paramMatch":"json","jsonResultVerification":{"resultType":"object","matchRule":"allElement"},"matchRule":[]}'),
        ("responseTimeVerification", '{"checkStatus":true,"projectTimeoutSetting":"project","timeoutLimit":5000,"timeoutLimitType":"totalTime"}'),
        ("responseHeaderVerification", '{"checkStatus":false,"matchRule":[]}'),
        ("responseHeader", []), ("resultParam", []),
        ("resultParamType", "json"), ("resultParamJsonType", "object"),
        ("judgeSetting", "1"), ("delayTime", "0"), ("module", "0"), ("stepType", "0"),
        ("beforeScriptMode", "2"), ("beforeScriptList", []),
        ("afterScriptMode", "2"), ("afterScriptList", after(script)),
    ]
    code, raw = post(session, "/index.php/automatedTest/AutomatedTestCaseSingle/addSingleCase", data)
    print("[addSingleCase] %s -> %s %s" % (api_name, code, raw[:120]))
    return raw


def detect_sum_type(picked):
    """从日期接口 body 解析 sumType：D=日数据，M=月数据（默认 D）。"""
    entry = picked.get("date")
    if entry is None:
        return "D"
    raw = (entry.get("request") or {}).get("postData") or {}
    body = raw.get("text") or ""
    try:
        obj = json.loads(body)
        return str(obj.get("sumType", "D")).upper()
    except Exception:
        m = re.search(r'"sumType"\s*:\s*"([A-Za-z]+)"', body)
        return m.group(1).upper() if m else "D"


DIM_MAP = {"D": "日", "M": "月", "Y": "年", "date": "日", "month": "月", "year": "年"}
PARAM_PRIORITY = ["sumType", "queryType", "secondTabType", "sortColumn"]


def collect_param_combos(har):
    """收集业务接口（queryLine/queryList/queryDateByType）所有 body 的参数组合。

    返回 (变化字段顺序, 唯一组合列表[{field: value}])。
    """
    bodies = []
    for e in har["log"]["entries"]:
        url = e["request"]["url"]
        if not re.search(r"queryLine|queryList|queryDateByType|queryDate", url):
            continue
        text = (e["request"].get("postData") or {}).get("text") or ""
        try:
            obj = json.loads(text)
            if isinstance(obj, dict):
                bodies.append(obj)
        except Exception:
            pass
    if not bodies:
        return [], []
    all_keys = []
    for b in bodies:
        for k in b:
            if k not in all_keys:
                all_keys.append(k)
    field_values = {k: set() for k in all_keys}
    for b in bodies:
        for k in all_keys:
            field_values[k].add(json.dumps(b.get(k), ensure_ascii=False, sort_keys=True))
    vary = [k for k in all_keys if len(field_values[k]) > 1 and k != "queryDate"]
    vary = [k for k in PARAM_PRIORITY if k in vary] + [k for k in vary if k not in PARAM_PRIORITY]
    combos = []
    seen = set()
    for b in bodies:
        tup = tuple(json.dumps(b.get(k), ensure_ascii=False, sort_keys=True) for k in vary)
        if tup in seen:
            continue
        seen.add(tup)
        combos.append({k: b.get(k) for k in vary})
    return vary, combos


def generate_dataset_csv(har, case_name, output_path):
    """生成参数化文件（数据集 CSV），供导入 eolinker 数据集。UTF-8 BOM 便于 Excel 打开。"""
    vary, combos = collect_param_combos(har)
    if not vary or not combos:
        print("[参数化文件] 未发现变化字段，跳过数据集文件生成")
        return
    header = ["数据集名称", "数据集标签"] + ["$dc{%s}" % k for k in vary]
    lines = [",".join(header)]
    for c in combos:
        dim = ""
        if "sumType" in c:
            dim = DIM_MAP.get(str(c["sumType"]), "")
        if not dim and "queryType" in c:
            dim = DIM_MAP.get(str(c["queryType"]), "")
        name = ("%s--%s" % (dim, case_name)) if dim else case_name
        vals = [name, ""] + [str(c.get(k, "")) for k in vary]
        lines.append(",".join(vals))
    with open(output_path, "w", encoding="utf-8-sig") as f:
        f.write("\n".join(lines))
    print("[参数化文件] 已生成 %s（%d 个数据集，字段 %s）" % (
        output_path, len(combos), ", ".join("$dc{%s}" % k for k in vary)))


def main():
    har_path, case_name = sys.argv[1], sys.argv[2]
    group_id = sys.argv[3] if len(sys.argv) > 3 else "394"
    session = login.login()
    har = json.load(open(har_path, encoding="utf-8"))
    picked = pick_entries(har)
    sum_type = detect_sum_type(picked)

    order = [("date", "日期接口", date_script),
             ("trend", "趋势图", trend_script),
             ("list", "明细列表", list_script)]
    for key, name, _s in order:
        if picked.get(key) is None:
            print("!! 未识别到接口：%s" % key)
    print("[日期数据粒度] sumType = %s（%s）" % (
        sum_type, "月数据，断言最新月份=当月" if sum_type == "M" else "日数据，断言最新日期=T-1"))

    code, raw = post(session, "/index.php/automatedTest/AutomatedTestCase/addTestCase", [
        ("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY), ("module", "0"),
        ("caseName", case_name), ("groupID", group_id), ("priority", "0"),
        ("caseStyle", "general"), ("uuid", ""), ("caseTag", ""), ("caseType", "0"),
    ])
    print("[addTestCase] ->", raw[:200])
    cid = str(json.loads(raw)["caseID"])
    print("caseID =", cid)

    for key, name, make_script in order:
        entry = picked.get(key)
        if entry is None:
            continue
        cd = build_case_data(entry)
        variations = analyze_variations(har, entry["request"]["url"])
        if variations:
            print("[参数化] %s -> %s" % (name, ", ".join(variations.keys())))
        cd = parametrize_raw(cd, variations)
        if key == "date":
            script = make_script(sum_type)
        else:
            script = make_script()
        add_single(session, cid, name, cd, script)
    generate_dataset_csv(har, case_name, case_name + "_dataset.csv")
    print("完成，caseID=", cid)


if __name__ == "__main__":
    main()
