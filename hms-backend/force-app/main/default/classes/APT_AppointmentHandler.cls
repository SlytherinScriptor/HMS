public with sharing class APT_AppointmentHandler {
    public static void beforeInsert(List<Appointment__c> newList) {
        BM_Appointment.validateBeforeInsert(newList);
    }
    
    public static void afterInsert(List<Appointment__c> newList) {
        BM_Appointment.logAIDecisions(newList);
        AppointmentNotificationService.sendNotifications(newList);
    }
    
    public static void afterUpdate(List<Appointment__c> newList, Map<Id, Appointment__c> oldMap) {
        BM_Appointment.handleAfterUpdate(newList, oldMap);
    }
}
