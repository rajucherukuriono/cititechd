Trigger HMTrigger ON Hiring_Manager__c(before delete)
{
    if(Trigger.isBefore && Trigger.isDelete)
    {  
         List<Position__c> lstPos = [Select id, name, Hiring_Manager__c From Position__c Where Hiring_Manager__c in : Trigger.OldMap.KeySet()];
        //List<Position__c> lstPositions = [Select id, name, Hiring_Manager__c From Position_c Where Hiring_Manager__c in : Trigger.OldMap.KeySet()];
        for(Position__c pos : lstPos)
        {
            delete pos;
        }
    }
}