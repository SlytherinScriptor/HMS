public with sharing class BM_Doctor {
    public static List<Doctor_Shift__c> getShifts(Id doctorId) {
        return RM_Doctor.getShiftsByDoctor(new Set<Id>{doctorId});
    }

    public static void saveShift(Id doctorId, String day, Time startTime, Time endTime) {
        Doctor_Shift__c shift = new Doctor_Shift__c(
            Doctor__c = doctorId,
            Day_of_Week__c = day,
            Start_Time__c = startTime,
            End_Time__c = endTime
        );
        // Add basic overlap checks if needed, for now just insert
        insert shift;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMyAppointments() {
        String userEmail = UserInfo.getUserEmail();
        List<Doctor__c> doctors = RM_Doctor.getDoctorByEmail(userEmail);
        
        Map<String, Object> result = new Map<String, Object>();

        if (doctors.isEmpty()) {
            // Check if System Admin to allow "Super User" access
            Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
            if (p.Name == 'System Administrator') {
                 // Mock a doctor record for display
                 Doctor__c adminDoc = new Doctor__c(First_Name__c = UserInfo.getFirstName(), Last_Name__c = UserInfo.getLastName());
                 
                 // For Admin, fetch ALL appointments for "Today" (or a broader range if preferred, keeping it Today for consistency with Console view)
                 // We need to construct a robust query here since RM_Appointment filters by Doctor ID.
                 // We will verify if RM_Appointment method can be reused or if we need a direct query.
                 // RM_Appointment.getAppointmentsByDoctorAndDate requires a Set<Id>. 
                 // So we will do a direct query here matching the fields in RM_Appointment for consistency.
                 List<Appointment__c> allAppointments = [
                    SELECT Id, Doctor__c, Date_Time__c, Status__c, Notes__c, 
                           Patient__c, Patient__r.First_Name__c, Patient__r.Last_Name__c
                    FROM Appointment__c 
                    WHERE Date_Time__c = TODAY
                    AND Status__c != 'Cancelled'
                 ];
                 
                 result.put('doctor', adminDoc);
                 result.put('appointments', allAppointments);
                 return result;
            }
            throw new AuraHandledException('No Doctor record found for your email: ' + userEmail);
        }
        
        Id doctorId = doctors[0].Id;
        List<Appointment__c> appointments = RM_Appointment.getAppointmentsByDoctorAndDate(new Set<Id>{doctorId}, Date.today(), Date.today());
        
        result.put('doctor', doctors[0]);
        result.put('appointments', appointments);
        return result;
    }
}

