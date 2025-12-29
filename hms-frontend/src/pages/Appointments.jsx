import React, { useEffect, useState } from 'react';
import { getAppointments } from '../services/salesforce';

const Appointments = () => {
    const [appointments, setAppointments] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getAppointments()
            .then(setAppointments)
            .finally(() => setLoading(false));
    }, []);

    return (
        <div>
            <h1 className="text-3xl font-bold mb-6">Appointments</h1>
            {loading ? <p>Loading...</p> : (
                <div className="bg-white shadow rounded-lg overflow-hidden">
                    <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date & Time</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Notes</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                            {appointments.map((apt) => (
                                <tr key={apt.Id}>
                                    <td className="px-6 py-4 whitespace-nowrap text-gray-900">
                                        {new Date(apt.Date_Time__c).toLocaleString()}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-gray-900">
                                        {apt.Patient__r ? `${apt.Patient__r.First_Name__c} ${apt.Patient__r.Last_Name__c}` : 'Unknown'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-gray-900">
                                        {apt.Doctor__r ? `${apt.Doctor__r.First_Name__c} ${apt.Doctor__r.Last_Name__c}` : 'Unknown'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                                        ${apt.Status__c === 'Completed' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                                            {apt.Status__c}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-gray-500 text-sm max-w-xs truncate">{apt.Notes__c}</td>
                                </tr>
                            ))}
                            {appointments.length === 0 && (
                                <tr>
                                    <td colSpan="5" className="px-6 py-4 text-center text-gray-500">No appointments found.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
};

export default Appointments;
