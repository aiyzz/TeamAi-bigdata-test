#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eolinker-case-creator 技能脚本：B 方式自动调试闭环

流程：触发 V3 运行 → 轮询结果 → 失败自动修正（删单用例 → 重建）→ 重跑，直到成功。
单轮上限 MAX_RETRY 次修正，超限输出失败清单停止。

⚠️ 端点配置（首跑探测后回填此处）：
  RUN_ENDPOINT    V3 触发执行端点（待探测，从 eolinker 前端网络面板抓取）
  REPORT_ENDPOINT 测试报告/结果查询端点（V3 缺 report/get，用报告列表/详情）
  DELETE_SINGLE_ENDPOINT 删除单用例端点（推测 AutomatedTestCaseSingle/deleteSingleCase）

本脚本为闭环骨架：端点未回填前仅支持 --check 模式校验配置；
端点回填后由技能主流程（LLM）按 SKILL.md Step 5 编排调用，或补全 _request 实现后独立运行。
纯标准库实现（urllib），无第三方依赖。
"""
import argparse
import json
import sys
import time
import urllib.parse
import urllib.request

# ===== 环境常量 =====
SPACE_KEY = "6mU5k3qa57e02888554eda5b7e9814c323cde54f75bb980"
PROJECT_HASH_KEY = "uatgvbLb09dab49a8b0eef3ee1b1c813d2e5b1fc48ce910"
GROUP_ID = "394"  # 出港运能成本菜单分组

# ===== 首跑探测后回填（当前为空 = 未探测） =====
# 2026-09-07 已确认：addTestCase 打到该域名返回业务 JSON（非 404/HTML），即域名正确
BASE_URL = "http://eolinker-tst-inter.yto.net.cn"
RUN_ENDPOINT = ""          # 例：/v3/automated-test/xxx/run（待探测）
REPORT_ENDPOINT = ""       # 例：/v3/automated-test/xxx/report（待探测）
DELETE_SINGLE_ENDPOINT = ""  # 例：/index.php/automatedTest/AutomatedTestCaseSingle/deleteSingleCase（待探测）

# ===== 闭环参数 =====
POLL_INTERVAL = 5      # 轮询间隔（秒）
POLL_TIMEOUT = 120     # 单次运行最长等待（秒）
MAX_RETRY = 5          # 自动修正上限


def check_config():
    """校验端点配置是否已回填。"""
    missing = [k for k, v in {
        "BASE_URL": BASE_URL,
        "RUN_ENDPOINT": RUN_ENDPOINT,
        "REPORT_ENDPOINT": REPORT_ENDPOINT,
        "DELETE_SINGLE_ENDPOINT": DELETE_SINGLE_ENDPOINT,
    }.items() if not v]
    if missing:
        print("[未配置] 以下端点待首跑探测后回填：%s" % "、".join(missing))
        print("探测方法：eolinker 前端 F12 网络面板，分别抓取：")
        print("  1. 自动化测试页点击「运行」的请求 → RUN_ENDPOINT")
        print("  2. 运行后拉取报告/结果的请求 → REPORT_ENDPOINT")
        print("  3. 删除单用例的请求 → DELETE_SINGLE_ENDPOINT")
        return False
    print("[已配置] 端点齐备，可执行自动调试闭环。")
    return True


def _request(path, data=None, headers=None, method="POST"):
    """通用 form-data 请求（端点回填后启用）。"""
    if not BASE_URL:
        raise RuntimeError("BASE_URL 未配置")
    url = BASE_URL + path
    if data is not None:
        body = urllib.parse.urlencode(data).encode("utf-8")
    else:
        body = None
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def trigger_run(case_id, headers):
    """触发 V3 运行（携带 caseID）。返回运行标识。"""
    result = _request(RUN_ENDPOINT, data={
        "spaceKey": SPACE_KEY,
        "projectHashKey": PROJECT_HASH_KEY,
        "caseID": case_id,
    }, headers=headers)
    return result


def poll_report(run_id, headers):
    """轮询执行结果，返回三个单用例的状态/响应/断言结果。"""
    deadline = time.time() + POLL_TIMEOUT
    while time.time() < deadline:
        result = _request(REPORT_ENDPOINT, data={"runID": run_id}, headers=headers)
        # TODO: 按真实返回结构解析，此处为骨架
        # status == finished 时返回明细
        time.sleep(POLL_INTERVAL)
    raise TimeoutError("轮询超时（%ds）" % POLL_TIMEOUT)


def delete_single_case(single_case_id, headers):
    """删除单用例（新增语义下的修正手段，绝不重复 addSingleCase 追加）。"""
    return _request(DELETE_SINGLE_ENDPOINT, data={
        "spaceKey": SPACE_KEY,
        "projectHashKey": PROJECT_HASH_KEY,
        "caseID": single_case_id,
    }, headers=headers)


def debug_loop(case_id, headers, fix_fn):
    """自动调试闭环主流程。

    fix_fn(single_case_result) -> (fixed_case_data, fixed_after_script_list) or None
    由技能主流程提供：根据失败原因修正 caseData / 断言路径。
    """
    for attempt in range(1, MAX_RETRY + 1):
        run = trigger_run(case_id, headers)
        detail = poll_report(run.get("runID"), headers)
        failures = [d for d in detail if not d.get("ok")]
        if not failures:
            return {"success": True, "attempts": attempt, "detail": detail}
        print("[第%d次] 失败明细：%s" % (attempt, json.dumps(failures, ensure_ascii=False)))
        for f in failures:
            fixed = fix_fn(f)
            if fixed is None:
                return {"success": False, "attempts": attempt, "failures": failures,
                        "reason": "修正函数无法处理，转人工决策"}
            delete_single_case(f["singleCaseID"], headers)
            # 重建由技能主流程调用 addSingleCase 完成（携带修正后的 caseData + afterScriptList）
    return {"success": False, "attempts": MAX_RETRY,
            "reason": "达到重试上限，输出失败清单停止"}


def main():
    ap = argparse.ArgumentParser(description="eolinker B 方式自动调试闭环（骨架）")
    ap.add_argument("--check", action="store_true", help="校验端点配置状态")
    args = ap.parse_args()
    if args.check:
        ok = check_config()
        sys.exit(0 if ok else 1)
    if not check_config():
        sys.exit(1)
    print("端点已配置。完整闭环由技能主流程按 SKILL.md Step 5 编排调用本模块函数。")


if __name__ == "__main__":
    main()
