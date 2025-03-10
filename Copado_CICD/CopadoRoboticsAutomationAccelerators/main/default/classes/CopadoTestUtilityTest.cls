@IsTest
private class CopadoTestUtilityTest {
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
        }
    }

    @IsTest
    static void testConstructor() {
        Test.startTest();
        CopadoTestUtility testUtil = new CopadoTestUtility();
        Test.stopTest();
        
        System.assertNotEquals(null, testUtil.copadoGlobalAPI, 'Global API should be initialized');
    }
    
    @IsTest
    static void testGetNumberOfAvailableEnterprise() {
        CopadoTestUtility testUtil = new CopadoTestUtility();
        testUtil.clic = new copado.GlobalAPI.CopadoLicenses();
        testUtil.clic.availableCopadoLicenses = 5;
        
        Test.startTest();
        Integer available = testUtil.getNumberOfAvailableEnterprise();
        Test.stopTest();
        
        System.assertEquals(5, available, 'Should return correct number of available licenses');
    }
    
    @IsTest
    static void testGetUsersWithEnterprise() {
        // Get the running user created in setup
        User runningUser = [SELECT Id FROM User WHERE Username = 'runningUser@copadoTestClass.com.test' LIMIT 1];
        
        Test.startTest();
        CopadoTestUtility testUtil = new CopadoTestUtility();
        List<copado.GlobalAPI.UserLicense> result = testUtil.getUsersWithEnterprise();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one user with enterprise license');
    }
    
    @IsTest
    static void testAssignLicenseForTestRun() {
        CopadoTestUtility testUtil = new CopadoTestUtility();
        testUtil.clic = new copado.GlobalAPI.CopadoLicenses();
        testUtil.clic.availableCopadoLicenses = 1;
        
        Test.startTest();
        testUtil.assignLicenseForTestRun(UserInfo.getUserId());
        Test.stopTest();
    }
    
    @IsTest
    static void testAddAndRemoveLicense() {
        CopadoTestUtility testUtil = new CopadoTestUtility();
        
        Test.startTest();
        copado.GlobalAPI.UserLicense addedLicense = testUtil.addLicenseToUser(UserInfo.getUserId(), 'enterprise');
        Boolean removed = testUtil.removeLicenseFromUser(UserInfo.getUserId());
        Test.stopTest();
        
        System.assertEquals(true, addedLicense.isCopadoEnabled, 'Enterprise license should be enabled');
    }
}
