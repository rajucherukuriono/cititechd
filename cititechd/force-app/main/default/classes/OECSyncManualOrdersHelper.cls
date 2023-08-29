public class OECSyncManualOrdersHelper {


    String apiCalloutName = 'OECManualOrderCreation';
    String apiEnvironment;
    CalloutData__c cd;
    CalloutData__c cancelledcd;
    private static Set<Id> alreadyProcessed = new Set<Id>();
    private static Set<Id> alreadyProcessedOrds = new Set<Id>();
    Order[] ords;  
    public OECSyncManualOrdersHelper(list<Order> triggerNew,map<Id,Order> triggerNewmap){ 
    
        
        //Load required details for onAfter Insert 
        //IdOrderMapBatch=IdOrderMap;
        //getAccessToken(outBoundCallName);
       
        // Fetch environment variable from custom metadata
        // Fetch API Environment to be connected from custom meta data
        

           
        //Load custom settings for the current environment for the API.
        loadCalloutParams();
        ords = [SELECT SyncStatus__c, recordtypeid, CreatedBy.Name , Business_Line__c, Status, 
               Sync_to_OEC__c, Account.External_Sync__c, RecordType.Name,OEC_Event_Name__c,name FROM Order WHERE Id IN :triggerNew and RecordType.Name in ('Standard Order','No Contract Required Order') ];
 
        System.debug('CalloutData__c---------------->>'+cd);
         
    } 

    public void onAfterUpdate(list<Order> triggerNew,map<Id,Order> triggerNewmap){
        
        Map<id,Order> IdOrderMap = new Map<Id,Order>();
        Map<id,Order> IdCanOrderMap = new Map<Id,Order>();
        //updateOECEventName();
        for(Order ord:ords){
            
            System.debug('In For loop---------------->>1');
            if(ord.Status == 'In Progress'){
                System.debug('In In Progress---------------->>2');
                if(validOrderToProcess(ord) && !alreadyProcessed.contains(ord.id)){
                    System.debug('In In Progress---------------->>2.2');
                    alreadyProcessed.add(ord.id);
                    IdOrderMap.put(ord.id,ord);
                }

            }
            else if(ord.Status == 'Cancelled'){   
                System.debug('In IdOrderMap.size---------------->>3');
                IdCanOrderMap.put(ord.id,ord);
                // Erite new real time Sync to process the Cancelled Orders   
                
            } 
         } 
         
         if(!System.isFuture() && !System.isBatch()){
             if(IdOrderMap.size() > 0){
             
                 System.debug('In IdOrderMap.size---------------->>4');
                 database.executeBatch(new OECManualOrderSync(IdOrderMap, cd),1); // Calling batch class.
                        
             }    
         
             if(IdCanOrderMap.size() > 0){
                 System.debug('In IdOrderMap.size---------------->>5');
                 database.executeBatch(new OECOrderStatusSync(IdCanOrderMap, cancelledcd),1); // Calling batch class.                    
             }
         
         }       
    }    
    
    public void onBeforeInsert(list<Order> triggerNew,map<Id,Order> triggerNewmap){
        
        List<Order> listOrders = new List<Order>();
        
        for(Order ord:triggerNew){

            if((String.isBlank(ord.OEC_Event_Name__c)) || ord.isClone()) 
                ord.OEC_Event_Name__c = ord.Name;

            listOrders.add(ord); 

        }
        
        if(listOrders.size() > 0){
            dupCheckonOECEventName(triggerNew);                
        }        
    }
    /*
    public void onBeforeUpdate(list<Order> triggerNew,map<Id,Order> triggerNewmap){
        
        List<Order> listOrders = new List<Order>();
        
        for(Order ord:triggerNew){

             if(ord.CreatedBy.Name == 'API Integration User' )
                ord.OEC_Event_Name__c = ord.Name;

            listOrders.add(ord); 

        }
        
        if(listOrders.size() > 0){
            dupCheckonOECEventName(triggerNew);                
        }        
    }   */ 
    
    /**
    Finds the right Order needs to be synced back to OEC
    */
    private boolean validOrderToProcess(Order ord){
    
    /*
        System.debug(
            'ord.RecordType.Name:'+ Schema.SObjectType.Order.getRecordTypeInfosById().get(ord.recordtypeid).getname()+
            '- ord.CreatedBy.Name:'+ord.CreatedBy.Name+
            '- ord.Business_Line__c:'+ord.Business_Line__c+
            '- ord.Status:'+ord.Status+
            '- ord.Sync_to_OEC__c:'+ord.Sync_to_OEC__c+
            '- ord.Account.External_Sync__c'+ord.Account.External_Sync__c
        );*/
        
        if (String.isNotBlank(ord.SyncStatus__c)){
            System.debug('Returning due to ------------>>  ord.SyncStatus__c');
            return false; 
            
        }    
        //else if(ord.RecordType.Name == 'Corporate_StreamLinks_Order' || ord.RecordType.Name == 'Corporate_Knovio_Order')
        else if(String.isBlank(ord.RecordType.Name )){
            System.debug('Returning due to ------------>>  ord.RecordType.Name ');
            return false;
        }
        else if(Schema.SObjectType.Order.getRecordTypeInfosById().get(ord.recordtypeid).getname() != 'Standard Order' && 
                Schema.SObjectType.Order.getRecordTypeInfosById().get(ord.recordtypeid).getname() != 'No Contract Required Order')
        {        
            System.debug('Returning due to ------------>>  ord.RecordType.ID ');
            return false;// We will not process Corporate_StreamLinks_Order orders
        }
        else if (ord.CreatedBy.Name == 'API Integration User') 
        {
            System.debug('Returning due to ------------>>  ord.CreatedBy.Name ');
            return false;// We will not process Order created by API Integration User
        }
        else if (ord.Status != 'In Progress')
        {
            System.debug('Returning due to ------------>>  ord.Status');
            return false;
        }
        else if (ord.Sync_to_OEC__c == False)
        {
            System.debug('Returning due to ------------>>  Sync_to_OEC__c');
            return false;
        }
        else if(ord.Account.External_Sync__c != true)
        {
            System.debug('Returning due to ------------>>  External_Sync__c ');
            return false;     
        }                
        return true;        
                    
    }
    
    private void loadCalloutParams(){
    
        Integration_Configuration__mdt ic = [SELECT API_Environment__c from Integration_Configuration__mdt];
        apiEnvironment = ic.API_Environment__c;
        
        System.debug('API Environment getting connected is -----> :'+apiEnvironment); 
        //CalloutData__c cd;

        if (apiEnvironment == 'QA'){
            OECCallOuts__mdt callouts = [SELECT QACancelEndpointURL__c, QAAccountId__c,QAAuthURL__c,QAEndpointURL__c,QAPassword__c,QAUserName__c FROM OECCallOuts__mdt where Label ='OECManualOrderCreation'];
            //OECCallOuts__mdt callouts = [SELECT QAAccountId__c,QAAuthURL__c,QAEndpointURL__c,QAPassword__c,QAUserName__c FROM OECCallOuts__mdt where Label ='OECManualOrderCreation'];
            cd = new CalloutData__c (AccountId__c=callouts.QAAccountId__c,AuthenticationURL__c=callouts.QAAuthURL__c,EndPointURL__c=callouts.QAEndpointURL__c,UserPassword__c=callouts.QAPassword__c,UserName__c=callouts.QAUserName__c);
        
            cancelledcd = new CalloutData__c (AccountId__c=callouts.QAAccountId__c,AuthenticationURL__c=callouts.QAAuthURL__c,EndPointURL__c=callouts.QACancelEndpointURL__c,UserPassword__c=callouts.QAPassword__c,UserName__c=callouts.QAUserName__c);
            
        }
        else if (apiEnvironment == 'Prod'){
            OECCallOuts__mdt callouts = [SELECT ProdCancelEndpointURL__c, ProdAccountId__c,ProdAuthURL__c,ProdEndpointURL__c,ProdPassword__c,ProdUserName__c FROM OECCallOuts__mdt where Label ='OECManualOrderCreation'];
            cd = new CalloutData__c(AccountId__c=callouts.ProdAccountId__c,AuthenticationURL__c=callouts.ProdAuthURL__c,EndPointURL__c=callouts.ProdEndpointURL__c,UserPassword__c=callouts.ProdPassword__c,UserName__c=callouts.ProdUserName__c);
       
            cancelledcd = new CalloutData__c (AccountId__c=callouts.ProdAccountId__c,AuthenticationURL__c=callouts.ProdAuthURL__c,EndPointURL__c=callouts.ProdCancelEndpointURL__c,UserPassword__c=callouts.ProdPassword__c,UserName__c=callouts.ProdUserName__c);
        }
        else {
            OECCallOuts__mdt callouts = [SELECT StageCancelEndpointURL__c, DevAccountId__c,DevAuthURL__c,DevEndpointURL__c,DevPassword__c,DevUserName__c FROM OECCallOuts__mdt where Label ='OECManualOrderCreation'];
            cd = new CalloutData__c(AccountId__c=callouts.DevAccountId__c,AuthenticationURL__c=callouts.DevAuthURL__c,EndPointURL__c=callouts.DevEndpointURL__c,UserPassword__c=callouts.DevPassword__c,UserName__c=callouts.DevUserName__c);
            cancelledcd = new CalloutData__c (AccountId__c=callouts.DevAccountId__c,AuthenticationURL__c=callouts.DevAuthURL__c,EndPointURL__c=callouts.StageCancelEndpointURL__c,UserPassword__c=callouts.DevPassword__c,UserName__c=callouts.DevUserName__c);
        }
                
    }
    /**
    private void updateOECEventName(){
        
        List<Order> listOrders = new List<Order>();
        
        for(Order ord:ords){
        
            if(!alreadyProcessedOrds.contains(ord.id))
            {
                System.debug('------------->> In For Loop to process after insert created Records '+trigger.size+'--'+ord.id);
                if(ord.CreatedBy.Name != 'API Integration User') {
                    ord.OEC_Event_Name__c = ord.Name;
                }
                listOrders.add(ord);
                    
                alreadyProcessedOrds.add(ord.Id);    
            }    
                
        }
        if(listOrders.size() > 0)
            update listOrders;
    
    } */
    
    private void dupCheckonOECEventName(List<Order> ordersList){
        if(ordersList.size() > 0) {
            for (Order ord : ordersList) {
                
                Integer existingOrd = [select count() from Order where OEC_Event_Name__c = :ord.OEC_Event_Name__c and Start_Date__c = :ord.Start_Date__c limit 1];
                if (existingOrd > 0) {
                    ord.addError('We cant create a duplicate Order as we have already Order exist with this OEC Event Name/ Event Name and Order Start Date.');
                }
            }
         }
    
    }
    
    
}