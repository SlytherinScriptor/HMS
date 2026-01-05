@isTest
public class BM_AppointmentTest {

    @testSetup
    static void setup() {
        // Create Cardiology Doctor
        Doctor__c cardioDoc = new Doctor__c(
            First_Name__c = 'Cardio',
            Last_Name__c = 'Doc',
            Email__c = 'cdoc@test.com',
            Specialization__c = 'Cardiology'
        );
        insert cardioDoc;
        
        // Create General Practice Doctor for fallback cases
        Doctor__c gpDoc = new Doctor__c(
            First_Name__c = 'General',
            Last_Name__c = 'Practitioner',
            Email__c = 'gp@test.com',
            Specialization__c = 'General Practice'
        );
        insert gpDoc;
        
        // Create Shifts for all days of the week to ensure availability
        List<Doctor_Shift__c> shifts = new List<Doctor_Shift__c>();
        List<String> days = new List<String>{'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
        
        for(String day : days) {
            shifts.add(new Doctor_Shift__c(
                Doctor__c = cardioDoc.Id,
                Day_of_Week__c = day,
                Start_Time__c = Time.newInstance(8,0,0,0),
                End_Time__c = Time.newInstance(12,0,0,0)
            ));
            shifts.add(new Doctor_Shift__c(
                Doctor__c = gpDoc.Id,
                Day_of_Week__c = day,
                Start_Time__c = Time.newInstance(8,0,0,0),
                End_Time__c = Time.newInstance(12,0,0,0)
            ));
        }
        insert shifts;
        
        // Create Patient
        insert new Patient__c(
            First_Name__c = 'Pat',
            Last_Name__c = 'One',
            Email__c = 'p1@test.com',
            Phone__c = '1234567890'
        );
    }
    
    @isTest
    static void testAutoAssignToday() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        // Appointment for today at 9 AM (within shift)
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Specialization__c = 'Cardiology',
            Date_Time__c = DateTime.newInstance(Date.today(), Time.newInstance(9,0,0,0)),
            Status__c = 'Scheduled'
        );
        
        Test.startTest();
        insert appt;
        Test.stopTest();
        
        Appointment__c saved = [SELECT Id, Doctor__c FROM Appointment__c WHERE Id = :appt.Id];
        System.assertNotEquals(null, saved.Doctor__c, 'Doctor should be auto assigned');
    }
    
    @isTest
    static void testAgentUsageHighConfidence() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Notes__c = 'Patient has severe chest pain and heart palpitations', // Cardiology, High Conf, Urgent
            Status__c = 'Scheduled'
        );
        
        Test.startTest();
        insert appt;
        Test.stopTest();
        
        Appointment__c saved = [SELECT Id, Doctor__c, Specialization__c, Priority__c FROM Appointment__c WHERE Id = :appt.Id];
        
        System.assertEquals('Cardiology', saved.Specialization__c, 'Agent should classify chest pain as Cardiology');
        System.assertEquals('High', saved.Priority__c, 'Priority should be High for urgent symptoms');
        System.assertNotEquals(null, saved.Doctor__c, 'Doctor should be auto assigned');
        
        // Check Audit
        List<AI_Audit__c> audits = [SELECT Id, Output_Specialty__c, Decision_Type__c FROM AI_Audit__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(1, audits.size(), 'Should create one audit record');
        System.assertEquals('Cardiology', audits[0].Output_Specialty__c);
        System.assertEquals('Urgent', audits[0].Decision_Type__c);
    }

    @isTest
    static void testAgentUsageLowConfidence() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Notes__c = 'Feeling a bit off', // General Practice, Low Conf
            Status__c = 'Scheduled'
        );
        
        Test.startTest();
        insert appt;
        Test.stopTest();
        
        Appointment__c saved = [SELECT Id, Doctor__c, Specialization__c FROM Appointment__c WHERE Id = :appt.Id];
        
        System.assertEquals('General Practice', saved.Specialization__c, 'Should default to General Practice on low confidence');
        System.assertEquals(null, saved.Doctor__c, 'Should not assign doctor');
        
        // Check Audit
        List<AI_Audit__c> audits = [SELECT Id, Decision_Type__c FROM AI_Audit__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(1, audits.size());
        System.assertEquals('Review Required', audits[0].Decision_Type__c);
        
        // Check Task
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :appt.Id];
        System.assertEquals(1, tasks.size(), 'Should create a review task');
        System.assert(tasks[0].Subject.contains('Review'), 'Task subject should indicate review');
    }

    @isTest
    static void testNoDoctorFound() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        // Use a time within shift hours (8 AM - 12 PM) so we test "no doctor found" not shift validation
        DateTime apptTime = DateTime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        
        Appointment__c appt = new Appointment__c(
            Patient__c = pat.Id,
            Specialization__c = 'Neurology', // No neuro doctor
            Date_Time__c = apptTime,
            Status__c = 'Scheduled'
        );
        
        try {
            insert appt;
            System.assert(false, 'Should throw exception');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('No doctors found') || e.getMessage().contains('No available doctors'), 'Wrong error: ' + e.getMessage());
        }
    }
}
