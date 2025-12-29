// Create a dummy Appointment to test
Patient__c pat = [SELECT Id FROM Patient__c LIMIT 1];
Appointment__c appt = new Appointment__c(
    Patient__c = pat.Id,
    Status__c = 'Scheduled'
);
insert appt;

System.debug('Appointment Created: ' + appt.Id);

// Test Agent Integration
try {
    String symptoms = 'Patient has severe chest pain and heart palpitations';
    
    INT_ClinicalTriageAgent.TriageRequest req = new INT_ClinicalTriageAgent.TriageRequest();
    req.appointmentId = appt.Id;
    req.symptoms = symptoms;
    
    List<INT_ClinicalTriageAgent.TriageRequest> requests = new List<INT_ClinicalTriageAgent.TriageRequest>{req};
    List<INT_ClinicalTriageAgent.TriageResponse> responses = INT_ClinicalTriageAgent.callAgent(requests);
    
    System.debug('Response Success: ' + responses[0].success);
    System.debug('Response Message: ' + responses[0].message);
    
    // Verify Update
    Appointment__c updatedAppt = [SELECT Specialization__c, Priority__c, Notes__c FROM Appointment__c WHERE Id = :appt.Id];
    System.debug('Updated Specialization: ' + updatedAppt.Specialization__c);
    System.debug('Updated Priority: ' + updatedAppt.Priority__c);
    
    // Verify Audit
    AI_Audit__c audit = [SELECT Input_Notes__c, Output_Specialty__c, Decision_Type__c FROM AI_Audit__c WHERE Appointment__c = :appt.Id ORDER BY CreatedDate DESC LIMIT 1];
    System.debug('Audit Notes: ' + audit.Input_Notes__c);
    System.debug('Audit Output: ' + audit.Output_Specialty__c);
    System.debug('Audit Decision: ' + audit.Decision_Type__c);
    
    // Assertions for correctness (manual check in logs)
    if(updatedAppt.Specialization__c == 'Cardiology' && updatedAppt.Priority__c == 'High' && audit.Decision_Type__c == 'Urgent') {
        System.debug('SUCCESS: integration worked as expected.');
    } else {
        System.debug('FAILURE: integration logic mismatch.');
    }

} catch(Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
