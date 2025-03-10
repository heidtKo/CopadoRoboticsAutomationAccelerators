@IsTest
private class CopadoTestUserServiceTest {
    @IsTest
    static void testGetUser() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Username = 'testuser@copadotest.com',
            Alias = 'tuser',
            Email = 'testuser@copadotest.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Test.startTest();
        CopadoTestUserService userService = new CopadoTestUserService();
        User retrievedUser = userService.getUser(testUser.Id);
        Test.stopTest();
        
        System.assertEquals(testUser.Id, retrievedUser.Id, 'User IDs should match');
    }
    
    @IsTest
    static void testGetProfile() {
        Test.startTest();
        CopadoTestUserService userService = new CopadoTestUserService();
        Profile retrievedProfile = userService.getProfile('Standard User');
        Test.stopTest();
        
        System.assertNotEquals(null, retrievedProfile, 'Profile should not be null');
        System.assertEquals('Standard User', retrievedProfile.Name, 'Profile names should match');
    }
    
    @IsTest
    static void testGetUsersBasedOnUserNames() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Username = 'testuser2@copadotest.com',
            Alias = 'tuser2',
            Email = 'testuser2@copadotest.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Test.startTest();
        CopadoTestUserService userService = new CopadoTestUserService();
        Set<String> usernames = new Set<String>{testUser.Username};
        List<User> retrievedUsers = userService.getUsersBasedOnUserNames(usernames);
        Test.stopTest();
        
        System.assertEquals(1, retrievedUsers.size(), 'Should retrieve one user');
        System.assertEquals(testUser.Id, retrievedUsers[0].Id, 'User IDs should match');
    }
    
    @IsTest
    static void testGetUsersBasedOnGroupNames() {
        // Create test group
        Group testGroup = new Group(
            Name = 'TestGroup',
            DeveloperName = 'TestGroup'
        );
        insert testGroup;
        
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Username = 'testuser3@copadotest.com',
            Alias = 'tuser3',
            Email = 'testuser3@copadotest.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        // Add user to group
        GroupMember gm = new GroupMember(
            GroupId = testGroup.Id,
            UserOrGroupId = testUser.Id
        );
        insert gm;
        
        Test.startTest();
        CopadoTestUserService userService = new CopadoTestUserService();
        List<String> groupNames = new List<String>{'TestGroup'};
        List<User> retrievedUsers = userService.getUsersBasedOnGroupNames(groupNames);
        Test.stopTest();
        
        System.assertEquals(1, retrievedUsers.size(), 'Should retrieve one user');
    }
}
