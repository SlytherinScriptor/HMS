public with sharing class HMS_AnalyticsService {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardAnalytics() {
        Map<String, Object> result = new Map<String, Object>();

        // Count Data
        result.put('patientsCount', [SELECT COUNT() FROM Patient__c]);
        // result.put('appointmentsCount', [SELECT COUNT() FROM Appointment__c WHERE Date_Time__c > TODAY]); // Upcoming - keeping for potential future use or context
        
        // Exact "Appointments Today" as requested by UI
        result.put('appointmentsToday', [SELECT COUNT() FROM Appointment__c WHERE Date_Time__c = TODAY]);

        result.put('doctorsCount', [SELECT COUNT() FROM Doctor__c]);
        
        AggregateResult[] revenueTotalResult = [SELECT SUM(Total_Amount__c) total FROM Billing__c];
        result.put('revenueTotal', revenueTotalResult[0].get('total'));

        // REVENUE by Status
        AggregateResult[] revAgg = [
            SELECT Status__c status, SUM(Total_Amount__c) total
            FROM Billing__c
            GROUP BY Status__c
        ];
        result.put('revenueByStatus', revAgg);

        // Appointments by Specialization
        AggregateResult[] appAgg = [
            SELECT Doctor__r.Specialization__c spec, COUNT(Id) total
            FROM Appointment__c 
            WHERE Doctor__r.Specialization__c != null
            GROUP BY Doctor__r.Specialization__c
        ];
        result.put('appointmentsBySpec', appAgg);


        // Patients by Age Group (Bucketing in Apex)
        // Note: Fetching all ages to bucket in memory as SOQL bucketing is limited without formula fields
        List<Patient__c> patients = [SELECT Age__c, Gender__c, CreatedDate FROM Patient__c];
        Map<String, Integer> ageGroups = new Map<String, Integer>{
            '0-18' => 0, '19-35' => 0, '36-60' => 0, '60+' => 0
        };
        Map<String, Integer> genderMap = new Map<String, Integer>();
        Map<String, Integer> trendMap = new Map<String, Integer>();

        for(Patient__c p : patients) {
            // Age
            if (p.Age__c != null) {
                Integer age = (Integer)p.Age__c;
                if(age <= 18) ageGroups.put('0-18', ageGroups.get('0-18') + 1);
                else if(age <= 35) ageGroups.put('19-35', ageGroups.get('19-35') + 1);
                else if(age <= 60) ageGroups.put('36-60', ageGroups.get('36-60') + 1);
                else ageGroups.put('60+', ageGroups.get('60+') + 1);
            }
            
            // Gender
            String g = p.Gender__c != null ? p.Gender__c : 'Unknown';
            if(!genderMap.containsKey(g)) genderMap.put(g, 0);
            genderMap.put(g, genderMap.get(g) + 1);

            // Trend (Last 6 Months approx)
            if(p.CreatedDate != null && p.CreatedDate >= Date.today().addMonths(-6)) {
                String month = p.CreatedDate.format('MMM yyyy'); // e.g., 'Dec 2025'
                if(!trendMap.containsKey(month)) trendMap.put(month, 0);
                trendMap.put(month, trendMap.get(month) + 1);
            }
        }
        result.put('patientsByAge', ageGroups);
        result.put('patientsByGender', genderMap);
        result.put('patientTrend', trendMap);

        // Appointments by Status
        AggregateResult[] appStatusAgg = [
            SELECT Status__c status, COUNT(Id) total
            FROM Appointment__c 
            GROUP BY Status__c
        ];
        result.put('appointmentsByStatus', appStatusAgg);

        // Appointments by Day of Week
        Map<String, Integer> dayMap = new Map<String, Integer>{
            'Mon' => 0, 'Tue' => 0, 'Wed' => 0, 'Thu' => 0, 'Fri' => 0, 'Sat' => 0, 'Sun' => 0
        };
        for(Appointment__c appt : [SELECT Date_Time__c FROM Appointment__c WHERE Date_Time__c != null]) {
             String day = appt.Date_Time__c.format('EEE'); // Mon, Tue...
             if(dayMap.containsKey(day)) {
                 dayMap.put(day, dayMap.get(day) + 1);
             }
        }
        result.put('appointmentsByDay', dayMap);


        // Doctors by Specialization
        AggregateResult[] docSpecAgg = [
            SELECT Specialization__c spec, COUNT(Id) total
            FROM Doctor__c 
            WHERE Specialization__c != null
            GROUP BY Specialization__c
        ];
        result.put('doctorsBySpec', docSpecAgg);

        // Top Doctors by Workload
        AggregateResult[] topDocs = [
            SELECT Doctor__r.Last_Name__c name, COUNT(Id) total
            FROM Appointment__c
            WHERE Doctor__c != null
            GROUP BY Doctor__r.Last_Name__c
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        result.put('topDoctors', topDocs);

        return result;
    }
}
