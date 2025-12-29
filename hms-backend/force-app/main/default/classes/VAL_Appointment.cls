public with sharing class VAL_Appointment {
    public static void checkConflicts(List<Appointment__c> newAppointments) {
        Set<Id> doctorIds = new Set<Id>();
        Date minDate = Date.today().addYears(100);
        Date maxDate = Date.today().addYears(-100);
        
        for (Appointment__c appt : newAppointments) {
            if (appt.Doctor__c != null && appt.Date_Time__c != null) {
                doctorIds.add(appt.Doctor__c);
                Date apptDate = appt.Date_Time__c.date();
                if (apptDate < minDate) minDate = apptDate;
                if (apptDate > maxDate) maxDate = apptDate;
            }
        }
        
        if (doctorIds.isEmpty()) return;

        List<Appointment__c> existingAppointments = RM_Appointment.getAppointmentsByDoctorAndDate(doctorIds, minDate, maxDate);
        List<Doctor_Shift__c> shifts = RM_Doctor.getShiftsByDoctor(doctorIds);
        
        Map<Id, List<Appointment__c>> doctorAppointmentsMap = new Map<Id, List<Appointment__c>>();
        for (Appointment__c a : existingAppointments) {
            if (!doctorAppointmentsMap.containsKey(a.Doctor__c)) {
                doctorAppointmentsMap.put(a.Doctor__c, new List<Appointment__c>());
            }
            doctorAppointmentsMap.get(a.Doctor__c).add(a);
        }

        Map<Id, List<Doctor_Shift__c>> doctorShiftsMap = new Map<Id, List<Doctor_Shift__c>>();
        for (Doctor_Shift__c s : shifts) {
            if (!doctorShiftsMap.containsKey(s.Doctor__c)) {
                doctorShiftsMap.put(s.Doctor__c, new List<Doctor_Shift__c>());
            }
            doctorShiftsMap.get(s.Doctor__c).add(s);
        }

        for (Appointment__c newAppt : newAppointments) {
            if (newAppt.Doctor__c == null || newAppt.Date_Time__c == null) continue;
            
            // Check Overlaps
            if (doctorAppointmentsMap.containsKey(newAppt.Doctor__c)) {
                for (Appointment__c existing : doctorAppointmentsMap.get(newAppt.Doctor__c)) {
                    if (newAppt.Id != existing.Id && isOverlapping(newAppt, existing)) { // Allow update of same record if needed, though Trigger.new usually distinct
                         newAppt.addError('The doctor already has an appointment at this time.');
                    }
                }
            }
            
            // Check Shifts
            boolean withinShift = false;
            if (doctorShiftsMap.containsKey(newAppt.Doctor__c)) {
                String dayOfWeek = newAppt.Date_Time__c.format('EEEE');
                Time apptTime = newAppt.Date_Time__c.time();
                for (Doctor_Shift__c shift : doctorShiftsMap.get(newAppt.Doctor__c)) {
                    if (shift.Day_of_Week__c == dayOfWeek && apptTime >= shift.Start_Time__c && apptTime < shift.End_Time__c) { // Assuming 1 hour slot
                         withinShift = true;
                         break;
                    }
                }
            }
            if (!withinShift) {
                 newAppt.addError('The doctor is not available at this time (Outside of Shift).');
            }
        }
    }
    
    private static Boolean isOverlapping(Appointment__c newAppt, Appointment__c existingAppt) {
        DateTime newStart = newAppt.Date_Time__c;
        DateTime newEnd = newStart.addMinutes(30); // Default 30 mins
        DateTime existStart = existingAppt.Date_Time__c;
        DateTime existEnd = existStart.addMinutes(30);
        
        return (newStart < existEnd && newEnd > existStart);
    }
}
