@isTest
private class HealthAgentToolsTest {
    
    @isTest
    static void testClassifyAction() {
        HealthAgentTools.ClassificationInput input = new HealthAgentTools.ClassificationInput();
        input.notes = 'Patient has chest pain';
        
        List<HealthAgentTools.ClassificationInput> inputs = new List<HealthAgentTools.ClassificationInput>();
        inputs.add(input);
        
        Test.startTest();
        List<HealthAgentTools.ClassificationOutput> results = HealthAgentTools.classifySymptoms(inputs);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals('Cardiology', results[0].specialization);
        System.assertEquals(true, results[0].urgent);
        System.assertEquals(0.95, results[0].confidence);
    }
}
