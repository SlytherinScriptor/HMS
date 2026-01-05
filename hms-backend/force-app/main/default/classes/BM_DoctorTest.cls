@isTest
private class BM_DoctorTest {
    @testSetup
    static void setup() {
        // Create Doctor with Current User's Email
        Doctor__c doctor = new Doctor__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Doctor',
            Email__c = UserInfo.getUserEmail()
        );
        insert doctor;

        // Create Patient
        Patient__c patient = new Patient__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Patient',
            Email__c = 'patient@test.com'
        );
        insert patient;

        // Create Shift for Today
        String dayOfWeek = DateTime.now().format('EEEE');
        Doctor_Shift__c shift = new Doctor_Shift__c(
            Doctor__c = doctor.Id,
            Day_of_Week__c = dayOfWeek,
            Start_Time__c = Time.newInstance(0, 0, 0, 0),
            End_Time__c = Time.newInstance(23, 59, 59, 0)
        );
        insert shift;

        // Create Appointments for Today
        Appointment__c appt = new Appointment__c(
            Doctor__c = doctor.Id,
            Patient__c = patient.Id,
            Date_Time__c = DateTime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0)),
            Status__c = 'Scheduled'
        );
        insert appt;
    }

    @isTest
    static void testGetMyAppointments() {
        Test.startTest();
        Map<String, Object> result = BM_Doctor.getMyAppointments();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        Doctor__c doc = (Doctor__c)result.get('doctor');
        System.assertEquals(UserInfo.getUserEmail(), doc.Email__c, 'Doctor email should match user email');

        List<Appointment__c> appointments = (List<Appointment__c>)result.get('appointments');
        System.assertNotEquals(null, appointments, 'Appointments list should not be null');
        System.assertEquals(1, appointments.size(), 'Should have 1 appointment for today');
    }

    @isTest
    static void testNoDoctorFound() {
        // Delete the doctor created in setup to test error
        delete [SELECT Id FROM Doctor__c];

        // Create a Standard User to bypass Admin check
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser' + DateTime.now().getTime() + '@testorg.com');
        insert u;

        System.runAs(u) {
            Test.startTest();
            try {
                BM_Doctor.getMyAppointments();
                System.assert(false, 'Should have thrown exception');
            } catch (Exception e) {
                System.assert(true, 'Exception caught as expected');
            }
            Test.stopTest();
        }
    }
}
