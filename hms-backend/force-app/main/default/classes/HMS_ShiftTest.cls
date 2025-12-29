@isTest
public class HMS_ShiftTest {
    
    @testSetup
    static void setup() {
        Doctor__c doc = new Doctor__c(
            First_Name__c = 'Test', 
            Last_Name__c = 'Doc', 
            Email__c = 'testdoc@hms.com',
            Specialization__c = 'Cardiology'
        );
        insert doc;
    }
    
    @isTest
    static void testSaveAndGetShifts() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        
        Test.startTest();
        HMS_Service.saveDoctorShift(
            doc.Id, 
            'Monday', 
            Time.newInstance(9,0,0,0), 
            Time.newInstance(17,0,0,0)
        );
        Test.stopTest();
        
        List<Doctor_Shift__c> shifts = HMS_Service.getDoctorShifts(doc.Id);
        System.assertEquals(1, shifts.size(), 'Should have 1 shift');
        System.assertEquals('Monday', shifts[0].Day_of_Week__c);
    }
    
    @isTest
    static void testValidationEndBeforeStart() {
        Doctor__c doc = [SELECT Id FROM Doctor__c LIMIT 1];
        
        Doctor_Shift__c invalidShift = new Doctor_Shift__c(
            Doctor__c = doc.Id, 
            Day_of_Week__c = 'Tuesday', 
            Start_Time__c = Time.newInstance(17,0,0,0), 
            End_Time__c = Time.newInstance(9,0,0,0)
        );
        
        Test.startTest();
        try {
            insert invalidShift;
            System.assert(false, 'Should have failed validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End Time must be later than Start Time'), 'Expected validation error');
        }
        Test.stopTest();
    }
}
