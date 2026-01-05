@isTest
private class INT_ClinicalTriageAgentTest {

    @testSetup
    static void setup() {
        // Create Patient with History
        Patient__c pat = new Patient__c(First_Name__c='Test', Last_Name__c='Patient', Email__c='test@example.com');
        insert pat;
        
        Medical_Record__c hist = new Medical_Record__c(Patient__c=pat.Id, Diagnosis__c='Chronic Asthma', Visit_Date__c=Date.today().addDays(-10));
        insert hist;
        
        // Create Appointment linked to Patient
        Appointment__c appt = new Appointment__c(Patient__c=pat.Id, Date_Time__c=Datetime.now().addDays(1));
        insert appt;
    }

    private static User createAgentUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='agentuser' + DateTime.now().getTime() + '@testorg.com');
        insert u;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HMS_AI_Service_Permissions'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        insert psa;
        
        return u;
    }

    @isTest
    static void testCallAgentWithHistoryUrgent() {
        // Create User first to avoid Mixed DML with Patient check later? 
        // Or better: Create Patient/Appt in setup (already done), then create User here.
        // The Mixed DML happens if we insert User (Setup) and then update Patient (Non-Setup) in same txn?
        // Actually, createAgentUser inserts User.
        
        User u = createAgentUser();
        
        Appointment__c appt = [SELECT Id FROM Appointment__c LIMIT 1];
        
        INT_ClinicalTriageAgent.TriageRequest req = new INT_ClinicalTriageAgent.TriageRequest();
        req.appointmentId = appt.Id;
        req.symptoms = 'difficulty breathing';
        List<INT_ClinicalTriageAgent.TriageRequest> requests = new List<INT_ClinicalTriageAgent.TriageRequest>{req};
        
        List<INT_ClinicalTriageAgent.TriageResponse> responses;
        
        System.runAs(u) {
            Test.startTest();
            // Debug visibility
            Integer count = [SELECT Count() FROM Medical_Record__c];
            System.debug('User sees ' + count + ' medical records');
            System.assert(count > 0, 'User sees 0 medical records - Permissions/Sharing Issue');
            
            responses = INT_ClinicalTriageAgent.callAgent(requests);
            Test.stopTest();
        }
        
        System.assertEquals(1, responses.size());
        if (!responses[0].success) {
            System.debug('Failure Message: ' + responses[0].message);
        }
        System.assertEquals(true, responses[0].success, 'Agent call failed: ' + responses[0].message);
        
        // Re-query as System/Admin to verify updates
        Appointment__c updatedAppt = [SELECT Specialization__c, Priority__c FROM Appointment__c WHERE Id = :appt.Id];
        // Order by CreatedDate DESC to get the latest audit (the one from the agent call, not the trigger)
        AI_Audit__c audit = [SELECT Output_Specialty__c, Reasoning__c, Decision_Type__c FROM AI_Audit__c WHERE Appointment__c = :appt.Id ORDER BY CreatedDate DESC, Id DESC LIMIT 1];
        
        System.assertEquals('High', updatedAppt.Priority__c, 'Should be High Priority due to Asthma history');
        System.assertEquals('Urgent', audit.Decision_Type__c);
        System.assert(audit.Reasoning__c.contains('Asthma'), 'Reasoning should mention Asthma history');
    }

    @isTest
    static void testCallAgentNoHistory() {
        // Create User first
        User u = createAgentUser();
        
        // Use runAs to separate Setup vs Non-Setup DML context if needed, 
        // OR just create patient outside of the User creation flow if possible.
        // createAgentUser does DML on User/PermSet.
        // We need to insert Patient. To avoid Mixed DML, we can do it in System.runAs(u) or new User.
        
        Patient__c pat2;
        Appointment__c appt2;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
             pat2 = new Patient__c(First_Name__c='New', Last_Name__c='NoHist', Email__c='none@example.com');
             insert pat2;
             appt2 = new Appointment__c(Patient__c=pat2.Id, Date_Time__c=Datetime.now().addDays(2));
             insert appt2;
        }
        
        INT_ClinicalTriageAgent.TriageRequest req = new INT_ClinicalTriageAgent.TriageRequest();
        req.appointmentId = appt2.Id;
        req.symptoms = 'mild headache';
        List<INT_ClinicalTriageAgent.TriageRequest> requests = new List<INT_ClinicalTriageAgent.TriageRequest>{req};
        
        List<INT_ClinicalTriageAgent.TriageResponse> responses;
        
        System.runAs(u) {
            Test.startTest();
            responses = INT_ClinicalTriageAgent.callAgent(requests);
            Test.stopTest();
        }
        
        System.assertEquals(true, responses[0].success);
        
        Appointment__c updatedAppt = [SELECT Priority__c FROM Appointment__c WHERE Id = :appt2.Id];
        System.assertNotEquals('High', updatedAppt.Priority__c, 'Should not be High Priority');
    }
}
