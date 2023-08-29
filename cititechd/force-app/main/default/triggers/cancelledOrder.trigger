trigger cancelledOrder on Order (after update) {
    OrderCancellation__e ore = new OrderCancellation__e();
    for(Order ord : trigger.new){
      
    
        //if(ord.Status == 'Cancelled' and ord.Status){
        System.debug('Trigger.oldMap.get(ord.id).Status ------------>>>'+Trigger.oldMap.get(ord.id).Status +':  ord.Status--------->>'+ord.Status); 
        if (Trigger.oldMap.get(ord.id).Status != 'Cancelled' && ord.Status != Trigger.oldMap.get(ord.id).Status){
             System.debug('Before Creating ORE ------------>>>');        
             ore.OrderId__c = ord.Id;
             ore.Status__c = 'Cancelled';
             
             System.debug('Before publishing ------------>>>'+ore.Status__c); 
             Database.saveResult sr = EventBus.publish(ore);
             System.debug('After publishing ------------>>>'+ore.OrderId__c);
        
         }  
        
    }

}