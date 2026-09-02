"""
驾驶舱-{{menu_name_cn}}菜单 - 获取日期接口

模板占位符说明：
- {{menu_name_cn}}: 菜单中文名（Allure feature），例如 "仲裁时效"
- {{ClassName}}: 类名前缀（PascalCase），例如 "ArbitrationAging"
- {{menu_name_en}}: 菜单英文名（目录名），例如 "arbitration_aging"
- {{date_api_path}}: 日期接口地址，例如 "/api-expj/expj/latestDateController/queryDateByType"
- {{date_request_body}}: 日期接口请求体（Python字典格式）
"""
import sys
import os
import pytest
from datetime import datetime
import allure

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))

from httprunner import HttpRunner, Config, Step, RunRequest, Parameters
from debugtalk import allure_report_steps


class Test{{ClassName}}Date(HttpRunner):
    case_id = f"{datetime.now().strftime('%m%d%H%M')}_{{menu_name_en}}_date"

    @allure.feature("{{menu_name_cn}}")
    @allure.story("日期接口校验")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.title("{param[caseName]}")
    @allure.description("验证{{menu_name_cn}}日期接口返回日期是否符合预期，日维度返回T-1，月维度返回当月1日")
    @pytest.mark.parametrize(
        "param",
        Parameters({"caseName-sumType": "${parameterize(testcases/cockpit/{{menu_name_en}}/{{menu_name_en}}_date_params.csv)}"})
    )
    def test_start(self, param):
        allure_report_steps(self, param)

    config = (
        Config("驾驶舱-{{menu_name_cn}}-日期接口")
        .base_url("https://jscapp.yto56.com.cn:18080")
        .variables(**{
            "token": "${get_token()}",
            "tableType": "{{tableType}}",
            "queryFlag": "new",
            "userOrgCode": "999999",
            "userOrgType": "HEAD",
            "expected_date": "${get_expected_date($sumType)}"
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
            .assert_equal("body.data.object2json.date", "$expected_date")
        ),
    ]
