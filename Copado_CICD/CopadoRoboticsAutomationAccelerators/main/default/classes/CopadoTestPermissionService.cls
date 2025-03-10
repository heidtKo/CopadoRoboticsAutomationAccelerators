public with sharing class CopadoTestPermissionService {
    public Set<String> copadoNameSpaceList = new Set<String>{
        'copado', 'cmcSf','copadoQuality','copadoconnect'
    };

    public Set<String> permissionSetsToSkip = new Set<String>{
        'Encrypted_fields','Persona_Permission_Manager'
    };

    public Map<Id,PermissionSet> getAllCopadoPermissionSets(){
        Map<Id,PermissionSet> permSetMap = new Map<Id,PermissionSet>();
        this.getSpecificCopadoPermissionSets(this.copadoNameSpaceList);
        return permSetMap;
    }

    public Map<Id,PermissionSet> getSpecificCopadoPermissionSets(Set<String> nameSpaces){
        Map<Id,PermissionSet> permSetMap = new Map<Id,PermissionSet>(
            [SELECT 
                Id, Name, Label, ProfileId, LicenseId, IsCustom, NamespacePrefix 
            FROM PermissionSet 
            WHERE NamespacePrefix IN :nameSpaces 
            AND Name NOT IN :this.permissionSetsToSkip
        ]);
        return permSetMap;
    }

    public Map<Id,PackageLicense> getCopadoPackageLicenses(){
        return this.getPackageLicenses(this.copadoNameSpaceList);
    }

    public Map<Id,PackageLicense> getPackageLicenses(Set<String> nameSpaces){
        Map<Id,PackageLicense> plMap = new Map<Id,PackageLicense>([
            SELECT Id,Status,UsedLicenses, AllowedLicenses, NamespacePrefix 
            FROM PackageLicense 
            WHERE Status = 'Active' AND 
            NamespacePrefix IN :nameSpaces AND 
            AllowedLicenses != -1
        ]);
        return plMap;
    }

    public Map<Id, Set<ID>> getUsersWithAssignedPackageLicenses(Set<Id> usersIdsInScope, Set<Id> packageIDs){
        List<UserPackageLicense> existingPackageLicenseAssignments = new List<UserPackageLicense>([
            SELECT Id,UserId, PackageLicenseId 
            FROM UserPackageLicense 
            WHERE PackageLicenseId IN :packageIDs
            AND UserId IN :usersIdsInScope
        ]);
        Map<Id, Set<Id>> assignedUsersPerPackage = new Map<Id, Set<Id>>();
        for(UserPackageLicense assignment : existingPackageLicenseAssignments){   
            if(assignedUsersPerPackage.containsKey(assignment.PackageLicenseId)){
                assignedUsersPerPackage.get(assignment.PackageLicenseId).add(assignment.UserId);
            } else {
                assignedUsersPerPackage.put(assignment.PackageLicenseId, new Set<Id>{assignment.UserId});
            }
        }
        return assignedUsersPerPackage;
    }

    public Map<Id, Set<Id>> getUsersWithAssignedPermissionSets(Set<Id> usersIdsInScope, Set<Id> permissionSetIds){
        List<PermissionSetAssignment> existingPermissionSetAssignments = new List<PermissionSetAssignment>([
            SELECT Id, AssigneeId, PermissionSetId 
            FROM PermissionSetAssignment
            WHERE PermissionSetId IN :permissionSetIds
            AND AssigneeId IN :usersIdsInScope
        ]); 
        Map<Id, Set<Id>> assignedUsersPerPermissionSet = new Map<Id, Set<Id>>();
        for(PermissionSetAssignment assignment : existingPermissionSetAssignments){
            if(assignedUsersPerPermissionSet.containsKey(assignment.PermissionSetId)){
                assignedUsersPerPermissionSet.get(assignment.PermissionSetId).add(assignment.AssigneeId);   
            } else {
                assignedUsersPerPermissionSet.put(assignment.PermissionSetId, new Set<Id>{assignment.AssigneeId});
            }
        }
        return assignedUsersPerPermissionSet;
    }

    public List<PermissionSetAssignment> assignPermissionSetsToUsers(Set<Id> usersIdsInScope, Set<Id> permissionSetIds, Map<Id, Set<Id>> existingPermSetAssignments){
        if(existingPermSetAssignments ==null){
            existingPermSetAssignments = this.getUsersWithAssignedPermissionSets(usersIdsInScope, permissionSetIds);
        }
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for(Id permissionSetId : permissionSetIds){
            Set<Id> usersIdsForPermSet = existingPermSetAssignments.get(permissionSetId);
            for(Id userId : usersIdsInScope){
                
                if(usersIdsForPermSet == null || !usersIdsForPermSet.contains(userId)){
                    psas.add(new PermissionSetAssignment(
                        AssigneeId = userId,
                        PermissionSetId = permissionSetId
                    ));
                }
            }
        }
        return psas;
    }

    public List<UserPackageLicense> assignPackagesToUsers(Set<Id> usersIdsInScope, Set<Id> licenseIDs, Map<Id, Set<Id>> existingLicenseAssignments){
        if(existingLicenseAssignments ==null ){
            existingLicenseAssignments = this.getUsersWithAssignedPackageLicenses(usersIdsInScope, licenseIDs);
        }
        List<UserPackageLicense> upls = new List<UserPackageLicense>();
        for(Id licenseId : licenseIDs){
            Set<Id> usersIdsWithPackageLicense = existingLicenseAssignments.get(licenseId);
            for(Id userId : usersIdsInScope){
                if(usersIdsWithPackageLicense == null || !usersIdsWithPackageLicense.contains(userId)){
                    upls.add(new UserPackageLicense(
                        PackageLicenseId = licenseId,
                        UserId = userId
                    ));
                }
            }
        }
        return upls;
    }


}