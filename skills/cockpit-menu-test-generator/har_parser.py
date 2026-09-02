"""
HAR 文件预处理脚本

解决 HAR 文件过大无法一次性读取的问题。
过滤无关请求，提取关键信息，生成精简摘要。

用法：
    python har_parser.py <har文件路径> [--output <输出路径>]

输出：
    - <har文件名>_summary.json  精简摘要（供模型读取）
"""

import json
import sys
import os
from collections import defaultdict
from urllib.parse import urlparse


# === 过滤规则 ===

# 排除的文件扩展名
EXCLUDE_EXTENSIONS = {
    '.js', '.css', '.png', '.ico', '.svg', '.woff', '.woff2',
    '.ttf', '.eot', '.map', '.jpg', '.jpeg', '.gif', '.webp',
    '.mp4', '.mp3', '.zip', '.pdf'
}

# 排除的路径关键词
EXCLUDE_PATH_KEYWORDS = [
    'operationMonitor', 'health', 'actuator', 'favicon',
    'static/', 'assets/', 'public/', '__webpack',
    'hot-update', 'sockjs-node', 'webpack-dev-server'
]

# 只保留的请求方法
INCLUDE_METHODS = {'POST'}


def should_exclude(url: str, method: str) -> bool:
    """判断请求是否应被排除"""
    if method.upper() not in INCLUDE_METHODS:
        return True

    parsed = urlparse(url)
    path = parsed.path.lower()

    for ext in EXCLUDE_EXTENSIONS:
        if path.endswith(ext):
            return True

    for keyword in EXCLUDE_PATH_KEYWORDS:
        if keyword.lower() in path:
            return True

    return False


def extract_path(url: str) -> str:
    """从 URL 提取路径（去掉域名和查询参数）"""
    parsed = urlparse(url)
    return parsed.path


def extract_request_body(entry: dict) -> dict | None:
    """提取请求体"""
    request = entry.get('request', {})
    post_data = request.get('postData', {})
    text = post_data.get('text', '')
    if text:
        try:
            return json.loads(text)
        except (json.JSONDecodeError, TypeError):
            return {"_raw": text[:500]}
    return None


def extract_response_body(entry: dict) -> dict | None:
    """提取响应体（截断过长内容）"""
    response = entry.get('response', {})
    content = response.get('content', {})
    text = content.get('text', '')
    if text:
        try:
            data = json.loads(text)
            text_str = json.dumps(data, ensure_ascii=False)
            if len(text_str) > 2000:
                return {"_truncated": True, "_size": len(text_str), "_preview": text_str[:500]}
            return data
        except (json.JSONDecodeError, TypeError):
            return {"_raw": text[:500]}
    return None


def parse_har(har_path: str) -> dict:
    """解析 HAR 文件，返回精简摘要"""
    with open(har_path, 'r', encoding='utf-8') as f:
        har = json.load(f)

    pages = har.get('log', {}).get('pages', [])
    entries = har.get('log', {}).get('entries', [])

    page_title = ''
    if pages:
        page_title = pages[0].get('title', '')

    api_groups = defaultdict(lambda: {
        'method': '',
        'path': '',
        'calls': [],
    })

    filtered_count = 0
    total_count = len(entries)

    for entry in entries:
        request = entry.get('request', {})
        url = request.get('url', '')
        method = request.get('method', '')

        if should_exclude(url, method):
            filtered_count += 1
            continue

        path = extract_path(url)
        req_body = extract_request_body(entry)
        resp_body = extract_response_body(entry)

        group = api_groups[path]
        group['method'] = method
        group['path'] = path
        group['calls'].append({
            'request': req_body,
            'response': resp_body,
        })

    apis = []
    for path, group in api_groups.items():
        param_variations = analyze_param_variations(group['calls'])

        apis.append({
            'path': group['path'],
            'method': group['method'],
            'call_count': len(group['calls']),
            'param_variations': param_variations,
            'sample_request': group['calls'][0]['request'] if group['calls'] else None,
            'sample_response': group['calls'][0]['response'] if group['calls'] else None,
        })

    apis.sort(key=lambda x: x['call_count'], reverse=True)

    return {
        'page_title': page_title,
        'total_requests': total_count,
        'filtered_requests': filtered_count,
        'kept_requests': total_count - filtered_count,
        'api_count': len(apis),
        'apis': apis,
    }


def analyze_param_variations(calls: list) -> dict:
    """分析多次调用的参数差异，识别需要参数化的字段

    规则：同一接口的相同参数，取值不同 → 需要参数化
    """
    if len(calls) <= 1:
        return {}

    bodies = [c['request'] for c in calls if c['request']]
    if not bodies:
        return {}

    all_keys = set()
    for body in bodies:
        if isinstance(body, dict):
            all_keys.update(body.keys())

    variations = {}
    for key in all_keys:
        values = []
        for body in bodies:
            if isinstance(body, dict) and key in body:
                val = body[key]
                if not isinstance(val, (dict, list)):
                    values.append(str(val))

        unique_values = list(dict.fromkeys(values))
        if len(unique_values) > 1:
            variations[key] = {
                'unique_values': unique_values,
                'count': len(unique_values),
            }

    return variations


def main():
    if len(sys.argv) < 2:
        print("用法: python har_parser.py <har文件路径> [--output <输出路径>]")
        sys.exit(1)

    har_path = sys.argv[1]

    if '--output' in sys.argv:
        idx = sys.argv.index('--output')
        output_path = sys.argv[idx + 1]
    else:
        base = os.path.splitext(har_path)[0]
        output_path = f"{base}_summary.json"

    if not os.path.exists(har_path):
        print(f"错误: 文件不存在 - {har_path}")
        sys.exit(1)

    print(f"正在解析 HAR 文件: {har_path}")
    summary = parse_har(har_path)

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    print(f"\n=== 解析完成 ===")
    print(f"总请求数: {summary['total_requests']}")
    print(f"已过滤: {summary['filtered_requests']}")
    print(f"保留: {summary['kept_requests']}")
    print(f"接口数: {summary['api_count']}")
    print(f"\n接口列表:")
    for i, api in enumerate(summary['apis'], 1):
        vars_parts = []
        for k, v in api['param_variations'].items():
            vals = '/'.join(v['unique_values'])
            vars_parts.append(f"{k}[{vals}]")
        vars_str = ', '.join(vars_parts) if vars_parts else '无变化'
        print(f"  {i}. [{api['method']}] {api['path']} (调用{api['call_count']}次)")
        print(f"     参数变化: {vars_str}")

    print(f"\n摘要已保存到: {output_path}")
    print(f"文件大小: {os.path.getsize(output_path) / 1024:.1f} KB")


if __name__ == '__main__':
    main()
