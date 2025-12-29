// Create Doctors
List<Doctor__c> doctors = new List<Doctor__c>();
List<String> specs = new List<String>{'Cardiology', 'General Practice', 'Neurology'};
for (Integer i = 0; i < 3; i++) {
    doctors.add(new Doctor__c(First_Name__c = 'Doc' + i, Last_Name__c = 'Specialist', Specialization__c = specs[i], Email__c = 'doc'+i+'@hms.com'));
}
insert doctors;

// Create Patients
List<Patient__c> patients = new List<Patient__c>();
for (Integer i = 0; i < 5; i++) {
    patients.add(new Patient__c(First_Name__c = 'Pat' + i, Last_Name__c = 'Patient', Email__c = 'pat'+i+'@client.com', Phone__c = '555111'+i, Gender__c = 'Other'));
}
insert patients;

// Create Appointments
List<Appointment__c> appts = new List<Appointment__c>();
for (Integer i = 0; i < 10; i++) {
    // Distribute appointments over the next 10 days
    DateTime slot = DateTime.now().addDays(i);
    // Pick random doctor and patient
    Integer docIdx = Math.mod(i, 3);
    Integer patIdx = Math.mod(i, 5);
    appts.add(new Appointment__c(
        Doctor__c = doctors[docIdx].Id,
        Patient__c = patients[patIdx].Id,
        Date_Time__c = slot,
        Status__c = 'Scheduled',
        Notes__c = 'Routine Checkup'
    ));
}
insert appts;

System.debug('Sample Data Created: ' + doctors.size() + ' Docs, ' + patients.size() + ' Patients, ' + appts.size() + ' Appointments');
