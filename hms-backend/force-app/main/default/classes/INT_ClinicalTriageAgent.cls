public with sharing class INT_ClinicalTriageAgent {

    public class TriageRequest {
        @InvocableVariable(label='Appointment ID' required=true)
        public Id appointmentId;
        
        @InvocableVariable(label='Symptoms' required=true)
        public String symptoms;
    }

    public class TriageResponse {
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Message')
        public String message;
    }
    
    @InvocableMethod(label='Run Clinical Triage' description='Analyzes symptoms, updates Appointment specialization/priority, and logs decision.')
    public static List<TriageResponse> callAgent(List<TriageRequest> requests) {
        List<TriageResponse> responses = new List<TriageResponse>();
        
        for (TriageRequest req : requests) {
            TriageResponse res = new TriageResponse();
            try {
                processTriage(req.appointmentId, req.symptoms);
                res.success = true;
                res.message = 'Triage completed successfully.';
            } catch (Exception e) {
                res.success = false;
                res.message = e.getMessage();
            }
            responses.add(res);
        }
        return responses;
    }

    private static void processTriage(Id appointmentId, String symptoms) {
        if(String.isBlank(symptoms)) return;
        
        // 1. Validate permissions
        if (!Schema.sObjectType.Appointment__c.isAccessible() || 
            !Schema.sObjectType.AI_Audit__c.isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to invoke AI Agent.');
        }

        Appointment__c appt = [SELECT Id, Notes__c, Specialization__c, Priority__c FROM Appointment__c WHERE Id = :appointmentId LIMIT 1];
        
        // 2. Wrap the service call for Agentforce
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem(symptoms);
        
        Boolean isUrgent = result.urgent;
        Decimal confidence = result.confidence;
        
        // Log the decision (Audit)
        AI_Audit__c audit = new AI_Audit__c();
        audit.Appointment__c = appt.Id;
        audit.Input_Notes__c = symptoms;
        audit.Output_Specialty__c = result.specialty;
        audit.Confidence_Score__c = confidence * 100;
        audit.Reasoning__c = result.reason;
        
        String decisionType = 'Review Required';
        
        if (confidence >= 0.80) {
            decisionType = 'Auto-Assign';
            appt.Specialization__c = result.specialty;
        }
        
        if (isUrgent) {
            decisionType = 'Urgent';
            appt.Priority__c = 'High';
        }
        
        audit.Decision_Type__c = decisionType;
        
        insert audit;
        update appt;
    }
}
