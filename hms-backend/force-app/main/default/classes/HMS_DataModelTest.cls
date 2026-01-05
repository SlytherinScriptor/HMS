@isTest
public class HMS_DataModelTest {
    
    @testSetup
    static void setup() {
        HMS_TestDataFactory.createPatients(1, true);
        HMS_TestDataFactory.createDoctors(1, true);
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        
        // Create shifts for the doctor
        DateTime apptTime = DateTime.now().addDays(1);
        String dayName = apptTime.format('EEEE');
        insert new Doctor_Shift__c(
            Doctor__c = doc.Id,
            Day_of_Week__c = dayName,
            Start_Time__c = Time.newInstance(0, 0, 0, 0),
            End_Time__c = Time.newInstance(23, 59, 0, 0)
        );
        
        insert new Appointment__c(
            Patient__c = pat.Id,
            Doctor__c = doc.Id,
            Date_Time__c = apptTime,
            Status__c = 'Scheduled'
        );
    }
    
    @isTest
    static void testMedicalRecordCreation() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        
        Medical_Record__c mr = new Medical_Record__c(
            Patient__c = pat.Id,
            Doctor__c = doc.Id,
            Diagnosis__c = 'Seasonal Flu',
            Prescription__c = 'Rest and hydration',
            Visit_Date__c = Date.today()
        );
        insert mr;
        
        Medical_Record__c savedMr = [SELECT Id, Diagnosis__c FROM Medical_Record__c WHERE Id = :mr.Id];
        System.assertEquals('Seasonal Flu', savedMr.Diagnosis__c, 'Diagnosis should match');
    }
    
    @isTest
    static void testBillingCreation() {
        Appointment__c appt = [SELECT Id, Patient__c FROM Appointment__c LIMIT 1];
        
        Billing__c bill = new Billing__c(
            Appointment__c = appt.Id,
            Patient__c = appt.Patient__c,
            Total_Amount__c = 150.00,
            Status__c = 'Unpaid',
            Payment_Date__c = Date.today()
        );
        insert bill;
        
        Billing__c savedBill = [SELECT Id, Total_Amount__c FROM Billing__c WHERE Id = :bill.Id];
        System.assertEquals(150.00, savedBill.Total_Amount__c, 'Total Amount should match');
    }
    

}
