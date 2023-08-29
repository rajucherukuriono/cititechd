@isTest(seeAllData=false)
private class HMTriggerTest {

 static testMethod void testPost1() {
     Hiring_Manager__c hm = new Hiring_Manager__c();
     hm.Name='HiringManager1';
     hm.Email_ID__c='raju@yahoo.com';
     hm.Contact_Number__c='7896541234';
     hm.Location__c='Hyderabad';
     insert hm;
     
     Position__c pos = new Position__c();
     pos.name='Position1';
     pos.Hiring_Manager__c=hm.Id;
     insert pos;
 
 } 

}