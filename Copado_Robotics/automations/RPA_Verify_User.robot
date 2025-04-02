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
