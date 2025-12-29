public with sharing class RM_Doctor {
    public static List<Doctor__c> getDoctorsBySpecialization(String specialization) {
        return [SELECT Id, First_Name__c, Last_Name__c, Specialization__c 
                FROM Doctor__c 
                WHERE Specialization__c = :specialization];
    }

    public static List<Doctor_Shift__c> getShiftsByDoctor(Set<Id> doctorIds) {
        return [SELECT Id, Doctor__c, Day_of_Week__c, Start_Time__c, End_Time__c 
                FROM Doctor_Shift__c 
                WHERE Doctor__c IN :doctorIds];
    }
    
    public static List<Doctor__c> getDoctorByEmail(String email) {
        return [SELECT Id, First_Name__c, Last_Name__c, Specialization__c, Email__c 
                FROM Doctor__c 
                WHERE Email__c = :email LIMIT 1];
    }
}
