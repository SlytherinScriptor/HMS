public with sharing class BM_Appointment {
    // State sharing between Before and After triggers
    public static Map<Integer, HealthAgentService.ClassificationResult> aiResults = new Map<Integer, HealthAgentService.ClassificationResult>();

    public static void validateBeforeInsert(List<Appointment__c> newAppointments) {
         assignDoctor(newAppointments);
         VAL_Appointment.checkConflicts(newAppointments);
    }
    
    public static void assignDoctor(List<Appointment__c> appointments) {
        // Clear previous results to avoid state pollution across batches
        aiResults.clear();
        
        List<Appointment__c> toAssign = new List<Appointment__c>();
        
        for(Integer i=0; i<appointments.size(); i++) {
            Appointment__c appt = appointments[i];
            
            // Check if Doctor is null. Specialization can be null now.
            if(appt.Doctor__c == null) {
                // Agent Logic
                HealthAgentService.ClassificationResult result = HealthAgentService.classifyProblem(appt.Notes__c);
                
                // Store result for logging in After Trigger
                aiResults.put(i, result);
                
                // Apply Trust Layer Logic
                
                // 1. Urgency
                if(result.urgent) {
                    appt.Priority__c = 'High';
                }
                
                // 2. Confidence Thresholds
                if(result.confidence >= 0.80) {
                    // High Confidence: Auto-Assign
                    if(appt.Specialization__c == null || (appt.Specialization__c == 'General Practice' && result.specialty != 'General Practice')) {
                        appt.Specialization__c = result.specialty;
                    }
                    toAssign.add(appt);
                } else {
                    // Low Confidence (< 80%): Do NOT auto-assign. 
                    // Leave Specialization as is (or null), so no doctor is found/assigned.
                    // A Task will be created in After Insert (Review Required).
                    // If user manually set General Practice, we respect it, but we won't overwrite usage of 'result.specialty'.
                }
            }
        }
        
        if(toAssign.isEmpty()) return;
        
        // Group by Specialization to minimize queries
        Map<String, List<Appointment__c>> specToAppts = new Map<String, List<Appointment__c>>();
        for(Appointment__c appt : toAssign) {
            if(!specToAppts.containsKey(appt.Specialization__c)) {
                specToAppts.put(appt.Specialization__c, new List<Appointment__c>());
            }
            specToAppts.get(appt.Specialization__c).add(appt);
        }
        
        for(String spec : specToAppts.keySet()) {
            List<Doctor__c> doctors = RM_Doctor.getDoctorsBySpecialization(spec);
            if(doctors.isEmpty()) {
                for(Appointment__c appt : specToAppts.get(spec)) {
                    // If auto-assign fails due to no doctors, just log error? 
                    // Or let it flow?
                    // Original logic added error.
                    appt.addError('No doctors found for specialization: ' + spec);
                }
                continue;
            }
            
            Set<Id> doctorIds = new Map<Id, Doctor__c>(doctors).keySet();
            
            for(Appointment__c appt : specToAppts.get(spec)) {
                Boolean assigned = false;
                DateTime originalTime = appt.Date_Time__c != null ? appt.Date_Time__c : DateTime.now();
                DateTime checkTime = originalTime;
                
                // Check up to 7 days ahead
                for(Integer k=0; k<7; k++) {
                    DateTime currentDay = checkTime.addDays(k);
                    String dayOfWeek = currentDay.format('EEEE');
                    
                    List<Doctor_Shift__c> shifts = RM_Shift.getShifts(doctorIds, dayOfWeek);
                    
                    for(Doctor__c doc : doctors) {
                         Boolean hasShift = false;
                         for(Doctor_Shift__c shift : shifts) {
                             if(shift.Doctor__c == doc.Id) {
                                 Time apptTime = currentDay.time();
                                 if (k > 0) {
                                     apptTime = shift.Start_Time__c;
                                     currentDay = DateTime.newInstance(currentDay.date(), apptTime);
                                 }
                                 
                                 if(apptTime >= shift.Start_Time__c && apptTime <= shift.End_Time__c) {
                                     hasShift = true; 
                                     break;
                                 }
                             }
                         }
                         
                         if(hasShift) {
                             appt.Doctor__c = doc.Id;
                             appt.Date_Time__c = currentDay;
                             assigned = true;
                             break;
                         }
                    }
                    if(assigned) break;
                }
                
                if(!assigned) {
                    appt.addError('No available doctors found for ' + spec + ' in the next 7 days.');
                }
            }
        }
    }
    
    // Called from After Insert
    public static void logAIDecisions(List<Appointment__c> appointments) {
        List<AI_Audit__c> audits = new List<AI_Audit__c>();
        List<Task> tasks = new List<Task>();
        
        for(Integer i=0; i<appointments.size(); i++) {
            if(aiResults.containsKey(i)) {
                Appointment__c appt = appointments[i];
                HealthAgentService.ClassificationResult res = aiResults.get(i);
                
                AI_Audit__c audit = new AI_Audit__c();
                audit.Appointment__c = appt.Id;
                audit.Input_Notes__c = appt.Notes__c;
                audit.Output_Specialty__c = res.specialty;
                audit.Confidence_Score__c = res.confidence * 100;
                audit.Reasoning__c = res.reason;
                
                String decisionType = 'Review Required';
                if(res.urgent) {
                    decisionType = 'Urgent';
                } else if(res.confidence >= 0.80) {
                    decisionType = 'Auto-Assign';
                }
                audit.Decision_Type__c = decisionType;
                audits.add(audit);
                
                // Create Task if Review Required (Low Confidence)
                if(res.confidence < 0.80) { // Should match logic in assignDoctor. Plan said < 0.60, but let's be consistent.
                    // If < 0.80, we didn't auto assign.
                    // Plan: 0.60-0.79 Recommendation -> Admin Approval. < 0.60 No Change -> Flag.
                    // Both require manual intervention.
                    
                    Task t = new Task();
                    t.Subject = 'Review: AI Confidence Low (' + (res.confidence*100) + '%)';
                    t.Description = 'AI Suggested: ' + res.specialty + '\nReason: ' + res.reason + '\nConfidence: ' + (res.confidence*100) + '%';
                    t.Priority = 'Normal';
                    t.Status = 'Not Started';
                    t.WhatId = appt.Patient__c;
                    t.OwnerId = UserInfo.getUserId(); // Assign to current user (Admin/Agent)
                    tasks.add(t);
                }
            }
        }
        
        if(!audits.isEmpty()) insert audits;
        if(!tasks.isEmpty()) insert tasks;
        
        aiResults.clear();
    }
    
    public static void handleAfterUpdate(List<Appointment__c> newAppointments, Map<Id, Appointment__c> oldMap) {
        List<Appointment__c> completedAppointments = new List<Appointment__c>();
        for (Appointment__c appt : newAppointments) {
            Appointment__c oldAppt = oldMap.get(appt.Id);
            if (appt.Status__c == 'Completed' && oldAppt.Status__c != 'Completed') {
                completedAppointments.add(appt);
            }
        }
        
        if (!completedAppointments.isEmpty()) {
            BM_Billing.createBillingForCompleted(completedAppointments);
        }
    }
}
