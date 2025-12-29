// Create a Doctor
Doctor__c dr = new Doctor__c(
    First_Name__c = 'Gregory',
    Last_Name__c = 'House',
    Email__c = 'dr.house@hms.com',
    Specialization__c = 'Cardiology' // Valid value from metadata
);
insert dr;

// Create Shifts for Doctor (Next 7 days, Morning and Evening)
List<Doctor_Shift__c> shifts = new List<Doctor_Shift__c>();
Date today = Date.today();
for(Integer i=0; i<7; i++) {
    Date shiftDate = today.addDays(i);
    DateTime dt = DateTime.newInstance(shiftDate, Time.newInstance(0,0,0,0));
    String dayOfWeek = dt.format('EEEE');
    
    // Morning Shift 8-12
    shifts.add(new Doctor_Shift__c(
        Doctor__c = dr.Id,
        Day_of_Week__c = dayOfWeek,
        Start_Time__c = Time.newInstance(8, 0, 0, 0),
        End_Time__c = Time.newInstance(12, 0, 0, 0)
    ));
    
    // Evening Shift 14-18
    shifts.add(new Doctor_Shift__c(
        Doctor__c = dr.Id,
        Day_of_Week__c = dayOfWeek,
        Start_Time__c = Time.newInstance(14, 0, 0, 0),
        End_Time__c = Time.newInstance(18, 0, 0, 0)
    ));
}
insert shifts;

// Create a Patient
Patient__c pat = new Patient__c(
    First_Name__c = 'John',
    Last_Name__c = 'Doe',
    Email__c = 'johndoe@test.com',
    Phone__c = '0987654321',
    DOB__c = Date.newInstance(1985, 5, 20), // 40ish
    Gender__c = 'Male'
    // Address__c = '221B Baker St' // Field not found
);
insert pat;

// Create Medical History (Past)
List<Appointment__c> appts = new List<Appointment__c>();
List<Medical_Record__c> records = new List<Medical_Record__c>();
List<Billing__c> bills = new List<Billing__c>();

// 1 month ago - Initial Visit
Date date1 = today.addDays(-30);
Appointment__c appt1 = new Appointment__c(
    Patient__c = pat.Id,
    Doctor__c = dr.Id,
    Date_Time__c = DateTime.newInstance(date1, Time.newInstance(9, 30, 0, 0)),
    Status__c = 'Completed'
);
appts.add(appt1);

// 2 weeks ago - Follow up
Date date2 = today.addDays(-14);
Appointment__c appt2 = new Appointment__c(
    Patient__c = pat.Id,
    Doctor__c = dr.Id,
    Date_Time__c = DateTime.newInstance(date2, Time.newInstance(10, 0, 0, 0)),
    Status__c = 'Completed'
);
appts.add(appt2);

// Tomorrow - Scheduled
Date date3 = today.addDays(1);
Appointment__c appt3 = new Appointment__c(
    Patient__c = pat.Id,
    Doctor__c = dr.Id,
    Date_Time__c = DateTime.newInstance(date3, Time.newInstance(11, 15, 0, 0)),
    Status__c = 'Scheduled'
);
appts.add(appt3);

insert appts;

// Create Medical Records linked to completed appts
Medical_Record__c med1 = new Medical_Record__c(
    Patient__c = pat.Id,
    Doctor__c = dr.Id, 
    // Appointment__c = appt1.Id, // Field does not exist
    Visit_Date__c = date1,
    Diagnosis__c = 'Leg Pain',
    Prescription__c = 'Ibuprofen 400mg'
);
records.add(med1);

Medical_Record__c med2 = new Medical_Record__c(
    Patient__c = pat.Id,
    Doctor__c = dr.Id,
    // Appointment__c = appt2.Id, // Field does not exist
    Visit_Date__c = date2,
    Diagnosis__c = 'Leg Pain Resolved',
    // Treatment__c = 'Physical Therapy recommended',
    Prescription__c = 'None'
);
records.add(med2);

insert records;

// Create Billing
Billing__c bill1 = new Billing__c(
    Patient__c = pat.Id,
    Appointment__c = appt1.Id,
    Total_Amount__c = 150.00,
    Status__c = 'Paid',
    Payment_Date__c = date1
);
bills.add(bill1);

Billing__c bill2 = new Billing__c(
    Patient__c = pat.Id,
    Appointment__c = appt2.Id,
    Total_Amount__c = 100.00,
    Status__c = 'Unpaid' // This should show up in timeline
    // Due_Date__c = date2.addDays(30)
);
bills.add(bill2);

insert bills;

System.debug('Test Data Created. Patient: ' + pat.Id + ', Doctor: ' + dr.Id);
