*** Settings ***
Documentation                 keywords used for automations
Library                       QForce
Library                       QVision
Library                       String
Library                       Collections
Library                       OperatingSystem
Library                       JSONLibrary

*** Keywords ***
sf cli version
    [Documentation]           Simple command to verify if the cli is installed and which version
    ${result_string}          Run                         sf --version
    RETURN                    ${result_string}

sf cli authenticate environment
    [Documentation]           Authenticates the local salesforce cli for the target environment. This extra step will enable CLI and UI usage during execution.
    [Arguments]               ${instance_url}             ${token}                    ${alias}
    #auth first
    ${auth_command}=          Set Variable                SF_ACCESS_TOKEN=${token} sf org login access-token --no-prompt --instance-url ${instance_url} --alias ${alias} --json
    ${cli_result}=            Run                         ${auth_command}
    Log                       ${cli_result}
    ${cli_result}=            Run                         sf org list --json
    Log                       ${cli_result}

    #it's annoying to check the command and json outcome, so we will use org display to verify if the org is connected
    ${org_details_string}=    Run                         sf org display --target-org ${alias} --json
    ${org_details_json}=      json sf cli response string to dict                     ${org_details_string}

    ${result_status}=         Set Variable                ${org_details_json["status"]}
    IF                        "${result_status}" != "0"
        Log                   Command failed. Message: ${org_details_json["message"]}                             level=WARN
        Fatal Error           Connection verification failed.
    ELSE
        ${connected_status}=                              Set Variable                ${org_details_json["result"]["connectedStatus"]}
        Log                   Connection Status: ${connected_status}

        IF                    "${connected_status}" != "Connected"
            Log               Connection status is not "Connected". Current status: ${connected_status}           level=WARN
            Fatal Error       Connection verification failed. Status: ${connected_status}
        END
    END
    RETURN                    ${connected_status}

sf cli query data
    [Documentation]           Executes a SOQL query against the currently authenticated environment.
    [Arguments]               ${query_string}             ${org_alias}
    ${query_result}=          Run                         sf data query --query '${query_string}' --json --target-org ${org_alias}
    ${query_json}=            json sf cli response string to dict                     ${query_result}
    RETURN                    ${query_json}

json sf cli response string to dict
    [Documentation]           Helper method to handle CLI responses. Not fully reliable yet, use with caution
    [Arguments]               ${JSON_STRING}
    ${JSON_STRING} =          Replace String              ${JSON_STRING}              \\n                         \\\\n
    ${JSON_STRING}            Set Variable                { ${JSON_STRING.split('{', 1)[1].rsplit('}', 1)[0]}}
    ${JSON_DICT} =            Evaluate                    json.loads('''${JSON_STRING}''', strict=${FALSE})
    RETURN                    ${JSON_DICT}

frontdoor login
    [Documentation]           Constructs a frontdoor url, which is used to log into your salesforce environment without 2FA.
    ...                       Can be tweaked to accept dedicated target URLs to specific tabs
    [Arguments]               ${base_url}                 ${token}
    ${frontdoor_url}=         Catenate                    ${base_url}                 /secur/frontdoor.jsp?sid=               ${token}
    ${frontdoor_url}=         Remove String               ${frontdoor_url}            ${SPACE}
    #Log                       ${frontdoor_url}           #use during development. remove line once all works. this will print the URL with a session token.
    Go To                     ${frontdoor_url}            timeout=2
    Sleep                     3s                         #just in case. remove if not needed
    RETURN                    ${frontdoor_url}
