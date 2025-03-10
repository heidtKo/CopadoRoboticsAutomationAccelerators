# CopadoRoboticsAutomationAccelerators
Sample logic to leverage automations.
Components include Copado CICD as well as Copado Robotics components.
This logis is intendet to speed up customizations by providing some important foundations, as well as sample automation cases.

## Key Enablers:
* pace before installs CLI
* Utility to authenticate an environment for the cli during automation execution
* Utility to query
* Utility to parse a json

## Sample Automations
### Activate All Flows in a promotion
* Dynamic Expression on the CICD side
* Automation Test Case on Robotics

#### How to Use it:
The Robotics automation is expecting the following input: 
* input_string: list of API names and types
* org_session_token: org session token
* instance_url: org instance URL

Steps:
This is only a high level guidance. For detailed steps check Copado Documentation, AI chatbots and Google/Bing
* Create a new Copado Robotics Test Job with this repo or copy paste the code into your existing Robotics Project
* Use Salesforce CLI to deploy the Salesforce Contents of this repo to your Copado CICD Org
* Connect Copado Robotics and your Copado CICD environment
* Create a Test Record in Copado CICD:
  * Reference your Robotics Project
  * Reference your Robotics Test Job (= Automation Job)
  * Set Variables to:
    * input_string = {$Context.Apex.Expression_FlowsInPromotion}
    * org_session_token = {$Destination.Credential.SessionId}
    * instance_url = {$Destination.Credential.EndpointURL}
* On a User Story, add a Deployment Step with the Type "Robotic Test" and select the Test record created previously. It can be before or after deployment, depending on your needs

