@isTest
private class HealthAgentServiceTest {

    @isTest
    static void testClassifyCardiology() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('Patient complains of severe chest pain and heart attack symptoms');
        System.assertEquals('Cardiology', result.specialty, 'Should classify as Cardiology');
        System.assertEquals(true, result.urgent, 'Should be urgent');
        System.assertEquals(0.95, result.confidence, 'Should have 0.95 confidence');
    }

    @isTest
    static void testClassifyNeurology() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('Patient has a severe headache and feels dizzy');
        System.assertEquals('Neurology', result.specialty, 'Should classify as Neurology');
        System.assertEquals(false, result.urgent, 'Should not be urgent');
        System.assertEquals(0.85, result.confidence, 'Should have 0.85 confidence');
    }

    @isTest
    static void testClassifyOrthopedics() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('Patient has a broken bone and knee fracture');
        System.assertEquals('Orthopedics', result.specialty, 'Should classify as Orthopedics');
        System.assertEquals(0.85, result.confidence, 'Should have 0.85 confidence');
    }

    @isTest
    static void testClassifyDefault() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('Patient feels generally unwell');
        System.assertEquals('General Practice', result.specialty, 'Should default to General Practice');
        System.assertEquals(0.50, result.confidence, 'Should have low confidence');
    }

    @isTest
    static void testClassifyNull() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem(null);
        System.assertEquals('General Practice', result.specialty, 'Null notes should default to General Practice');
        System.assertEquals(0.5, result.confidence, 'Should have low confidence');
    }
    
    @isTest
    static void testClassifyEmpty() {
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('');
        System.assertEquals('General Practice', result.specialty, 'Empty notes should default to General Practice');
        System.assertEquals(0.5, result.confidence, 'Should have low confidence');
    }
}
