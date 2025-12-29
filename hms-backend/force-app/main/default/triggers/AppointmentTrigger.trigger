trigger AppointmentTrigger on Appointment__c (before insert, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            APT_AppointmentHandler.beforeInsert(Trigger.new);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            APT_AppointmentHandler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            APT_AppointmentHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}