#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eolinker-case-creator 技能脚本：HAR 解析 + 接口识别 + caseData 构造

用法：
    python parse_har.py <har文件路径> [-o 输出.json]

输出 JSON 结构：
{
  "candidates": [  # 全部候选接口（识别失败时供用户指认）
    {"method", "url", "body_summary", "count", "has_response"}
  ],
  "matched": {     # 按优先级匹配的三个接口
    "list":  {"api_name", "api_uri", "case_data", "response_sample"},
    "date":  {...},
    "trend": {...}
  },
  "notes": [...]   # 提示信息（如 HAR 无响应体需走两阶段兜底）
}

识别规则（2026-09-07 用户确认）：
  优先级1 明细列表：URL 含 list（不区分大小写）
  优先级2 日期接口：URL 含 date / queryDate / latestDate
  优先级3 趋势图接口：URL 含 trend / chart / series
纯标准库实现，无第三方依赖。
"""
import argparse
import base64
import json
import re
import sys

# ---- 识别规则（校准后回写） ----
RULES = [
    ("list",  re.compile(r"list", re.I)),
    ("date",  re.compile(r"date", re.I)),
    ("trend", re.compile(r"trend|chart|series", re.I)),
]

# 剔除的浏览器头（小写）
STRIP_HEADERS = {
    "cookie", "accept", "accept-encoding", "accept-language",
    "user-agent", "referer", "origin", "host", "connection",
    "content-length", "cache-control", "pragma",
}

API_NAME_MAP = {"list": "明细列表", "date": "日期接口", "trend": "趋势图"}


def get_response_text(entry):
    """提取 entry 的响应体文本（处理 base64 编码），失败返回 None。"""
    content = (entry.get("response") or {}).get("content") or {}
    text = content.get("text")
    if not text:
        return None
    if content.get("encoding") == "base64":
        try:
            return base64.b64decode(text).decode("utf-8", errors="replace")
        except Exception:
            return None
    return text


def parse_headers(har_headers):
    """HAR headers → eolinker caseData.headers，剔除浏览器头。"""
    result = []
    for h in har_headers or []:
        name = h.get("name", "")
        if name.lower() in STRIP_HEADERS:
            continue
        result.append({
            "headerName": name,
            "headerValue": h.get("value", ""),
            "paramName": "",
            "checkbox": True,
        })
    return result


def build_case_data(entry):
    """HAR entry.request → eolinker caseData（不含断言，断言由调用方注入）。

    URL 域名替换为 {{url}} 环境变量（与外层 apiURI 一致）。
    """
    req = entry.get("request") or {}
    url = req.get("url", "")
    method = (req.get("method") or "GET").upper()
    post_data = (req.get("postData") or {}).get("text") or ""
    return {
        "messageEncoding": "utf-8",
        "messageSeparatorSetting": "none",
        "headers": parse_headers(req.get("headers")),
        "params": [],
        "URL": to_env_url(url),
        "requestType": "1" if method == "POST" else "0",
        "raw": post_data,
        "apiRequestType": 0,
        "httpHeader": 0,
        "urlParam": [],
        "restfulParam": [],
        "auth": {"status": "0"},
        "apiRequestParamJsonType": "0",
        "script": {"before": "", "after": "", "prepare": "", "type": "0"},
        "keepGoing": 1,
    }, method, url


def to_env_url(url):
    """域名部分替换为 {{url}} 环境变量（保留路径与查询串）。"""
    m = re.match(r"^(https?://)([^/]+)(/.*)?$", url)
    if not m:
        return url
    path = m.group(3) or ""
    return "{{url}}" + path


def analyze_param_variations(entries):
    """对比同一接口多次调用的 body 参数，返回取值有差异的字段及其枚举值。

    返回 {field: {"unique_values": [...], "count": N}}，仅含取值不固定的字段。
    """
    bodies = []
    for e in entries:
        post = (e.get("request") or {}).get("postData") or {}
        text = post.get("text") or ""
        try:
            obj = json.loads(text)
            if isinstance(obj, dict):
                bodies.append(obj)
        except Exception:
            continue
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
            unique = []
            for s in vs:
                try:
                    unique.append(json.loads(s))
                except Exception:
                    unique.append(s)
            variations[k] = {"unique_values": unique, "count": len(vs)}
    return variations


def main():
    ap = argparse.ArgumentParser(description="HAR 解析 + eolinker 接口识别 + caseData 构造")
    ap.add_argument("har", help="HAR 文件路径")
    ap.add_argument("-o", "--output", help="输出 JSON 文件路径（默认打印到 stdout）")
    args = ap.parse_args()

    with open(args.har, "r", encoding="utf-8") as f:
        har = json.load(f)

    entries = (har.get("log") or {}).get("entries") or []
    # 过滤 XHR/Fetch + 业务接口（可按需扩充域名关键字）
    resource_types = {"xhr", "fetch"}
    filtered = []
    for e in entries:
        rt = (e.get("_resourceType") or "").lower()
        req = e.get("request") or {}
        url = req.get("url", "")
        if rt and rt not in resource_types:
            continue
        # 剔除静态资源
        if re.search(r"\.(js|css|png|jpg|jpeg|gif|svg|woff2?|ttf|ico|map)(\?|$)", url, re.I):
            continue
        filtered.append(e)

    # 按 method + url 分组（保留全部调用，用于参数化分析）
    grouped = {}
    order = []
    for e in filtered:
        req = e.get("request") or {}
        key = ((req.get("method") or "GET").upper() + " " + (req.get("url") or ""))
        if key not in grouped:
            order.append(key)
            grouped[key] = []
        grouped[key].append(e)

    candidates = []
    matched = {}
    notes = []

    for key in order:
        entries = grouped[key]
        e = entries[-1]  # 用最后一次调用作为样本
        case_data, method, url = build_case_data(e)
        body_summary = (case_data["raw"] or "")[:120]
        resp_text = get_response_text(e)
        variations = analyze_param_variations(entries)
        candidates.append({
            "method": method,
            "url": url,
            "body_summary": body_summary,
            "count": len(entries),
            "param_variations": variations,
            "has_response": resp_text is not None,
        })

        # 优先级匹配：已被占用的类别跳过
        for cat, pattern in RULES:
            if cat in matched:
                continue
            if pattern.search(url):
                matched[cat] = {
                    "api_name": API_NAME_MAP[cat],
                    "api_uri": to_env_url(url),
                    "case_data": case_data,
                    "param_variations": variations,
                    "response_sample": (resp_text or "")[:2000],
                }
                break

    if not all(c in matched for c in ("list", "date", "trend")):
        missing = [API_NAME_MAP[c] for c in ("date", "trend", "list") if c not in matched]
        notes.append("未匹配到接口：%s，请让用户从 candidates 中指认" % "、".join(missing))

    if any(not m["response_sample"] for m in matched.values()):
        notes.append("部分接口 HAR 无响应体，断言路径无法预判，走 SKILL.md Step 5 两阶段兜底（裸建→调试→删除→带断言重建）")

    result = {"candidates": candidates, "matched": matched, "notes": notes}
    out = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(out)
        print("已输出: %s" % args.output)
    else:
        print(out)


if __name__ == "__main__":
    sys.exit(main())
