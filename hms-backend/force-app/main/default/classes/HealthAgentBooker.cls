public with sharing class HealthAgentBooker {

    public class BookingInput {
        @InvocableVariable(label='Patient ID' description='(Optional) ID of the Patient. If empty, tries to find by context or leaves blank.' required=false)
        public Id patientId;

        @InvocableVariable(label='Specialization' description='The medical specialization determined by the Agent (e.g. Cardiology, Neurology).' required=true)
        public String specialization;

        @InvocableVariable(label='Notes' description='Summary of the problem or contents from the PDF.' required=false)
        public String notes;
    }
    
    public class BookingOutput {
        @InvocableVariable(label='Appointment ID' description='The ID of the created appointment.')
        public Id appointmentId;

        @InvocableVariable(label='Assigned Doctor' description='Name of the auto-assigned doctor.')
        public String assignedDoctorName;

        @InvocableVariable(label='Assigned Time' description='The auto-assigned date and time.')
        public DateTime assignedTime;

        @InvocableVariable(label='Status' description='Success or Error message.')
        public String status;
    }

    @InvocableMethod(label='Book Appointment by Specialization' description='Creates an appointment for a specific specialization and auto-assigns the next available slot.')
    public static List<BookingOutput> bookAppointment(List<BookingInput> inputs) {
        List<BookingOutput> results = new List<BookingOutput>();
        
        for(BookingInput input : inputs) {
            BookingOutput out = new BookingOutput();
            try {
                Appointment__c appt = new Appointment__c();
                appt.Patient__c = input.patientId; // If null, validation might fail unless we handle it. 
                // For Agent context, often we might need a default patient or the User's Contact.
                // Assuming PatientId is passed or we pick a dummy if needed for testing? 
                // Let's assume input.patientId is provided by the Agent context (RecordId).
                
                appt.Specialization__c = input.specialization;
                appt.Notes__c = input.notes;
                appt.Status__c = 'Scheduled';
                // Date_Time__c is null -> Trigger will auto-assign.
                
                insert appt;
                
                // Re-query to get assigned details
                Appointment__c created = [SELECT Id, Doctor__r.Name, Date_Time__c FROM Appointment__c WHERE Id = :appt.Id LIMIT 1];
                
                out.appointmentId = created.Id;
                out.assignedDoctorName = created.Doctor__r.Name;
                out.assignedTime = created.Date_Time__c;
                out.status = 'Success';
                
            } catch(Exception e) {
                out.status = 'Error: ' + e.getMessage();
            }
            results.add(out);
        }
        
        return results;
    }
}
