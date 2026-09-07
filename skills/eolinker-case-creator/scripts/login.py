#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eolinker-case-creator Step 1：登录拿 JWT 鉴权信息

用法：
    python login.py [输出.json]
默认输出 session.json：{"jwt": ..., "uvId": ..., "userId": ...}
后续所有 /index.php/... 请求统一携带：
    Authorization: <jwt>
    Pragma: no-cache
    Cookie: uvId=<uvId>
"""
import json
import ssl
import sys
import uuid
import urllib.request

BASE = "http://eolinker-tst-inter.yto.net.cn"
LOGIN_PATH = "/userCenter/common/sso/login"

LOGIN_BODY = {
    "keepLogin": 1,
    "username": "02004619",
    "type": 1,
    "password": "MAksLAvvCZ7M1fxSaTQtzg==",
    "client": 0,
    "appType": 0,
}

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE


def login(uvid=None):
    uvid = uvid or str(uuid.uuid4())
    body = json.dumps(LOGIN_BODY).encode("utf-8")
    req = urllib.request.Request(BASE + LOGIN_PATH, data=body, method="POST")
    req.add_header("content-type", "application/json")
    req.add_header("Accept", "application/json, text/plain, */*")
    req.add_header("Pragma", "no-cache")
    req.add_header("Origin", BASE)
    req.add_header("Referer", BASE + "/independent/login")
    req.add_header("Cookie", "uvId=" + uvid)
    with urllib.request.urlopen(req, timeout=30, context=CTX) as resp:
        raw = resp.read().decode("utf-8", "replace")
    data = json.loads(raw)
    if not data.get("success"):
        raise RuntimeError("登录失败: " + raw[:300])
    jwt = data["data"]["jwt"]
    session = {
        "jwt": jwt,
        "uvId": uvid,
        "userId": data["data"].get("userId"),
        "base": BASE,
    }
    return session


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "session.json"
    session = login()
    with open(out, "w", encoding="utf-8") as f:
        json.dump(session, f, ensure_ascii=False, indent=2)
    print("登录成功 userId=%s，jwt 前 20 位：%s..." % (session["userId"], session["jwt"][:20]))
    print("已写入", out)


if __name__ == "__main__":
    main()
