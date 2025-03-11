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
${org_session_token}            00DS8000007THfo!AQEAQBWF8ZWcDqC5R1lXhhZ_GhhS3wlOW9ABQQs3s276RcvVvfWd5C4fajEzglnBm2tbUvnGI4Feztz3ocEZh_g0h56aXuZ5
${instance_url}                 https://rlmdemo1--rlmdev1.sandbox.my.salesforce.com
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

    #Log in
    ${frontdoor_url}=           Catenate                    ${instance_url}             /secur/frontdoor.jsp?sid=                           ${org_session_token}
    ${flow_redirect}=           Set Variable                &retURL=/lightning/setup/Flows/home
    ${start_url}=               Catenate                    ${frontdoor_url}            ${flow_redirect}
    ${start_url}=               Remove String               ${start_url}                ${SPACE}
    Log                         ${frontdoor_url}
    Log                         ${flow_redirect}
    Go To                       ${start_url}                timeout=2
    Sleep                       5s

    Go To                       ${instance_url}/lightning/setup/CorePricingSetup/home
    Sleep                       5s
    Click Element               xpath=//button[contains(@class, 'slds-button_neutral') and contains(text(), 'Sync')]               
    Click Text    Confirm
