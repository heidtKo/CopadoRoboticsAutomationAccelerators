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
${org_session_token}            00DDa000000AOwV!AQEAQCNr5eKoITY1Zu.mdkdrLiGvBTnIciERdfJenr0rDDNdu7LqeLrLXEN4rNVW.1Ski_CJa95cy.Q0A4OHOQ9J_.cCeb6K
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

    #Get Flow API names
    ${input_json}=              Evaluate                    json.loads('''${input_string}''')                       json
    ${flow_names}=              Create List
    FOR                         ${flow}                     IN                          @{input_json}[flows]
        Append To List          ${flow_names}               '"'"'${flow}[apiName]'"'"'
    END
    ${flow_names_quoted}=       Evaluate                    ",".join(${flow_names})

    #Query Flow Labels based on flow list
    ${query_string}=            Set Variable                SELECT Id, ApiName, Label FROM FlowDefinitionView WHERE ApiName IN (${flow_names_quoted})
    ${flows_json}=              sf cli query data           ${query_string}             ${alias}

    ${flows_enriched}=          Create List

    # Create dictionary of API names to labels and Ids. modify id's to be used later.
    FOR                         ${record}                   IN                          @{flows_json}[result][records]
        ${flow_details}=        Create Dictionary
        ${flow_id}=             Set Variable                ${record}[Id]
        ${modified_flow_id}=    Replace String              ${flow_id}                  3dd                         300
        Set To Dictionary       ${flow_details}             id                          ${flow_id}
        Set To Dictionary       ${flow_details}             modifiedId                  ${modified_flow_id}
        Set To Dictionary       ${flow_details}             label                       ${record}[Label]
        Set To Dictionary       ${flow_details}             apiName                     ${record}[ApiName]
        Append To List          ${flows_enriched}           ${flow_details}
    END

    Set To Dictionary           ${input_json}               flows                       ${flows_enriched}

    # Log the enriched JSON
    Log                         ${input_json}


    ## With the api names and labels of the flows in a structured list, time to navigate to the UI and Activate the last version of the flows
    # Login to Salesforce using the session id and redirect to the list of flows directly. Should save some hassle.
    # this step can be skipped, as we could navigate to the flows directly, but it doesn't add a lot of execution time, and helps to understand potential errors while not adding too much execution time
    # also, it makes later URLs less complicated.
    frontdoor login             ${instance_url}             ${org_session_token}
    Go To                       ${instance_url}/lightning/setup/Flows/home 
    Sleep                       5s           

    ## let's try the following approach which should limit the number of UI interactions and therefore the number of potential errors improving performance along the way
    # each flow has a detail page with a specific URL
    # url structure is: <loginURL>/lightning/setup/Flows/page?address=%2F<modifedFlowId> optional, add a return url: %3FretUrl%3D%2Flightning%2Fsetup%2FFlows%2Fhome
    # we already query the IDs in a step before, but we need to modify them. The queried IDs start with '3dd', yet we need to change them to start with '300'
    # while IDs in Salesforce are org specific, some objects will always start with the same prefix on all environments. Flows will always be 3dd/300, so that's safe.
    # with this URL hack we can directly navigate to the flow page and hit activate
    ${flow_setup_url}=          Set Variable                ${instance_url}/lightning/setup/Flows/page?address=%2F
    ${flow_setup_url_post}=     Set Variable                %3FretUrl%3D%2Flightning%2Fsetup%2FFlows%2Fhome

    # Validate base URLs before loop
    Log                         Flow Setup URL: ${flow_setup_url}
    Log                         Flow Setup Post URL: ${flow_setup_url_post}


    FOR                         ${flow}                     IN                          @{input_json}[flows]
        Log                     ${flow}
        ${modified_id}=         Set Variable                ${flow}[modifiedId]
        ${flow_detail_url}=     Catenate                    SEPARATOR=                  ${flow_setup_url}           ${modified_id}
        ${flow_detail_url}=     Remove String               ${flow_detail_url}          ${SPACE}
        Log                     ${flow_detail_url}
        Go To                   ${flow_detail_url}          timeout=2
        Sleep                   10s
        
        #just checking if we are on the correct page.
        QForce.VerifyText       Modified By


        Use Table               //table[@class\='list' and @id\='view:lists:versions']
        
        #check if "Deactivate" is visible on the page in general and if the first row does not have it.
        #activate first row and verify if it worked.
        #skip otherwise
        ${first_cell}=          GetCellText                 r1c1                        anchor=1
        ${first_row_not_active}=                            Evaluate                    'Activate' in '''${first_cell}'''
        ${deactivate_exists_on_page}=                       QWeb.IsText                     Deactivate

        IF                      ${deactivate_exists_on_page} and ${first_row_not_active}
            QWeb.ClickText           Activate                    anchor=Action
            Sleep               2s
            
            # Verify the action was successful
            ${new_status}=      GetCellText                 r1c1                        anchor=1
            ${contains_deactivate}=                         Evaluate                    'Deactivate' in '''${new_status}'''
            IF                  ${contains_deactivate}
                Log             Successfully activated the flow
            END
        ELSE
            Log                 No activation needed
        END
        Sleep                   2s
    END