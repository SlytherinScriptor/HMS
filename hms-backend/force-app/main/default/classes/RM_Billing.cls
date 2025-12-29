public with sharing class RM_Billing {
    public static void insertBillings(List<Billing__c> billings) {
        insert billings;
    }
    
    public static List<Billing__c> getExistingBillings(Set<Id> appointmentIds) {
        return [SELECT Appointment__c FROM Billing__c WHERE Appointment__c IN :appointmentIds];
    }
}
