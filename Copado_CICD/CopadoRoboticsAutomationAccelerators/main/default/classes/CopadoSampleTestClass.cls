@IsTest
private class CopadoSampleTestClass {
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

            // Assign package licenses
            Database.insert(
                ctps.assignPackagesToUsers(new Set<Id>{runningUser.Id}, packageLicenses.keySet(),null)
            );

            // Assign permission sets
            Database.insert(
                ctps.assignPermissionSetsToUsers(new Set<Id>{runningUser.Id},permSets.keySet(),null)
            );

            // Assign Copado License
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

                // Create Git Repository
                copado__Git_Repository__c repo = CopadoTestDataFactory.createGitRepo();
                insert repo;

                // Create Git Backup
                copado__Git_Backup__c snapshot = CopadoTestDataFactory.createGitSnapshot(sourceOrgCredential, repo, 'dev1');
                insert snapshot;

                // Create Deployment Flow
                copado__Deployment_Flow__c flow = CopadoTestDataFactory.createDeploymentFlow(repo);
                flow.copado__Active__c = false;
                insert flow;
                flow.copado__Active__c = true;
                update flow;

                // Create Deployment Flow Step
                copado__Deployment_Flow_Step__c dfs = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id, sourceEnv.Id, targetEnv.Id);
                insert dfs;

                // Create Project
                copado__Project__c project = CopadoTestDataFactory.createProject(flow);
                if(CopadoTestDataFactory.hasCopadoIntegration) {
                    SObject setting = CopadoTestDataFactory.createIntegrationSetting();
                    Database.insertImmediate(setting);
                    project = CopadoTestDataFactory.addIntegrationSetting(project, (String) setting.Id);
                }
                insert project;



                
                // Create Snapshot Commit and User Story Commit
                
            }
        }
    }
    
    @IsTest
    static void testMyCopadoRelatedLogic() {
        User runningUser = [SELECT Id FROM User WHERE Username LIKE 'runningUser%' LIMIT 1];
        
        System.runAs(runningUser) {
            
            //get relevant elements
            copado__Org__c sourceCredential = [SELECT Id, Name FROM copado__Org__c WHERE Name = 'sourceCred' LIMIT 1];
            copado__Org__c targetCredential = [SELECT Id, Name FROM copado__Org__c WHERE Name = 'targetCred' LIMIT 1];
            
            copado__Environment__c sourceEnvironment = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'Source'];
            copado__Environment__c targetEnvironment = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'Target'];
            
            copado__Project__c project = [SELECT Id, Name FROM copado__Project__c LIMIT 1];

            copado__Git_Repository__c repo = [SELECT Id, Name FROM copado__Git_Repository__c LIMIT 1];
            copado__Git_Backup__c snapshot = [SELECT Id, Name FROM copado__Git_Backup__c WHERE copado__Branch__c = 'dev1' LIMIT 1];
            
            Test.startTest();
            System.debug('startLogic');
            //Create commit related objects
            // Create User Story and related records
            copado__User_Story__c userStory = CopadoTestDataFactory.createUserStory(project, sourceEnvironment, sourceCredential);
            insert userStory;
            
            List<copado__User_Story_Metadata__c> usmList = CopadoTestDataFactory.createSampleMetadataForStory(userStory.Id);
            insert usmList;
            
            copado__Git_Org_Commit__c snapshotCommit = CopadoTestDataFactory.createSnapshotCommit(sourceCredential, snapshot, 'Complete');
            insert snapshotCommit;
            
            copado__User_Story_Commit__c usc = CopadoTestDataFactory.createUserStoryCommit(userStory, snapshotCommit);
            insert usc;
            //create promotion related objects

            copado__Promotion__c promotion = CopadoTestDataFactory.createForwardPromotion(project.Id, sourceEnvironment.Id, targetEnvironment.Id);
            insert promotion;

            List<copado__Promoted_User_Story__c> pus = CopadoTestDataFactory.createPromotedUserStories(promotion.Id, new Set<Id>{userStory.Id});
            insert pus;

            Test.stopTest();

            List<copado__Promoted_User_Story__c> promotedUserStories = [SELECT Id, Name, copado__User_Story__c, copado__Promotion__c FROM copado__Promoted_User_Story__c];
            
            System.assertNotEquals(0, promotedUserStories.size(), 'No Promoted User Stories created');
        }
    }
}