public with sharing class RM_Appointment {
    public static List<Appointment__c> getAppointmentsByDoctorAndDate(Set<Id> doctorIds, Date startDate, Date endDate) {
        Date rangeEnd = endDate.addDays(1);
        return [
            SELECT Id, Doctor__c, Date_Time__c, Status__c, Notes__c, 
                   Patient__c, Patient__r.First_Name__c, Patient__r.Last_Name__c
            FROM Appointment__c 
            WHERE Doctor__c IN :doctorIds 
            AND Date_Time__c >= :startDate 
            AND Date_Time__c < :rangeEnd
            AND Status__c != 'Cancelled'
        ];
    }

    public static void insertAppointments(List<Appointment__c> appts) {
        insert appts;
    }

    @AuraEnabled
    public static void updateAppointmentStatus(Id appointmentId, String status) {
        Appointment__c appt = new Appointment__c(Id = appointmentId, Status__c = status);
        update appt;
    }
}
