@isTest
public class APT_AppointmentHandler_Test {
    @testSetup
    static void setup() {
        Doctor__c doc = new Doctor__c(First_Name__c='Doc', Last_Name__c='Test', Email__c='testdoc@example.com', Specialization__c='Cardiology');
        insert doc;
        
        insert new Doctor_Shift__c(Doctor__c=doc.Id, Day_of_Week__c=DateTime.now().format('EEEE'), Start_Time__c=Time.newInstance(0,0,0,0), End_Time__c=Time.newInstance(23,59,0,0));
        
        Patient__c pat = new Patient__c(First_Name__c='Pat', Last_Name__c='Test', Email__c='testpat@example.com', Phone__c='1234567890');
        insert pat;
    }

    @isTest
    static void testOverlapValidation() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        DateTime now = DateTime.now();
        
        insert new Appointment__c(Doctor__c=doc.Id, Patient__c=pat.Id, Date_Time__c=now, Status__c='Scheduled');
        
        try {
            insert new Appointment__c(Doctor__c=doc.Id, Patient__c=pat.Id, Date_Time__c=now, Status__c='Scheduled');
            System.assert(false, 'Should have failed overlap');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('already has an appointment'), 'Overlap message expected');
        }
    }

    @isTest
    static void testBillingCreation() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        DateTime now = DateTime.now();
        
        Appointment__c appt = new Appointment__c(Doctor__c=doc.Id, Patient__c=pat.Id, Date_Time__c=now, Status__c='Scheduled');
        insert appt;
        
        Test.startTest();
        appt.Status__c = 'Completed';
        update appt;
        Test.stopTest();
        
        List<Billing__c> bills = [SELECT Id, Status__c FROM Billing__c WHERE Appointment__c = :appt.Id];
        System.assertEquals(1, bills.size(), 'Bill should be created');
    }
}
