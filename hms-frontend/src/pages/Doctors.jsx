import React, { useEffect, useState } from 'react';
import { getDoctors } from '../services/salesforce';

const Doctors = () => {
    const [doctors, setDoctors] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getDoctors()
            .then(setDoctors)
            .finally(() => setLoading(false));
    }, []);

    return (
        <div>
            <h1 className="text-3xl font-bold mb-6">Doctors</h1>
            {loading ? <p>Loading...</p> : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {doctors.map(doc => (
                        <div key={doc.Id} className="bg-white p-6 rounded-lg shadow border border-gray-200 hover:shadow-lg transition">
                            <div className="flex items-center space-x-4">
                                <div className="h-12 w-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl">
                                    {doc.First_Name__c?.[0]}{doc.Last_Name__c?.[0]}
                                </div>
                                <div>
                                    <h2 className="text-lg font-bold text-gray-900">{doc.Name}</h2>
                                    <p className="text-sm text-green-600 font-medium">{doc.Specialization__c}</p>
                                </div>
                            </div>
                            <div className="mt-4 pt-4 border-t border-gray-100 text-sm text-gray-500">
                                <p>Email: {doc.Email__c}</p>
                            </div>
                        </div>
                    ))}
                    {doctors.length === 0 && <p className="text-gray-500">No doctors found.</p>}
                </div>
            )}
        </div>
    );
};

export default Doctors;
