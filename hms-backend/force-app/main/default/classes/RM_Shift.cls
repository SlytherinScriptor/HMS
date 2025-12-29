public with sharing class RM_Shift {
    public static List<Doctor_Shift__c> getShifts(Set<Id> doctorIds, String dayOfWeek) {
        return [SELECT Id, Doctor__c, Day_of_Week__c, Start_Time__c, End_Time__c 
                FROM Doctor_Shift__c 
                WHERE Doctor__c IN :doctorIds 
                AND Day_of_Week__c = :dayOfWeek];
    }
}
