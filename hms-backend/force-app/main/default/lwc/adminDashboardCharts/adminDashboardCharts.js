import { LightningElement, wire } from 'lwc';
import getDashboardAnalytics from '@salesforce/apex/HMS_AnalyticsService.getDashboardAnalytics';
import chartJs from '@salesforce/resourceUrl/chartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class AdminDashboardCharts extends LightningElement {
    isChartJsInitialized = false;
    analyticsData;

    @wire(getDashboardAnalytics)
    wiredStats({ data }) {
        if (data) {
            this.analyticsData = data;
            if (this.isChartJsInitialized) this.renderCharts();
        }
    }

    renderedCallback() {
        if (this.isChartJsInitialized) return;
        loadScript(this, chartJs).then(() => {
            this.isChartJsInitialized = true;
            if (this.analyticsData) this.renderCharts();
        }).catch(error => {
            console.error('Error loading Chart.js', error);
        });
    }

    renderCharts() {
        const ctx1 = this.template.querySelector('[data-id="revenueChart"]');
        const ctx2 = this.template.querySelector('[data-id="appointmentsChart"]');

        const revenueData = this.analyticsData.revenueByStatus.map(r => r.total);
        const revenueLabels = this.analyticsData.revenueByStatus.map(r => r.status); // Fixed case from Status__c to status as per Apex alias

        new Chart(ctx1, {
            type: 'doughnut',
            data: {
                labels: revenueLabels,
                datasets: [{
                    data: revenueData,
                    backgroundColor: ['#00C853', '#FFD600', '#D50000']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { labels: { color: 'white' } },
                    title: { display: true, text: 'Revenue by Status', color: 'white' }
                }
            }
        });

        const specData = this.analyticsData.appointmentsBySpec.map(r => r.total);
        const specLabels = this.analyticsData.appointmentsBySpec.map(r => r.spec);

        new Chart(ctx2, {
            type: 'bar',
            data: {
                labels: specLabels,
                datasets: [{
                    label: 'Appointments',
                    data: specData,
                    backgroundColor: '#00B0FF'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { labels: { color: 'white' } },
                    title: { display: true, text: 'Appointments by Specialization', color: 'white' }
                },
                scales: {
                    x: { ticks: { color: 'white' }, grid: { color: '#444' } },
                    y: { ticks: { color: 'white' }, grid: { color: '#444' } }
                }
            }
        });
    }
}
