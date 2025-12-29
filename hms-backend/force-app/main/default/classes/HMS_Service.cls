public with sharing class HMS_Service {
    @AuraEnabled(cacheable=true)
    public static List<BM_Patient.TimelineItem> getPatientTimeline(Id patientId) {
        return BM_Patient.getPatientTimeline(patientId);
    }
    
    @AuraEnabled
    public static void saveDoctorShift(Id doctorId, String dayOfWeek, Time startTime, Time endTime) {
        BM_Doctor.saveShift(doctorId, dayOfWeek, startTime, endTime);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Doctor_Shift__c> getDoctorShifts(Id doctorId) {
        return BM_Doctor.getShifts(doctorId);
    }

    @AuraEnabled(cacheable=true) 
    public static List<Appointment__c> getUpcomingAppointments() {
        return [SELECT Id, Patient__r.First_Name__c, Patient__r.Last_Name__c, Doctor__r.Last_Name__c, Date_Time__c, Status__c FROM Appointment__c WHERE Date_Time__c >= TODAY ORDER BY Date_Time__c ASC LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardStats() {
        return HMS_AnalyticsService.getDashboardAnalytics();
    }
}