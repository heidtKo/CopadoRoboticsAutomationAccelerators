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
${org_session_token}            00DDa000000AOwV!AQEAQKjHDfpTlurnnx7KSzT4Rj2GqjAFO8LH5blrhrb25a83NUVXcP..j.mkBnIS10n8BMDSPUfUiPwCNTR62Y88ZEqeHT9j
${instance_url}                 https://copado51--s23g3dev1.sandbox.my.salesforce.com
${alias}                        automation_environment

*** Test Cases ***
Verify User
    [Documentation]             In this case we are given a list of flows in a current Copado CICD promotion. The list is only API names, so we need to get the UI Labels of those flows first, using the Salesforce CLI. Afterwards, the automation continues in the UI.
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
    ${flow_redirect}=           Set Variable                &retURL=/lightning/setup/SetupOneHome/home
    ${start_url}=               Catenate                    ${frontdoor_url}            ${flow_redirect}
    ${start_url}=               Remove String               ${start_url}                ${SPACE}
    Log                         ${frontdoor_url}
    Log                         ${flow_redirect}
    Go To                       ${start_url}                timeout=2
    Sleep                       5s
    

    ClickText    View profile
    ClickText    Settings
    ClickText    kheidt+pre_s23-fm46@force.com.s23g3dev1    anchor=\nUsername

