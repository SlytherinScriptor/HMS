public with sharing class HealthAgentTools {

    public class ClassificationInput {
        @InvocableVariable(label='Symptom Notes' description='The patient complaints or symptoms' required=true)
        public String notes;
    }
    
    public class ClassificationOutput {
        @InvocableVariable(label='Recommended Specialization' description='The medical specialization logic determined from symptoms')
        public String specialization;
        
        @InvocableVariable(label='Reasoning' description='Explanation for the classification')
        public String reason;
        
        @InvocableVariable(label='Confidence Score' description='Confidence score between 0 and 1')
        public Decimal confidence;
        
        @InvocableVariable(label='Urgent' description='True if the symptoms indicate a medical emergency')
        public Boolean urgent;
    }

    @InvocableMethod(label='Classify Symptoms' description='Analyzes patient notes to recommend a medical specialization.')
    public static List<ClassificationOutput> classifySymptoms(List<ClassificationInput> inputs) {
        List<ClassificationOutput> results = new List<ClassificationOutput>();
        
        for(ClassificationInput input : inputs) {
            ClassificationOutput out = new ClassificationOutput();
            HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem(input.notes);
            
            out.specialization = result.specialty;
            out.reason = result.reason;
            out.confidence = result.confidence;
            out.urgent = result.urgent;
            
            results.add(out);
        }
        
        return results;
    }
}
