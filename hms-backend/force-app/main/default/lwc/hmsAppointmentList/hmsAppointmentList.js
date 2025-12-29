import { LightningElement, wire, track } from 'lwc';
import getUpcomingAppointments from '@salesforce/apex/HMS_Service.getUpcomingAppointments';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    {
        label: 'Date/Time', fieldName: 'Date_Time__c', type: 'date',
        typeAttributes: { year: "numeric", month: "short", day: "2-digit", hour: "2-digit", minute: "2-digit" }
    },
    { label: 'Patient', fieldName: 'PatientSteps', type: 'text' }, // Flattened via JS
    { label: 'Doctor', fieldName: 'DoctorName', type: 'text' },   // Flattened via JS
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: [{ label: 'View Details', name: 'view' }] } }
];

export default class HmsAppointmentList extends NavigationMixin(LightningElement) {
    @track appointments = [];
    columns = COLUMNS;

    @wire(getUpcomingAppointments)
    wiredAppts({ error, data }) {
        if (data) {
            this.appointments = data.map(record => ({
                ...record,
                PatientSteps: record.Patient__r ? `${record.Patient__r.First_Name__c} ${record.Patient__r.Last_Name__c}` : '',
                DoctorName: record.Doctor__r ? `${record.Doctor__r.First_Name__c} ${record.Doctor__r.Last_Name__c}` : ''
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'view'
                }
            });
        }
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Appointment__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }
}