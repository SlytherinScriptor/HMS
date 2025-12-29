import React, { useEffect, useState } from 'react';
import { getPatients, createPatient } from '../services/salesforce';

const Patients = () => {
    const [patients, setPatients] = useState([]);
    const [loading, setLoading] = useState(true);
    const [formData, setFormData] = useState({
        First_Name__c: '',
        Last_Name__c: '',
        Email__c: '',
        Phone__c: '',
        Gender__c: ''
    });

    const loadPatients = async () => {
        setLoading(true);
        try {
            const data = await getPatients();
            setPatients(data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadPatients();
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await createPatient(formData);
            alert('Patient created successfully!');
            setFormData({ First_Name__c: '', Last_Name__c: '', Email__c: '', Phone__c: '', Gender__c: '' });
            loadPatients();
        } catch (err) {
            alert('Error creating patient: ' + err.message);
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-3xl font-bold">Patients</h1>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2">
                    {loading ? <p>Loading...</p> : (
                        <div className="bg-white shadow rounded-lg overflow-hidden">
                            <table className="min-w-full divide-y divide-gray-200">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Gender</th>
                                    </tr>
                                </thead>
                                <tbody className="bg-white divide-y divide-gray-200">
                                    {patients.map((p) => (
                                        <tr key={p.Id}>
                                            <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{p.Name}</td>
                                            <td className="px-6 py-4 whitespace-nowrap text-gray-500">{p.Email__c}</td>
                                            <td className="px-6 py-4 whitespace-nowrap text-gray-500">{p.Phone__c}</td>
                                            <td className="px-6 py-4 whitespace-nowrap text-gray-500">{p.Gender__c}</td>
                                        </tr>
                                    ))}
                                    {patients.length === 0 && (
                                        <tr>
                                            <td colSpan="4" className="px-6 py-4 text-center text-gray-500">No patients found.</td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>

                <div className="bg-white p-6 rounded-lg shadow-md h-fit">
                    <h2 className="text-xl font-bold mb-4">Add New Patient</h2>
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700">First Name</label>
                            <input
                                type="text"
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 border p-2"
                                value={formData.First_Name__c}
                                onChange={e => setFormData({ ...formData, First_Name__c: e.target.value })}
                                required
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Last Name</label>
                            <input
                                type="text"
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 border p-2"
                                value={formData.Last_Name__c}
                                onChange={e => setFormData({ ...formData, Last_Name__c: e.target.value })}
                                required
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Email</label>
                            <input
                                type="email"
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 border p-2"
                                value={formData.Email__c}
                                onChange={e => setFormData({ ...formData, Email__c: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Phone</label>
                            <input
                                type="text"
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 border p-2"
                                value={formData.Phone__c}
                                onChange={e => setFormData({ ...formData, Phone__c: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Gender</label>
                            <select
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 border p-2"
                                value={formData.Gender__c}
                                onChange={e => setFormData({ ...formData, Gender__c: e.target.value })}
                            >
                                <option value="">Select...</option>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <button type="submit" className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition">
                            Save Patient
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Patients;
