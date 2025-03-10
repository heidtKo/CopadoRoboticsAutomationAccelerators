/**
 * Created by kheidt on 2019-04-11.
 */

 public class CopadoTestUserService {

    public User getUser(Id userId){
        User thisUser = new User();
        thisUser = queryUser(userId);
        return thisUser;
    }

    public Profile getProfile(String profileName){
        Profile thisProfile = queryProfile(profileName);
        return thisProfile;
    }

    public List<User> getUsersBasedOnUserNames(Set<String> usernames){
        List<User> users = [
                SELECT
                        Id,
                        Name
                FROM     User
                WHERE    UserName IN :usernames
        ];
        return users;
    }

    public List<User> getUsersBasedOnGroupNames(List<String> groupNames){
        Set<Id> uniqueUserIds = new Set<Id>();
        
        // First get the groups
        List<Group> groups = [
            SELECT Id 
            FROM Group 
            WHERE DeveloperName IN :groupNames 
            OR Name IN :groupNames
        ];
        
        Set<Id> groupIds = new Map<Id, Group>(groups).keySet();
        
        if(groupIds.isEmpty()) {
            return new List<User>();
        }
        
        // Get the group members
        for(GroupMember gm : [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId IN :groupIds
            AND UserOrGroupId IN (SELECT Id FROM User WHERE IsActive = true)
        ]) {
            uniqueUserIds.add(gm.UserOrGroupId);
        }
        
        if(uniqueUserIds.isEmpty()) {
            return new List<User>();
        }
        
        List<User> usersInGroups = new List<User>([
            SELECT
                    Id,
                    Name,
                    UserName,
                    Email
            FROM User
            WHERE Id IN :uniqueUserIds
            AND IsActive = true
            ]);
        // Return the users
        return usersInGroups;
    }

    /** queries and more stuff **/
    private Profile queryProfile(String profileName){
        return [
                SELECT
                        Id,
                        Name
                FROM
                        Profile
                WHERE
                        Name = :profileName
                LIMIT
                        1
        ];
    }

    private User queryUser(Id userId){
        return [
                SELECT
                        Id,
                        Name
                FROM
                        User
                WHERE
                        Id = :userId
        ];
    }
}