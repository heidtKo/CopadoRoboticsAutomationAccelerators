global with sharing class Expression_FlowsInPromotion implements copado.ParameterExpressionCallable {

    global String execute(Id contextId) {
        // List to hold flow information
        List<Map<String, String>> flowsList = new List<Map<String, String>>();
        
        try {
            
            copado__JobStep__c cstep = [
                SELECT Id, 	copado__JobExecution__c, copado__JobExecution__r.copado__DataJson__c FROM copado__JobStep__c WHERE Id = :contextId
            ];
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(cstep.copado__JobExecution__r.copado__DataJson__c);
            String promotionId = (String)jsonMap.get('promotionId');
            System.debug('Promotion ID: ' + promotionId);

            // Get the promotion record
            List<copado__Promotion__c> promotions = [
                SELECT Id 
                FROM copado__Promotion__c 
                WHERE Id = :promotionId 
                LIMIT 1
            ];
            
            if(promotions.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Promotion not found',
                    'contextId' => contextId,
                    'promotionId' => promotionId
                });
            }
            
            // Query user stories related to the promotion
            List<copado__Promoted_User_Story__c> promoUserStories = [
                SELECT copado__User_Story__c 
                FROM copado__Promoted_User_Story__c 
                WHERE copado__Promotion__c = :promotionId
            ];
            
            // Get all user story IDs
            Set<Id> userStoryIds = new Set<Id>();
            for(copado__Promoted_User_Story__c pus : promoUserStories) {
                userStoryIds.add(pus.copado__User_Story__c);
            }
            
            // Query user story metadata 
            List<copado__User_Story_Metadata__c> metadataList = [
                SELECT copado__User_Story__r.Name,
                        copado__User_Story__r.copado__User_Story_Title__c,
                        copado__Metadata_API_Name__c,
                        copado__Type__c
                FROM copado__User_Story_Metadata__c 
                WHERE copado__User_Story__c IN :userStoryIds 
                AND copado__Type__c = 'Flow'
                AND copado__Action__c = 'Add'
            ];
            
            //simple deduplication 
            Set<String> uniqueFlows = new Set<String>();

            // Process each commit to create flow information
            for(copado__User_Story_Metadata__c metadata : metadataList) {
                String typeName = metadata.copado__Type__c + '.' + metadata.copado__Metadata_API_Name__c;
                if(!uniqueFlows.contains(typeName)){
                    Map<String, String> flowInfo = new Map<String, String>();
                    flowInfo.put('apiName', metadata.copado__Metadata_API_Name__c);
                    flowInfo.put('type', metadata.copado__Type__c);
                    
                    uniqueFlows.add(typeName);
                    flowsList.add(flowInfo);
                }
            }
            
            // Create the final JSON structure
            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('flows', flowsList);
            resultMap.put('totalFlows', flowsList.size());
            resultMap.put('promotionId', contextId);
            
            // Convert to JSON string {"promotionId":"a0tQH0000093TmfYAE","totalFlows":2,"flows":[{"type":"Flow","apiName":"my_flow"},{"type":"Flow","apiName":"ctx_rule_1"}]}

            String resultJsonString = String.valueOf( JSON.serialize(resultMap));
            System.debug(resultJsonString);
            return resultJsonString;
            
        } catch(Exception e) {
            return JSON.serialize(new Map<String, Object>{
                'error' => e.getMessage(),
                'contextId' => contextId,
                'lineNumber' => e.getLineNumber(),
                'stack' => e.getStackTraceString()
            });
        }
    }
}