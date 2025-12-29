public with sharing class HealthAgentService {
    
    public class ClassificationResult {
        public String specialty;
        public Decimal confidence;
        public String reason;
        public Boolean urgent;
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
