import { LightningElement, api } from 'lwc';

export default class HmsStatsCard extends LightningElement {
    @api title;
    @api value;
    @api iconName;
    @api trend;
    @api variant; // blue, green, purple

    get cardClass() {
        // Dynamic classes for nice gradients
        const base = 'slds-p-around_medium slds-card shadow-card card-gradient ';
        switch (this.variant) {
            case 'green': return base + 'gradient-green';
            case 'purple': return base + 'gradient-purple';
            default: return base + 'gradient-blue';
        }
    }
}