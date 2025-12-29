public with sharing class BM_Patient {
    @AuraEnabled(cacheable=true)
    public static List<TimelineItem> getPatientTimeline(Id patientId) {
        List<TimelineItem> timeline = new List<TimelineItem>();
        
        for(Appointment__c appt : [SELECT Id, Date_Time__c, Status__c, Doctor__r.Last_Name__c FROM Appointment__c WHERE Patient__c = :patientId]) {
            TimelineItem item = new TimelineItem();
            item.id = appt.Id;
            item.itemDate = appt.Date_Time__c;
            item.type = 'Appointment';
            item.title = 'Appointment with Dr. ' + (appt.Doctor__r.Last_Name__c != null ? appt.Doctor__r.Last_Name__c : 'Unknown');
            item.description = 'Status: ' + appt.Status__c;
            item.icon = 'standard:event';
            timeline.add(item);
        }

       for(Medical_Record__c med : [SELECT Id, Visit_Date__c, Diagnosis__c, Doctor__r.Last_Name__c FROM Medical_Record__c WHERE Patient__c = :patientId]) {
            TimelineItem item = new TimelineItem();
            item.id = med.Id;
            item.itemDate = med.Visit_Date__c; // Assumes DateTime or Date auto-converts, may need casting if Date
            item.type = 'Medical Record';
            item.title = 'Diagnosis: ' + med.Diagnosis__c;
            item.description = 'Dr. ' + (med.Doctor__r.Last_Name__c != null ? med.Doctor__r.Last_Name__c : '');
            item.icon = 'standard:medical_history';
            timeline.add(item);
        }
        
        for(Billing__c bill : [SELECT Id, CreatedDate, Status__c, Total_Amount__c FROM Billing__c WHERE Patient__c = :patientId AND Status__c != 'Paid']) {
            TimelineItem item = new TimelineItem();
            item.id = bill.Id;
            item.itemDate = bill.CreatedDate;
            item.type = 'Billing';
            item.title = 'Bill Due: $' + bill.Total_Amount__c;
            item.description = 'Status: ' + bill.Status__c;
            item.icon = 'standard:currency';
            timeline.add(item);
        }

        timeline.sort();
        return timeline; 
    }

    public class TimelineItem implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public DateTime itemDate;
        @AuraEnabled public String type;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String icon;

        public Integer compareTo(Object compareTo) {
            TimelineItem other = (TimelineItem) compareTo;
            if (this.itemDate == other.itemDate) return 0;
            if (this.itemDate < other.itemDate) return 1; // Descending Order
            return -1;
        }
    }
}
