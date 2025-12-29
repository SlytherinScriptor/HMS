@isTest
public class HMS_AnalyticsServiceTest {
    @isTest
    static void testGetAnalytics() {
        Test.startTest();
        Map<String, Object> data = HMS_AnalyticsService.getDashboardAnalytics();
        Test.stopTest();
        
        System.assertEquals(3, data.get('patientsCount'), 'Should have 3 patients');
        System.assertEquals(2, data.get('doctorsCount'), 'Should have 2 doctors');
        
        // Check new Analytics keys
        Map<String, Object> ageGroups = (Map<String, Object>) data.get('patientsByAge');
        System.assert(ageGroups.containsKey('19-35'), 'Should track 19-35 age group');
        
        Map<String, Object> genderMap = (Map<String, Object>) data.get('patientsByGender');
        System.assert(genderMap.containsKey('Male'), 'Should track Male gender');
        
        Map<String, Object> dayMap = (Map<String, Object>) data.get('appointmentsByDay');
        System.assert(dayMap != null, 'Should have day map');

        List<AggregateResult> topDocs = (List<AggregateResult>) data.get('topDoctors');
        System.assert(!topDocs.isEmpty(), 'Should have top doctors');
    }

    @testSetup
    static void setup() {
        // Doctors
        Doctor__c doc1 = new Doctor__c(First_Name__c='Doc1', Last_Name__c='Cardio', Email__c='doc1@test.com', Specialization__c='Cardiology');
        Doctor__c doc2 = new Doctor__c(First_Name__c='Doc2', Last_Name__c='Ortho', Email__c='doc2@test.com', Specialization__c='Orthopedics');
        insert new List<Doctor__c>{doc1, doc2};
        
        // Create shifts for all days to avoid validation errors
        List<Doctor_Shift__c> shifts = new List<Doctor_Shift__c>();
        List<String> days = new List<String>{'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
        for(String d : days) {
            shifts.add(new Doctor_Shift__c(Doctor__c=doc1.Id, Day_of_Week__c=d, Start_Time__c=Time.newInstance(0,0,0,0), End_Time__c=Time.newInstance(23,59,0,0)));
            shifts.add(new Doctor_Shift__c(Doctor__c=doc2.Id, Day_of_Week__c=d, Start_Time__c=Time.newInstance(0,0,0,0), End_Time__c=Time.newInstance(23,59,0,0)));
        }
        insert shifts;
        
        // Patients
        Patient__c pat1 = new Patient__c(First_Name__c='Pat1', Last_Name__c='Young', Email__c='pat1@test.com', Phone__c='1112223333', Age__c=25, Gender__c='Male');
        Patient__c pat2 = new Patient__c(First_Name__c='Pat2', Last_Name__c='Old', Email__c='pat2@test.com', Phone__c='1112223334', Age__c=65, Gender__c='Female');
        Patient__c pat3 = new Patient__c(First_Name__c='Pat3', Last_Name__c='Kid', Email__c='pat3@test.com', Phone__c='1112223335', Age__c=10, Gender__c='Male');
        insert new List<Patient__c>{pat1, pat2, pat3};
        
        // Appointments
        insert new Appointment__c(Patient__c=pat1.Id, Doctor__c=doc1.Id, Date_Time__c=DateTime.now().addDays(1), Status__c='Scheduled');
        insert new Appointment__c(Patient__c=pat2.Id, Doctor__c=doc1.Id, Date_Time__c=DateTime.now().addDays(2), Status__c='Completed');
        insert new Appointment__c(Patient__c=pat3.Id, Doctor__c=doc2.Id, Date_Time__c=DateTime.now().addDays(3), Status__c='Cancelled');
        
        // Billing for Revenue
        Appointment__c appt = [SELECT Id FROM Appointment__c LIMIT 1];
        insert new Billing__c(Appointment__c=appt.Id, Patient__c=pat1.Id, Status__c='Paid', Total_Amount__c=500, Payment_Date__c=Date.today());
    }
}
