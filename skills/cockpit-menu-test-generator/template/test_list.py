"""
驾驶舱-{{menu_name_cn}}菜单 - 明细列表接口

模板占位符说明：
- {{menu_name_cn}}: 菜单中文名（Allure feature），例如 "仲裁时效"
- {{menu_name_en}}: 菜单英文名（目录名），例如 "arbitration_aging"
- {{ClassName}}: 类名前缀（PascalCase），例如 "ArbitrationAging"
- {{parametrize_keys}}: 参数化字段列表，例如 "caseName-sumType-queryType-firstTabType"
- {{list_api_path}}: 明细列表接口地址，例如 "/api-cntj/cntj/leaderAssistant/quality/list"
- {{list_request_body}}: 明细列表接口请求体（Python字典格式）
- {{assert_field}}: 断言字段，例如 "orgName"
- {{metrics_field}}: 指标字段列表，例如 ["problemNum"]
"""
import sys
import os
import pytest
from datetime import datetime
import allure

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))

from httprunner import HttpRunner, Config, Step, RunRequest, RunTestCase, Parameters
from testcases.cockpit.{{menu_name_en}}.api_{{menu_name_en}}_date import Api{{ClassName}}Date
from debugtalk import allure_report_steps


class Test{{ClassName}}List(HttpRunner):
    case_id = f"{datetime.now().strftime('%m%d%H%M')}_{{menu_name_en}}_list"

    @allure.feature("{{menu_name_cn}}")
    @allure.story("明细列表数据质量校验")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.title("{param[caseName]}")
    @allure.description("验证{{menu_name_cn}}明细列表接口数据质量，包括日期获取、orgName唯一性校验、指标汇总校验")
    @pytest.mark.parametrize(
        "param",
        Parameters({"{{parametrize_keys}}": "${parameterize(testcases/cockpit/{{menu_name_en}}/{{menu_name_en}}_list_params.csv)}"})
    )
    def test_start(self, param):
        allure_report_steps(self, param)

    config = (
        Config("驾驶舱-{{menu_name_cn}}-明细列表")
        .base_url("https://jscapp.yto56.com.cn:18080")
        .variables(**{
            "token": "${get_token()}",
            "orgCode": "999999",
            "orgName": "国内事业部",
            "orgType": "REGION_MANAGE",
            "dataType": "HEAD",
            "userOrgCode": "999999",
            "userOrgType": "HEAD",
            "assert_field": "{{assert_field}}",
            "metrics_field": {{metrics_field}}
        })
    )

    teststeps = [
        Step(
            RunTestCase("获取{{menu_name_cn}}最新日期")
            .with_variables(**{"sumType": "$sumType"})
            .call(Api{{ClassName}}Date)
            .export("actual_date")
        ),
        Step(
            RunRequest("获取{{menu_name_cn}}明细列表数据")
            .with_retry(3, 2)
            .post("{{list_api_path}}")
            .with_headers(**{
                "Content-Type": "application/json;charset=UTF-8",
                "token": "$token"
            })
            .with_json({{list_request_body}})
            .extract()
            .with_jmespath("body.data.object2json.tbody", "tbody")
            .validate()
            .assert_equal("status_code", 200, "响应状态码应为200")
            .assert_equal("${check_org_unique($tbody, $assert_field)}", True, "orgName存在重复")
            .assert_equal("${check_global_sum($tbody, $assert_field, $metrics_field)}", True, "全国指标不等于省区合计")
        )
    ]
