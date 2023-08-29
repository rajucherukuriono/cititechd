({doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('recordId'+recordId);
        var action = component.get("c.getOrderDetails");
        action.setParams({ 
                "orderId" : recordId
            });
        action.setCallback(this, function(response){
                var state = response.getState();
            if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                //console.log('results' + JSON.stringify(result));
                 var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({ 
                "entityApiName": "Order",
                "defaultFieldValues":{
                    "AccountId" : result.AccountId,
                    "Status" : result.Status,
                    "Description" : "Test D--"
                }                
            });
            createRecordEvent.fire();
               }
            });
            $A.enqueueAction(action);
    }
})