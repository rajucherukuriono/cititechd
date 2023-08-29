public class CloneOrderController {
    @AuraEnabled
    public static Order getOrderDetails(String orderId){
         return [SELECT Id, AccountId,  Status FROM Order WHERE Id =: orderId];
    }

}