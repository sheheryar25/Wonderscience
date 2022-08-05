trigger trg_Opportunity on Opportunity (before Update,after update) {
    if(C_AcoidRecursiveness.runAccountTrigger){
        Map<string,string> WEBToSFDC = new Map<string,string>();
        Map<string,string> SFDCToWEB = new Map<string,string>();
        Map<String, Opportunity_Stage_Transformation__mdt> oppStageTransformationMap = Opportunity_Stage_Transformation__mdt.getAll();
        for(Opportunity_Stage_Transformation__mdt transformationObj : oppStageTransformationMap.values()){
            SFDCToWEB.put(transformationObj.Label,transformationObj.Web_App_Stage__c);
            WEBToSFDC.put(transformationObj.Web_App_Stage__c,transformationObj.Label);
        }
        if(Trigger.isAfter){
            if(Trigger.isUpdate){
                for(Opportunity opp : trigger.new){
                    if(opp.StageName == 'Disqualified' ||opp.StageName == 'No-Show' ||opp.StageName == 'Prescribed' ||opp.StageName == 'Shipped')
                    {
                        if(C_AcoidRecursiveness.sendFutureCall)
                        {
                            string CustStageName = SFDCToWEB.get(opp.StageName) != null ? SFDCToWEB.get(opp.StageName) : opp.StageName; 
                            //Call @Future
                            string EndPointURL = Label.WebAPP_BaseURL+'/webhooks/api/salesforce/customer-journey';
                            CC_trg_OppHandler.sendCustomerJourney(opp.AccountId,opp.Id,CustStageName,EndPointURL,'PATCH');
                            //Call @Future
                        }
                    }
                    
                }
            }
        }
        if(Trigger.isBefore){
            if(Trigger.isInsert || Trigger.isUpdate){
                for(Opportunity oppObj : trigger.new){
                    oppObj.StageName = WEBToSFDC.get(oppObj.StageName) != null ? WEBToSFDC.get(oppObj.StageName) : SFDCToWEB.get(oppObj.StageName) != null ? SFDCToWEB.get(oppObj.StageName) : oppObj.StageName;
                }
            }
        }
    }
}