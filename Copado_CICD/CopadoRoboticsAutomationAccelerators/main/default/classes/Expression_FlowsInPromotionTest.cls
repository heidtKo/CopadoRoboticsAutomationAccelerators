@IsTest
private class Expression_FlowsInPromotionTest {
    private static CopadoTestUtility ctu;
    private static CopadoTestUserService ctus;
    private static CopadoTestPermissionService ctps;

    @TestSetup
    static void makeData() {
        System.debug('Start Test Class Setup');
        ctu = new CopadoTestUtility();
        ctus = new CopadoTestUserService();
        ctps = new CopadoTestPermissionService();
        CopadoTestDataFactory.ctus = ctus;

        // Create Admin User
        User adminUser = CopadoTestDataFactory.createAdminUser();
        insert adminUser;

        System.runAs(adminUser) {
            // Create Running User
            User runningUser = CopadoTestDataFactory.createStandardUser();
            runningUser.ProfileId = adminUser.ProfileId;
            runningUser.Username = 'runningUser@copadoTestClass.com.test';
            insert runningUser;

            // Get Licenses & PermSets
            Map<Id,PermissionSet> permSets = ctps.getAllCopadoPermissionSets();
            Map<Id,PackageLicense> packageLicenses = ctps.getCopadoPackageLicenses();

            // Assign package licenses and permission sets
            Database.insert(ctps.assignPackagesToUsers(new Set<Id>{runningUser.Id}, packageLicenses.keySet(),null));
            Database.insert(ctps.assignPermissionSetsToUsers(new Set<Id>{runningUser.Id},permSets.keySet(),null));
            ctu.assignLicenseForTestRun(runningUser.Id);

            System.runAs(runningUser) {
                // Create Environments
                String currentOrgId = UserInfo.getOrganizationId();
                copado__Environment__c sourceEnv = CopadoTestDataFactory.createEnvironment('Source', '');
                copado__Environment__c targetEnv = CopadoTestDataFactory.createEnvironment('Target', '');
                insert new List<copado__Environment__c>{sourceEnv, targetEnv};

                // Create Credentials
                copado__Org__c sourceOrgCredential = CopadoTestDataFactory.createOrgCredential(sourceEnv, currentOrgId.left(15) + 'ABC');
                sourceOrgCredential.Name = 'sourceCred';
                copado__Org__c targetOrgCredential = CopadoTestDataFactory.createOrgCredential(targetEnv, currentOrgId.left(15) + 'DEF');
                targetOrgCredential.Name = 'targetCred';
                insert new List<copado__Org__c>{sourceOrgCredential, targetOrgCredential};

                // Create Git Repository and Flow
                copado__Git_Repository__c repo = CopadoTestDataFactory.createGitRepo();
                insert repo;
                
                copado__Deployment_Flow__c flow = CopadoTestDataFactory.createDeploymentFlow(repo);
                insert flow;

                // Create Deployment Flow Steps (Pipeline Connection)
                copado__Deployment_Flow_Step__c dfs = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id, sourceEnv.Id, targetEnv.Id);
                insert dfs;

                // Activate the flow after creating steps
                flow.copado__Active__c = true;
                update flow;

                // Create Project
                copado__Project__c project = CopadoTestDataFactory.createProject(flow);
                insert project;
            }
        }
    }

    @IsTest
    static void testGetFlowsInPromotion() {
        User runningUser = [SELECT Id FROM User WHERE Username LIKE 'runningUser%' LIMIT 1];
        
        System.runAs(runningUser) {
            // Get test data
            copado__Org__c sourceCredential = [SELECT Id FROM copado__Org__c WHERE Name = 'sourceCred' LIMIT 1];
            copado__Environment__c sourceEnvironment = [SELECT Id FROM copado__Environment__c WHERE Name = 'Source'];
            copado__Project__c project = [SELECT Id FROM copado__Project__c LIMIT 1];

            Test.startTest();

            // Create User Story with Flow metadata
            copado__User_Story__c userStory = CopadoTestDataFactory.createUserStory(project, sourceEnvironment, sourceCredential);
            insert userStory;

            // Create Flow metadata records
            List<copado__User_Story_Metadata__c> flowMetadata = new List<copado__User_Story_Metadata__c>{
                CopadoTestDataFactory.createUserStoryMetadata(userStory.Id, 'Flow', 'Test_Flow_1', null, 'Add', null),
                CopadoTestDataFactory.createUserStoryMetadata(userStory.Id, 'Flow', 'Test_Flow_2', null, 'Add', null)
            };
            insert flowMetadata;

            // Create Promotion
            copado__Promotion__c promotion = CopadoTestDataFactory.createForwardPromotion(
                project.Id, 
                sourceEnvironment.Id, 
                [SELECT Id FROM copado__Environment__c WHERE Name = 'Target'].Id
            );
            insert promotion;

            // Create Promoted User Story
            copado__Promoted_User_Story__c pus = new copado__Promoted_User_Story__c(
                copado__User_Story__c = userStory.Id,
                copado__Promotion__c = promotion.Id
            );
            insert pus;

            // Create Job Step
            copado__JobStep__c jobStep = CopadoTestDataFactory.createJobStep(promotion.Id);
            insert jobStep;

            // Execute Expression
            Expression_FlowsInPromotion expr = new Expression_FlowsInPromotion();
            String result = expr.execute(jobStep.Id);

            Test.stopTest();

            // Verify results
            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
            System.assertEquals(2, (Integer)resultMap.get('totalFlows'), 'Expected 2 flows in the result');
            
            List<Object> flows = (List<Object>)resultMap.get('flows');
            System.assertNotEquals(null, flows, 'Flows list should not be null');
            System.assertEquals(2, flows.size(), 'Should have 2 flow records');
        }
    }
    @IsTest
    static void testEmptyJsonField() {
        User runningUser = [SELECT Id FROM User WHERE Username LIKE 'runningUser%' LIMIT 1];
        
        System.runAs(runningUser) {
            // Create Job Step with empty JSON
            copado__JobExecution__c jobExecution = new copado__JobExecution__c(
                copado__DataJson__c = null  // Empty JSON field
            );
            insert jobExecution;
            
            copado__JobStep__c jobStep = new copado__JobStep__c(
                copado__JobExecution__c = jobExecution.Id,
                Name = 'Test Job Step Empty JSON',
                copado__Type__c = 'Flow'
            );
            insert jobStep;

            Test.startTest();
            Expression_FlowsInPromotion expr = new Expression_FlowsInPromotion();
            String result = expr.execute(jobStep.Id);
            Test.stopTest();

            // Verify error response
            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
            System.assertNotEquals(null, resultMap.get('error'), 'Should return error message for empty JSON');
            System.assertEquals(jobStep.Id, resultMap.get('contextId'), 'Context ID should match input JobStep ID');
        }
    }

    @IsTest
    static void testErrorScenarios() {
        Test.startTest();
        
        // Test with null ID
        Expression_FlowsInPromotion expr = new Expression_FlowsInPromotion();
        String nullIdResult = expr.execute(null);
        
        // Test with invalid ID
        String invalidId = '00P000000000000'; // Invalid ID format
        String invalidIdResult = expr.execute(invalidId);
        
        // Test with non-existent ID
        Id nonExistentId = '00P000000000001'; // Valid ID format but doesn't exist
        String nonExistentResult = expr.execute(nonExistentId);
        
        Test.stopTest();

        // Verify null ID result
        Map<String, Object> nullIdMap = (Map<String, Object>)JSON.deserializeUntyped(nullIdResult);
        System.assertNotEquals(null, nullIdMap.get('error'), 'Should return error message for null ID');
        
        // Verify invalid ID result
        Map<String, Object> invalidIdMap = (Map<String, Object>)JSON.deserializeUntyped(invalidIdResult);
        System.assertNotEquals(null, invalidIdMap.get('error'), 'Should return error message for invalid ID');
        System.assertNotEquals(null, invalidIdMap.get('lineNumber'), 'Should include line number in error');
        
        // Verify non-existent ID result
        Map<String, Object> nonExistentMap = (Map<String, Object>)JSON.deserializeUntyped(nonExistentResult);
        System.assertNotEquals(null, nonExistentMap.get('error'), 'Should return error message for non-existent ID');
        System.assertNotEquals(null, nonExistentMap.get('stack'), 'Should include stack trace in error');
    }
}
