@isTest
public class BM_Billing_Test {
    @testSetup
    static void setup() {
         Doctor__c doc = new Doctor__c(First_Name__c='Doc', Last_Name__c='Test', Email__c='testdoc@example.com', Specialization__c='Cardiology');
        insert doc;
        insert new Doctor_Shift__c(Doctor__c=doc.Id, Day_of_Week__c=DateTime.now().format('EEEE'), Start_Time__c=Time.newInstance(0,0,0,0), End_Time__c=Time.newInstance(23,59,0,0));
        Patient__c pat = new Patient__c(First_Name__c='Pat', Last_Name__c='Test', Email__c='testpat@example.com', Phone__c='1234567890');
        insert pat;
        insert new Appointment__c(Doctor__c=doc.Id, Patient__c=pat.Id, Date_Time__c=DateTime.now(), Status__c='Completed');
    }

    @isTest
    static void testIdempotency() {
        Appointment__c appt = [SELECT Id, Patient__c FROM Appointment__c LIMIT 1];
        
        Test.startTest();
        // Manually trigger logic again
        BM_Billing.createBillingForCompleted(new List<Appointment__c>{appt});
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM Billing__c WHERE Appointment__c = :appt.Id];
        // Expect 1 (created trigger insert) + 0 (from redundant call) => NO, trigger created 1. 
        // Logic: Trigger created 1 on insert (if we had after insert logic, which we dont, only after update).
        // Wait, setup Inserted as 'Completed'. Trigger runs on update. So insert won't trigger billing creation.
        // We must call manually or update.
        
        // Actually, let's reset status and update to test End-to-End or just test method
        
        // Let's rely on method testing here
        
        // Call logic again
        BM_Billing.createBillingForCompleted(new List<Appointment__c>{appt});
        
        count = [SELECT COUNT() FROM Billing__c WHERE Appointment__c = :appt.Id];
        // 1 from first manual call (since insert didnt trigger it), 1 from second? No, idempotency should block 2nd.
        System.assertEquals(1, count, 'Should be idempotent');
    }
}
