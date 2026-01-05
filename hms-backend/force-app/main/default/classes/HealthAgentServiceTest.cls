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
    static void testClassifyWithHistoryCritical() {
        // Mock History: Heart Disease
        Medical_Record__c med = new Medical_Record__c(Diagnosis__c='History of Heart Disease');
        List<Medical_Record__c> history = new List<Medical_Record__c>{med};
        
        // Symptoms: Chest Pain
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('mild chest pain', history);
        
        System.assertEquals('Cardiology', result.specialty, 'History should drive specialty');
        System.assertEquals(true, result.urgent, 'Cardiac history + chest pain should be URGENT/CRITICAL');
        System.assertEquals(0.99, result.confidence, 'Confidence should be maxed out');
        System.assert(result.reason.contains('[CRITICAL]'), 'Reason should indicate CRITICAL risk');
    }

    @isTest
    static void testClassifyWithHistoryUrgent() {
        // Mock History: Asthma
        Medical_Record__c med = new Medical_Record__c(Diagnosis__c='Chronic Asthma');
        List<Medical_Record__c> history = new List<Medical_Record__c>{med};
        
        // Symptoms: Shortness of breath
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('feeling short of breath', history);
        
        System.assertEquals('Pulmonology', result.specialty, 'Asthma history should drive specialty');
        System.assertEquals(true, result.urgent, 'Asthma + breath shortage should be URGENT');
        System.assert(result.reason.contains('[URGENT]'), 'Reason should indicate URGENT risk');
    }

    @isTest
    static void testClassifyWithHistoryNoMatch() {
        // Mock History: Broken Leg (Unrelated)
        Medical_Record__c med = new Medical_Record__c(Diagnosis__c='Fractured Leg');
        List<Medical_Record__c> history = new List<Medical_Record__c>{med};
        
        // Symptoms: Headache
        HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem('bad headache', history);
        
        System.assertEquals('Neurology', result.specialty, 'History should NOT override obvious other symptoms if unrelated');
        System.assertEquals(false, result.urgent, 'Headache is not typically urgent unless context says so');
    }
}
