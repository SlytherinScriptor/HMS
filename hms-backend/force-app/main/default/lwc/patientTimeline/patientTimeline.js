import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPatientTimeline from '@salesforce/apex/HMS_Service.getPatientTimeline';

export default class PatientTimeline extends NavigationMixin(LightningElement) {
    @api recordId; // Patient Record Id
    @track timelineItems;
    isLoading = true;
    error;

    @wire(getPatientTimeline, { patientId: '$recordId' })
    wiredTimeline({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.timelineItems = data.map(item => {
                let cssClass = 'slds-timeline__item_expandable ';
                let iconName = item.icon;

                if (item.type === 'Appointment') {
                    cssClass += 'timeline-item-appointment';
                } else if (item.type === 'Medical Record') {
                    cssClass += 'timeline-item-medical';
                } else if (item.type === 'Billing') {
                    cssClass += 'timeline-item-billing';
                }

                return {
                    ...item,
                    cssClass: cssClass,
                    relativeDate: this.subtractDate(item.itemDate),
                    isAppointment: item.type === 'Appointment',
                    isMedical: item.type === 'Medical Record',
                    isBilling: item.type === 'Billing'
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.timelineItems = undefined;
            this.isLoading = false;
        }
    }

    subtractDate(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays === 1) return 'Today';
        if (diffDays === 2) return 'Yesterday';
        if (diffDays > 30) return Math.floor(diffDays / 30) + ' months ago';

        return diffDays + ' days ago';
    }

    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}
