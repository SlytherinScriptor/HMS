import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getDashboardStats from '@salesforce/apex/HMS_Service.getDashboardStats';
import chartJs from '@salesforce/resourceUrl/chartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class HealthDashboard extends NavigationMixin(LightningElement) {
    @track metrics = [];
    @track isLoading = true;
    wiredStatsResult; // To store the provisioned value for refreshApex

    @wire(getDashboardStats)
    wiredStats(result) {
        this.wiredStatsResult = result;
        const { error, data } = result;
        // Keep loading true until we process data
        if (data) {
            console.log('Dashboard Data Received (Fixed Mappings):', JSON.stringify(data));
            this.isLoading = false;
            const calculateTrend = (total, recent) => {
                const previous = total - recent;
                if (previous === 0) return { trend: recent > 0 ? '+100%' : '0%', class: 'trend-neutral' };
                const percent = Math.round((recent / previous) * 100);
                return {
                    trend: (percent >= 0 ? '+' : '') + percent + '%',
                    class: percent >= 0 ? 'trend-up' : 'trend-down'
                };
            };

            const patTrend = calculateTrend(data.patientsCount || 0, data.patients_new || 0);
            const apptTrend = calculateTrend(data.appointmentsToday || 0, data.appointments_new || 0); // Using appointmentsToday as total for now based on log
            const docTrend = calculateTrend(data.doctorsCount || 0, data.doctors_new || 0);

            this.metrics = [
                {
                    id: 'Patient__c',
                    label: 'Total Patients',
                    value: data.patientsCount || 0,
                    icon: 'standard:user',
                    trend: patTrend.trend,
                    trendClass: patTrend.class
                },
                {
                    id: 'Appointment__c',
                    label: 'Upcoming Appointments',
                    value: data.appointmentsToday || 0,
                    icon: 'standard:event',
                    trend: apptTrend.trend,
                    trendClass: apptTrend.class
                },
                {
                    id: 'Doctor__c',
                    label: 'Available Doctors',
                    value: data.doctorsCount || 0,
                    icon: 'standard:user_role',
                    trend: docTrend.trend,
                    trendClass: docTrend.class
                }
            ];
        } else if (error) {
            console.error('Error fetching dashboard stats:', error);
            this.metrics = [];
            this.isLoading = false;
        }
    }

    handleRefresh() {
        console.log('Refreshing Dashboard...');
        this.isLoading = true;
        refreshApex(this.wiredStatsResult)
            .then(() => {
                console.log('Refresh Complete');
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error refreshing dashboard:', error);
                this.isLoading = false;
            });
    }

    handleNav(event) {
        const id = event.currentTarget.dataset.id;
        this.setActiveNav(id);

        let pageRef = null;

        switch (id) {
            case 'patients':
                pageRef = {
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Patient__c',
                        actionName: 'list'
                    },
                    state: { filterName: 'Recent' }
                };
                break;
            case 'appointments':
                pageRef = {
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Appointment__c',
                        actionName: 'list'
                    },
                    state: { filterName: 'Recent' }
                };
                break;
            case 'doctors':
                pageRef = {
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Doctor__c',
                        actionName: 'list'
                    },
                    state: { filterName: 'Recent' }
                };
                break;
            case 'dashboard':
                // Already on dashboard
                return;
            default:
                console.log('Navigation not implemented for:', id);
                return;
        }

        if (pageRef) {
            this[NavigationMixin.Navigate](pageRef);
        }
    }

    // Charts handled in array now
    isChartJsInitialized = false;
    activeChart = null; // 'patients', 'appointments', 'doctors'

    renderedCallback() {
        if (this.isChartJsInitialized) return;
        loadScript(this, chartJs)
            .then(() => {
                this.isChartJsInitialized = true;
            })
            .catch(error => {
                console.error('Error loading Chart.js', error);
            });
    }

    handleCardClick(event) {
        const objectApiName = event.currentTarget.dataset.id;

        // Map ID to Chart Type
        if (objectApiName === 'Patient__c') {
            this.activeChart = 'patients';
            this.renderChart();
        } else if (objectApiName === 'Appointment__c') {
            this.activeChart = 'appointments';
            this.renderChart();
        } else if (objectApiName === 'Doctor__c') {
            this.activeChart = 'doctors';
            this.renderChart();
        }
    }

    // State to track chart instances to destroy them properly
    charts = [];

    renderChart() {
        if (!this.isChartJsInitialized) return;

        // Wait for DOM update
        Promise.resolve().then(() => {
            // Cleanup old charts
            this.charts.forEach(chart => {
                if (chart) chart.destroy();
            });
            this.charts = [];

            const ctx1 = this.template.querySelector('canvas.chart-1');
            const ctx2 = this.template.querySelector('canvas.chart-2');
            const ctx3 = this.template.querySelector('canvas.chart-3');

            if (!ctx1 || !ctx2 || !ctx3) return;

            if (this.activeChart === 'patients') {
                this.renderPatientCharts(ctx1, ctx2, ctx3);
            } else if (this.activeChart === 'appointments') {
                this.renderAppointmentCharts(ctx1, ctx2, ctx3);
            } else if (this.activeChart === 'doctors') {
                this.renderDoctorCharts(ctx1, ctx2, ctx3);
            }
        });
    }

    renderPatientCharts(ctx1, ctx2, ctx3) {
        // 1. Age Distribution (Bar)
        const ageData = this.wiredStatsResult.data.patientsByAge;
        this.charts.push(new window.Chart(ctx1, {
            type: 'bar',
            data: {
                labels: Object.keys(ageData),
                datasets: [{
                    label: 'Age Groups',
                    data: Object.values(ageData),
                    backgroundColor: '#00B0FF'
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Age Distribution' } }
            }
        }));

        // 2. Gender Distribution (Pie)
        const genderData = this.wiredStatsResult.data.patientsByGender || {};
        this.charts.push(new window.Chart(ctx2, {
            type: 'pie',
            data: {
                labels: Object.keys(genderData),
                datasets: [{
                    data: Object.values(genderData),
                    backgroundColor: ['#F50057', '#2979FF', '#9E9E9E']
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Gender Ratio' } }
            }
        }));

        // 3. Growth Trend (Line)
        const trendData = this.wiredStatsResult.data.patientTrend || {};
        this.charts.push(new window.Chart(ctx3, {
            type: 'line',
            data: {
                labels: Object.keys(trendData),
                datasets: [{
                    label: 'New Patients',
                    data: Object.values(trendData),
                    borderColor: '#00E676',
                    fill: false,
                    tension: 0.1
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Patient Growth Trend' } }
            }
        }));
    }

    renderAppointmentCharts(ctx1, ctx2, ctx3) {
        // 1. Status Breakdown (Doughnut)
        const agg = this.wiredStatsResult.data.appointmentsByStatus || [];
        this.charts.push(new window.Chart(ctx1, {
            type: 'doughnut',
            data: {
                labels: agg.map(a => a.status),
                datasets: [{
                    data: agg.map(a => a.total),
                    backgroundColor: ['#00E676', '#FF3D00', '#2979FF', '#FFC400'] // Completed, Cancelled, Scheduled, etc.
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Status Overview' } }
            }
        }));

        // 2. Weekly Traffic (Bar)
        const dayData = this.wiredStatsResult.data.appointmentsByDay || {};
        const daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const sortedData = daysOrder.map(day => dayData[day] || 0);

        this.charts.push(new window.Chart(ctx2, {
            type: 'bar',
            data: {
                labels: daysOrder,
                datasets: [{
                    label: 'Appointments',
                    data: sortedData,
                    backgroundColor: '#651FFF'
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Weekly Traffic Volume' } }
            }
        }));

        // 3. Empty or Future Chart
        // Leaving 3rd canvas empty or we could add another metric later
        this.charts.push(new window.Chart(ctx3, {
            type: 'bubble',
            data: { datasets: [] },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'No Data' } }
            }
        }));
    }

    renderDoctorCharts(ctx1, ctx2, ctx3) {
        // 1. Specialization (Pie)
        const agg = this.wiredStatsResult.data.doctorsBySpec || [];
        this.charts.push(new window.Chart(ctx1, {
            type: 'pie',
            data: {
                labels: agg.map(a => a.spec),
                datasets: [{
                    data: agg.map(a => a.total),
                    backgroundColor: ['#651FFF', '#00B0FF', '#00E676', '#FFC400', '#FF3D00']
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Specializations' } }
            }
        }));

        // 2. Top Doctors (Horizontal Bar)
        const topDocs = this.wiredStatsResult.data.topDoctors || [];
        this.charts.push(new window.Chart(ctx2, {
            type: 'bar',
            indexAxis: 'y',
            data: {
                labels: topDocs.map(d => 'Dr. ' + d.name),
                datasets: [{
                    label: 'Total Appointments',
                    data: topDocs.map(d => d.total),
                    backgroundColor: '#FF6D00'
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { title: { display: true, text: 'Top Doctors by Workload' } }
            }
        }));

        // 3. Clear 3rd
        this.charts.push(new window.Chart(ctx3, {
            type: 'bubble', data: { datasets: [] },
            options: { plugins: { title: { display: true, text: 'No Data' } } }
        }));
    }

    handleCloseChart() {
        this.activeChart = null;
    }

    setActiveNav(id) {
        const navItems = this.template.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            if (item.dataset.id === id) item.classList.add('active');
            else item.classList.remove('active');
        });
    }
}