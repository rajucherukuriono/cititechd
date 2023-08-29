trigger CancelledOrders on OrderCancellation__e (after insert) {
    List<CancelledOrder__c> cords = new List<CancelledOrder__c>();
    
    for(OrderCancellation__e oc : trigger.new){
        CancelledOrder__c cord = new CancelledOrder__c();
        cord.Status__c = oc.Status__c;
        cord.CancelledOrder__c = oc.OrderId__c;
        cord.OpequeID__c = oc.ReplayID;
    
        cords.add(cord);
        System.debug('Event added ------------->>>>');
    }
    if (cords.size() > 0){
        database.insert(cords);
    }

}