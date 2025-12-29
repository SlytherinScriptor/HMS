public with sharing class BM_Billing {
    public static void createBillingForCompleted(List<Appointment__c> completedAppointments) {
        if (completedAppointments.isEmpty()) return;

        Set<Id> appointmentIds = new Set<Id>();
        for (Appointment__c appt : completedAppointments) {
            appointmentIds.add(appt.Id);
        }

        // Idempotency: Check existing billings via RM
        List<Billing__c> existingBillings = RM_Billing.getExistingBillings(appointmentIds);
        Set<Id> appointmentsWithBilling = new Set<Id>();
        for (Billing__c b : existingBillings) {
            appointmentsWithBilling.add(b.Appointment__c);
        }

        List<Billing__c> billingsToCreate = new List<Billing__c>();
        for (Appointment__c appt : completedAppointments) {
            if (!appointmentsWithBilling.contains(appt.Id)) {
                billingsToCreate.add(new Billing__c(
                    Appointment__c = appt.Id,
                    Patient__c = appt.Patient__c,
                    Status__c = 'Unpaid',
                    Total_Amount__c = 100.00, // Standard fee
                    Payment_Date__c = Date.today()
                ));
            }
        }

        if (!billingsToCreate.isEmpty()) {
            RM_Billing.insertBillings(billingsToCreate);
        }
    }
}
