#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eolinker-case-creator Step 5：统一测试任务调试 + 结果分析

用法：
    python run_debug.py <caseID> <菜单名>
流程：登录 → addTask({菜单名}-自动调试, groupID=119) → testTask → 轮询 getTaskList
      → V2 report/search 定位报告 → report/get 统计 → 下载 zip 解析单用例错误 → 输出分析。
纯标准库，无第三方依赖。
"""
import json
import re
import ssl
import sys
import time
import urllib.parse
import urllib.request
import zipfile

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
import login  # noqa: E402

SPACE_KEY = "6mU5k3qa57e02888554eda5b7e9814c323cde54f75bb980"
PROJECT_HASH_KEY = "uatgvbLb09dab49a8b0eef3ee1b1c813d2e5b1fc48ce910"
OPEN_KEY = "HzVXYvq07b604f411a0ae914c4b6217fe8bd5a36020bca8"
OPEN_AUTH = "Basic aGFjOkYqWENIQ3dW"

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE


def post_form(session, path, data):
    body = urllib.parse.urlencode(data).encode("utf-8")
    req = urllib.request.Request(session["base"] + path, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("Authorization", session["jwt"])
    req.add_header("Pragma", "no-cache")
    req.add_header("Cookie", "uvId=" + session["uvId"])
    with urllib.request.urlopen(req, timeout=60, context=CTX) as resp:
        return resp.status, resp.read().decode("utf-8", "replace")


def post_open(path, data):
    body = urllib.parse.urlencode(data).encode("utf-8")
    req = urllib.request.Request("http://eolinker-tst-inter.yto.net.cn" + path,
                                 data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("eo-secret-key", OPEN_KEY)
    req.add_header("Authorization", OPEN_AUTH)
    with urllib.request.urlopen(req, timeout=60, context=CTX) as resp:
        return resp.status, resp.read().decode("utf-8", "replace")


def add_task(session, case_id, menu_name):
    data = [
        ("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY),
        ("taskName", menu_name + "-自动调试"),
        ("taskTime[]", "10:00"),
        ("groupID", "119"),
        ("envID", "80"),
        ("caseFilter", "3"),
        ("caseID[0][caseID]", case_id),
        ("caseID[0][retries]", "1"),
        ("retrySetting", '{"enable":false,"times":3,"interval":10000}'),
        ("taskCycle", "0"), ("taskDate[]", "0"), ("taskLoop", "0"),
    ]
    code, raw = post_form(session, "/index.php/automatedTest/AutomatedTestTask/addTask", data)
    print("[addTask] ->", raw[:200])
    tid = json.loads(raw).get("taskID")
    return str(tid)


def trigger(session, tid):
    code, raw = post_form(session, "/index.php/automatedTest/AutomatedTestTask/testTask",
                          [("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY),
                           ("taskID", tid)])
    print("[testTask] ->", raw[:120])


def poll(session, tid, timeout=180, interval=5):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(interval)
        code, raw = post_form(session, "/index.php/automatedTest/AutomatedTestTask/getTaskList",
                              [("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY),
                               ("pageNo", "1"), ("limit", "50")])
        for t in json.loads(raw).get("taskList", []):
            if str(t.get("taskID")) == tid:
                st, res = t.get("testStatus"), t.get("testResult")
                if st in ("success", "error"):
                    return t
    return {"testStatus": "timeout"}


def find_report(start_date, end_date):
    code, raw = post_open("/v2/api_studio/automated_test/report/search", [
        ("project_id", PROJECT_HASH_KEY), ("space_id", SPACE_KEY),
        ("report_type", "timed_task"),
        ("start_time", start_date), ("end_time", end_date),
    ])
    return json.loads(raw).get("result", [])


def report_detail(report_id):
    code, raw = post_open("/v2/api_studio/automated_test/report/get", [
        ("space_id", SPACE_KEY), ("project_id", PROJECT_HASH_KEY),
        ("report_id", report_id), ("report_type", "timed_task"),
    ])
    return json.loads(raw).get("result", {})


def analyze_zip(url):
    """下载报告 zip，解析单用例错误，返回 [(apiName, status, errorMsg), ...]"""
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=60, context=CTX) as resp:
        raw = resp.read()
    import io
    z = zipfile.ZipFile(io.BytesIO(raw))
    out = []
    # 1) caseSurveyList.js 拿每步 reportStatus
    survey = z.read("data/caseSurveyList.js").decode("utf-8", "replace")
    status_map = {}
    for m in re.finditer(r'"apiName"\s*:\s*"([^"]+)".*?"reportStatus"\s*:\s*"([^"]+)"', survey):
        status_map[m.group(1)] = m.group(2)
    # 2) scene/0/0.js 拿 errorList
    scene = z.read("data/scene/0/0.js").decode("utf-8", "replace")
    err_map = {}
    for m in re.finditer(r'"apiName"\s*:\s*"([^"]+)"[\s\S]{0,4000}?"errorList"\s*:\s*(\[[^\]]*\])', scene):
        err_map[m.group(1)] = m.group(2)
    for name in ("日期接口", "趋势图", "明细列表"):
        out.append((name, status_map.get(name, "?"), err_map.get(name, "")))
    return out


def main():
    case_id, menu_name = sys.argv[1], sys.argv[2]
    session = login.login()
    tid = add_task(session, case_id, menu_name)
    trigger(session, tid)
    t = poll(session, tid)
    print("\n[任务结果] testStatus=%s testResult=%s testTime=%s" %
          (t.get("testStatus"), t.get("testResult"), t.get("testTime")))
    today = time.strftime("%Y-%m-%d")
    reports = find_report(today, today)
    hit = None
    for r in reports:
        if str(r.get("test_time", "")).startswith(str(t.get("testTime", ""))[:16]):
            hit = r
            break
    if not hit and reports:
        hit = reports[0]
    if not hit:
        print("未找到报告，请稍后重试 find_report（等 5~10s 重试）")
        cleanup_task(session, tid)
        return
    rid = hit["report_id"]
    print("[报告] report_id=%s 用例 %s/%s 成功，单用例 %s/%s 成功" % (
        rid, hit["success_case_num"], hit["case_num"],
        hit.get("success_single_case_num", "?"), hit.get("single_case_num", "?")))
    det = report_detail(rid)
    for f in det.get("failure_case_list", []):
        print("[失败用例] case_id=%s name=%s 单用例失败 %s/%s" % (
            f["case_id"], f["case_name"], f["failure_single_case_num"], f["single_case_num"]))
    dl = det.get("report_download_url") or hit.get("report_download_url")
    if dl:
        print("\n[单用例明细]")
        for name, status, err in analyze_zip(dl):
            print("  - %s : %s" % (name, status))
            if "codeError" in status or err:
                print("      %s" % re.sub(r'\s+', ' ', err)[:300])
    cleanup_task(session, tid)
    print("\n提示：断言修复需用户确认后再改（无单步删除端点，改断言需整条 deleteTestCase 重建）。")


def cleanup_task(session, tid):
    """删除临时调试任务，避免每日定时误触发（无论成败都执行）。"""
    code, raw = post_form(session, "/index.php/automatedTest/AutomatedTestTask/deleteTask",
                          [("spaceKey", SPACE_KEY), ("projectHashKey", PROJECT_HASH_KEY),
                           ("taskID[]", tid)])
    print("[deleteTask %s] -> %s" % (tid, raw[:120]))


if __name__ == "__main__":
    main()
