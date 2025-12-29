@isTest
private class HealthAgentBookerTest {

    @testSetup
    static void setup() {
        // Create Patients
        List<Patient__c> pats = HMS_TestDataFactory.createPatients(1, true);
        
        // Create Doctors (Cardiology)
        List<Doctor__c> docs = HMS_TestDataFactory.createDoctors(1, false);
        docs[0].Specialization__c = 'Cardiology';
        insert docs;
        
        // Create Shifts for ALL days so assignment always finds a slot
        List<Doctor_Shift__c> shifts = new List<Doctor_Shift__c>();
        List<String> days = new List<String>{'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
        
        for(String day : days) {
            shifts.add(new Doctor_Shift__c(
                Doctor__c = docs[0].Id,
                Start_Time__c = Time.newInstance(0, 0, 0, 0), // Midnight
                End_Time__c = Time.newInstance(23, 59, 0, 0), // Almost midnight - full coverage
                Day_of_Week__c = day
            ));
        }
        insert shifts;
    }

    @isTest
    static void testBookAction() {
        Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
        
        HealthAgentBooker.BookingInput input = new HealthAgentBooker.BookingInput();
        input.patientId = pat.Id;
        input.specialization = 'Cardiology';
        input.notes = 'PDF Analysis: Severe heart issue.';
        
        List<HealthAgentBooker.BookingInput> inputs = new List<HealthAgentBooker.BookingInput>();
        inputs.add(input);
        
        Test.startTest();
        List<HealthAgentBooker.BookingOutput> results = HealthAgentBooker.bookAppointment(inputs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals('Success', results[0].status);
        System.assertNotEquals(null, results[0].appointmentId);
        System.assertNotEquals(null, results[0].assignedDoctorName, 'Doctor should be auto-assigned by Trigger');
    }
}
