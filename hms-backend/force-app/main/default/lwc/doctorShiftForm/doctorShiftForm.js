import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DoctorShiftForm extends LightningElement {
    @api recordId; // Doctor Id if placed on Doctor Record Page
    isSuccess = false;
    error;

    handleSuccess() {
        this.isSuccess = true;
        this.error = undefined;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Doctor Shift created successfully',
                variant: 'success'
            })
        );
        // Reset form or notify parent
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if (field.fieldName !== 'Doctor__c') field.reset();
            });
        }
    }

    handleError(event) {
        this.isSuccess = false;
        this.error = event.detail.message || 'Error creating shift';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: this.error,
                variant: 'error'
            })
        );
    }
}
