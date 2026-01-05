@isTest
public class HMS_TestDataFactory {
    
    public static List<Patient__c> createPatients(Integer num, Boolean doInsert) {
        List<Patient__c> patients = new List<Patient__c>();
        for(Integer i=0; i<num; i++) {
            patients.add(new Patient__c(
                First_Name__c = 'Patient ' + i,
                Last_Name__c = 'Test ' + i,
                Email__c = 'patient' + i + '@test.com',
                Phone__c = '555-000' + i,
                Gender__c = 'Male'
            ));
        }
        if(doInsert) insert patients;
        return patients;
    }

    public static List<Doctor__c> createDoctors(Integer num, Boolean doInsert) {
        List<Doctor__c> doctors = new List<Doctor__c>();
        for(Integer i=0; i<num; i++) {
            doctors.add(new Doctor__c(
                First_Name__c = 'Dr. ' + i,
                Last_Name__c = 'Test ' + i,
                Email__c = 'doctor' + i + '@test.com',
                Specialization__c = 'Cardiology' // Ensure this matches a picklist value if restricted
            ));
        }
        if(doInsert) insert doctors;
        return doctors;
    }

    public static List<Appointment__c> createAppointments(List<Patient__c> patients, List<Doctor__c> doctors, Boolean doInsert) {
        List<Appointment__c> appts = new List<Appointment__c>();
        DateTime baseTime = System.now().addDays(1);
        
        for(Integer i=0; i<patients.size(); i++) {
            Doctor__c doc = doctors.size() > i ? doctors[i] : doctors[0];
            appts.add(new Appointment__c(
                Patient__c = patients[i].Id,
                Doctor__c = doc.Id,
                Date_Time__c = baseTime.addHours(i),
                Status__c = 'Scheduled',
                Notes__c = 'Routine checkup'
            ));
        }
        if(doInsert) insert appts;
        return appts;
    }

    public static List<Doctor_Shift__c> createShiftsForDoctor(Id doctorId, Boolean doInsert) {
        List<Doctor_Shift__c> shifts = new List<Doctor_Shift__c>();
        String[] daysOfWeek = new String[]{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
        
        for(String day : daysOfWeek) {
            shifts.add(new Doctor_Shift__c(
                Doctor__c = doctorId,
                Day_of_Week__c = day,
                Start_Time__c = Time.newInstance(0, 0, 0, 0),
                End_Time__c = Time.newInstance(23, 59, 0, 0)
            ));
        }
        
        if(doInsert) insert shifts;
        return shifts;
    }
}
