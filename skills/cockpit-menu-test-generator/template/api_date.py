"""
驾驶舱-{{menu_name_cn}}菜单 - 公共日期接口（无业务断言）

模板占位符说明：
- {{menu_name_cn}}: 菜单中文名（Allure feature），例如 "仲裁时效"
- {{ClassName}}: 类名前缀（PascalCase），例如 "ArbitrationAging"
- {{menu_name_en}}: 菜单英文名（目录名），例如 "arbitration_aging"
- {{date_api_path}}: 日期接口地址，例如 "/api-expj/expj/latestDateController/queryDateByType"
- {{date_request_body}}: 日期接口请求体（Python字典格式）
"""
import sys
import os
from datetime import datetime

# 添加项目根目录到Python搜索路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))

from httprunner import HttpRunner, Config, Step, RunRequest


class Api{{ClassName}}Date(HttpRunner):
    case_id = f"{datetime.now().strftime('%m%d%H%M')}_api_{{menu_name_en}}_date"

    config = (
        Config("驾驶舱-{{menu_name_cn}}-公共日期接口")
        .base_url("https://jscapp.yto56.com.cn:18080")
        .variables(**{
            "token": "${get_token()}",
            "tableType": "{{tableType}}",
            "sumType": "D",
            "queryFlag": "new",
            "userOrgCode": "999999",
            "userOrgType": "HEAD"
        })
        .export("actual_date")
    )

    teststeps = [
        Step(
            RunRequest("获取{{menu_name_cn}}最新日期")
            .with_retry(3, 2)
            .post("{{date_api_path}}")
            .with_headers(**{
                "Content-Type": "application/json;charset=UTF-8",
                "token": "$token"
            })
            .with_json({{date_request_body}})
            .extract()
            .with_jmespath("body.data.object2json.date", "actual_date")
            .validate()
            .assert_equal("status_code", 200)
        ),
    ]
