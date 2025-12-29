import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class HmsPatientQuickAdd extends LightningElement {

    handleSuccess(event) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Patient registered successfully! ID: ' + event.detail.id,
            variant: 'success',
        });
        this.dispatchEvent(evt);

        // Reset form fields if needed or allow standard behavior
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    handleError(event) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Error creating patient: ' + event.detail.message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}