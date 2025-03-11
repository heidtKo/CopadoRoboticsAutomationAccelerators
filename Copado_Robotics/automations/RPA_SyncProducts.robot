*** Settings ***
Documentation                   New test suite
Library                         QVision
Library                         QForce
Library                         QWeb
Library                         OperatingSystem
Library                         Collections
Library                         JSONLibrary
Resource                        ../resources/utility.resource    

Suite Setup                     Open Browser                about:blank                 chrome
Suite Teardown                  Close All Browsers

*** Variables ***
#sample variable values help during development
${input_string}                 {"promotionId": "a0tQH0000095aAaYAI", "totalFlows": 2, "flows": [{"type": "Flow", "apiName": "my_flow"}, {"type": "Flow", "apiName": "ctx_rule_1"}]}
${org_session_token}            00DDa000000AOwV!AQEAQAVjkpy4X4CCXLyTTNDYmUTuz74nlxrSE0j6QgWt7qJyC0CZwTueV4de8jfQTKX0QEi0VqOpNVWnMPDei8Eds4bDpjM_
${instance_url}                 https://copado51--s23g3dev1.sandbox.my.salesforce.com
${alias}                        automation_environment

*** Test Cases ***
Activate Flows In Deployment
    [Documentation]             In this case we are given a list of flows in a current Copado CICD promotion. The list is only API names, so we need to get the UI Labels of those flows first, using the Salesforce CLI. Afterwards, the automation continues in the UI.
    [Tags]                      poc
    ## Use API to get flow labels.
    #check cli version
    ${sf_version}=              sf cli version
    Log                         ${sf_version}
    ${sf_cli}=                  Evaluate                    """${sf_version}""".startswith("@salesforce/cli")
    IF                          ${sf_cli} == ${FALSE}
        Log                     No salesforce cli has been installed. abort
        Fatal Error
    END

    #Authenticate current org
    ${org_session_token_shell}=                             Catenate                    '                           ${org_session_token}    '
    ${auth_result}=             sf cli authenticate environment                         ${instance_url}             ${org_session_token_shell}    ${alias}
