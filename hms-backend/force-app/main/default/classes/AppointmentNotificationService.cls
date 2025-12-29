public with sharing class AppointmentNotificationService {
    
    public static void sendNotifications(List<Appointment__c> newAppointments) {
        Set<Id> patientIds = new Set<Id>();
        Set<Id> doctorIds = new Set<Id>();
        
        for(Appointment__c appt : newAppointments) {
            patientIds.add(appt.Patient__c);
            doctorIds.add(appt.Doctor__c);
        }
        
        Map<Id, Patient__c> patients = new Map<Id, Patient__c>([SELECT Id, First_Name__c, Last_Name__c, Email__c FROM Patient__c WHERE Id IN :patientIds]);
        Map<Id, Doctor__c> doctors = new Map<Id, Doctor__c>([SELECT Id, First_Name__c, Last_Name__c, Email__c FROM Doctor__c WHERE Id IN :doctorIds]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for(Appointment__c appt : newAppointments) {
            Patient__c p = patients.get(appt.Patient__c);
            Doctor__c d = doctors.get(appt.Doctor__c);
            
            if(p != null && d != null && p.Email__c != null && d.Email__c != null) {
                // Email to Patient
                emails.add(createEmail(p.Email__c, 'Appointment Confirmed: Dr. ' + d.Last_Name__c, 'Dear ' + p.First_Name__c + ',\n\nYour appointment with Dr. ' + d.Last_Name__c + ' is confirmed for ' + appt.Date_Time__c + '.\n\nThank you,\nHMS Team', appt, d.Last_Name__c));
                
                // Email to Doctor
                emails.add(createEmail(d.Email__c, 'New Appointment: ' + p.First_Name__c + ' ' + p.Last_Name__c, 'Dear Dr. ' + d.Last_Name__c + ',\n\nYou have a new appointment with ' + p.First_Name__c + ' ' + p.Last_Name__c + ' on ' + appt.Date_Time__c + '.\n\nThank you,\nHMS Team', appt, p.First_Name__c + ' ' + p.Last_Name__c));
            }
        }
        
        if(!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Failed to send email notifications: ' + e.getMessage());
            }
        }
    }
    
    private static Messaging.SingleEmailMessage createEmail(String toAddress, String subject, String body, Appointment__c appt, String attendeeName) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toAddress });
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        
        // Setup ICS attachment
        Messaging.EmailFileAttachment ics = new Messaging.EmailFileAttachment();
        ics.setFileName('appointment.ics');
        ics.setBody(Blob.valueOf(generateICS(appt, attendeeName)));
        ics.setContentType('text/calendar');
        
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { ics });
        
        return mail;
    }
    
    private static String generateICS(Appointment__c appt, String attendeeName) {
        // Simple ICS Generation logic
        // Ideally needs proper formatting for Dates (yyyyMMddTHHmmssZ)
        // For POC we stick to a basic structure
        String dtStart = appt.Date_Time__c != null ? appt.Date_Time__c.format('yyyyMMdd\'T\'HHmmss\'Z\'') : '';
        String dtEnd = appt.Date_Time__c != null ? appt.Date_Time__c.addMinutes(30).format('yyyyMMdd\'T\'HHmmss\'Z\'') : '';
        
        return 'BEGIN:VCALENDAR\n' +
               'VERSION:2.0\n' +
               'PRODID:-//HMS//Appointment//EN\n' +
               'BEGIN:VEVENT\n' +
               'UID:' + appt.Id + '\n' +
               'DTSTAMP:' + System.now().format('yyyyMMdd\'T\'HHmmss\'Z\'') + '\n' +
               'DTSTART:' + dtStart + '\n' +
               'DTEND:' + dtEnd + '\n' +
               'SUMMARY:Appointment with ' + attendeeName + '\n' +
               'DESCRIPTION:HMS Appointment\n' +
               'END:VEVENT\n' +
               'END:VCALENDAR';
    }
}