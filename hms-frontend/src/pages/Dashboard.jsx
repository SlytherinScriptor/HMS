import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getPatients, getDoctors, getAppointments } from '../services/salesforce';

const Dashboard = () => {
    const [stats, setStats] = useState({ patients: 0, doctors: 0, appointments: 0 });

    useEffect(() => {
        const fetchStats = async () => {
            try {
                // Fetching all for demo counts (not efficient for real app)
                const [p, d, a] = await Promise.all([
                    getPatients(),
                    getDoctors(),
                    getAppointments()
                ]);
                setStats({ patients: p.length, doctors: d.length, appointments: a.length });
            } catch (err) {
                console.error("Failed to load stats", err);
            }
        };
        fetchStats();
    }, []);

    return (
        <div>
            <h1 className="text-3xl font-bold mb-6">Dashboard</h1>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded-lg shadow-md border border-gray-100">
                    <h2 className="text-xl font-semibold text-gray-700">Patients</h2>
                    <p className="text-4xl font-bold text-blue-600 mt-2">{stats.patients}</p>
                    <Link to="/patients" className="text-sm text-blue-500 hover:underline mt-4 block">View All Patients &rarr;</Link>
                </div>
                <div className="bg-white p-6 rounded-lg shadow-md border border-gray-100">
                    <h2 className="text-xl font-semibold text-gray-700">Doctors</h2>
                    <p className="text-4xl font-bold text-green-600 mt-2">{stats.doctors}</p>
                    <Link to="/doctors" className="text-sm text-green-500 hover:underline mt-4 block">View All Doctors &rarr;</Link>
                </div>
                <div className="bg-white p-6 rounded-lg shadow-md border border-gray-100">
                    <h2 className="text-xl font-semibold text-gray-700">Appointments</h2>
                    <p className="text-4xl font-bold text-purple-600 mt-2">{stats.appointments}</p>
                    <Link to="/appointments" className="text-sm text-purple-500 hover:underline mt-4 block">View All Appointments &rarr;</Link>
                </div>
            </div>

            <div className="mt-8 bg-blue-50 p-6 rounded-lg border border-blue-100">
                <h3 className="text-lg font-medium text-blue-800">Welcome to HMS Salesforce Edition</h3>
                <p className="text-blue-600 mt-2">
                    This application is connected to your Salesforce Developer Org.
                    Data is retrieved in real-time using Salesforce REST API.
                </p>
            </div>
        </div>
    );
};

export default Dashboard;
