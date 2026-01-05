public with sharing class HealthAgentService {
    
    public class ClassificationResult {
        public String specialty;
        public Decimal confidence;
        public String reason;
        public Boolean urgent;
    }

    public static ClassificationResult classifyProblem(String notes, List<Medical_Record__c> history) {
        // Base classification
        ClassificationResult res = classifyProblem(notes);
        
        if (history == null || history.isEmpty()) {
            return res;
        }
        
        String n = (notes != null) ? notes.toLowerCase() : '';
        Boolean historyCtxUsed = false;
        
        // Analyze History
        for (Medical_Record__c record : history) {
            String diag = (record.Diagnosis__c != null) ? record.Diagnosis__c.toLowerCase() : '';
            
            // Scenario 1: Cardiac History + Chest Pain = CRITICAL
            if ((diag.contains('heart') || diag.contains('cardiac') || diag.contains('hypertension')) && 
                (n.contains('chest') || n.contains('pain') || n.contains('palpitation'))) {
                
                res.specialty = 'Cardiology';
                res.confidence = 0.99;
                res.urgent = true;
                res.reason = '[CRITICAL] Patient has history of ' + record.Diagnosis__c + ' and is reporting ' + notes + '.';
                historyCtxUsed = true;
                break; 
            }
            
            // Scenario 2: Asthma + Breathing issues = URGENT
            if ((diag.contains('asthma') || diag.contains('copd') || diag.contains('respiratory')) && 
                (n.contains('breath') || n.contains('wheez') || n.contains('air'))) {
                
                res.specialty = 'Pulmonology'; // Assuming Pulmonology exists or falls under General/Specialist
                res.confidence = 0.95;
                res.urgent = true;
                res.reason = '[URGENT] Patient with history of ' + record.Diagnosis__c + ' reporting respiratory distress.';
                historyCtxUsed = true;
                break;
            }
        }
        
        if (historyCtxUsed && !res.reason.contains('[Context Used]')) {
             // ensure we mark it if we didn't fully override the reason string above (though we did)
        } else if (!historyCtxUsed && !String.isBlank(n)) {
             // If no specific history trigger, maybe just slightly boost confidence if specialty matches?
             // Keeping simple for now to avoid over-engineering.
        }
        
        return res;
    }

    public static ClassificationResult classifyProblem(String notes) {
        ClassificationResult res = new ClassificationResult();
        res.urgent = false;

        if(String.isBlank(notes)) {
            res.specialty = 'General Practice';
            res.confidence = 0.5;
            res.reason = 'No notes provided. Defaulting to General Practice.';
            return res;
        }
        
        String n = notes.toLowerCase();
        
        if(n.contains('heart') || n.contains('chest') || n.contains('attack') || n.contains('cardio')) {
            res.specialty = 'Cardiology';
            res.confidence = 0.95;
            res.reason = 'Keywords detected indicating potential cardiac emergency (heart, chest, attack).';
            res.urgent = true;
        }
        else if(n.contains('head') || n.contains('dizzy') || n.contains('brain') || n.contains('migraine')) {
            res.specialty = 'Neurology';
            res.confidence = 0.85;
            res.reason = 'Neurological symptoms detected (head, brain, migraine).';
        }
        else if(n.contains('bone') || n.contains('joint') || n.contains('fracture') || n.contains('knee')) {
            res.specialty = 'Orthopedics';
            res.confidence = 0.85;
            res.reason = 'Orthopedic symptoms detected (bone, joint, fracture).';
        }
        else {
            res.specialty = 'General Practice';
            res.confidence = 0.50;
            res.reason = 'No specific specialty determined from notes. Recommended General Practice for initial triage.';
        }
        
        return res;
    }
}
