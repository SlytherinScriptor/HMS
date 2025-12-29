@isTest
public class HMS_TimelineTest {
    
    @testSetup
    static void setup() {
        Doctor__c doc = new Doctor__c(First_Name__c='Test', Last_Name__c='Doc', Email__c='doc@test.com', Specialization__c='General Practice');
        insert doc;
        
        Patient__c pat = new Patient__c(First_Name__c='Pat', Last_Name__c='Tim', Email__c='tim@test.com', Phone__c='9998887776');
        insert pat;
        
        // Create valid shift for Appointment
        DateTime apptTime = DateTime.now().addDays(1);
        String dayName = apptTime.format('EEEE');
        insert new Doctor_Shift__c(
            Doctor__c=doc.Id, 
            Day_of_Week__c=dayName, 
            Start_Time__c=Time.newInstance(0,0,0,0), 
            End_Time__c=Time.newInstance(23,59,0,0)
        );

        Appointment__c appt = new Appointment__c(Patient__c=pat.Id, Doctor__c=doc.Id, Date_Time__c=apptTime, Status__c='Scheduled');
        insert appt;
        
        insert new Medical_Record__c(Patient__c=pat.Id, Doctor__c=doc.Id, Diagnosis__c='Flu', Visit_Date__c=Date.today());
        insert new Billing__c(Patient__c=pat.Id, Appointment__c=appt.Id, Status__c='Unpaid', Total_Amount__c=100, Payment_Date__c=Date.today());

    }
    

    @isTest
    static void testGetTimeline() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        Test.startTest();
        List<BM_Patient.TimelineItem> timeline = HMS_Service.getPatientTimeline(pat.Id);
        Test.stopTest();
        
        System.assertEquals(3, timeline.size(), 'Should return 3 items (Appt, Rec, Bill)');
        
        // Check sorting (descending)
        // Since we created them roughly same time or future, logic:
        // Appt is +1 day.
        // Rec/Report/Bill are today/now.
        // So Appt should be first.
        System.assertEquals('Appointment', timeline[0].type);
    }
}
