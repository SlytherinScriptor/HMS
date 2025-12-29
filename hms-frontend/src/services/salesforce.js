// Salesforce Service
// Handles connection to Salesforce Org via Vite Proxy

const API_VERSION = 'v60.0';
// In Vite, we use import.meta.env
const TOKEN = import.meta.env.VITE_SF_ACCESS_TOKEN;

// Helper for Fetch
const sfFetch = async (endpoint, options = {}) => {
    if (!TOKEN) {
        throw new Error('Salesforce Access Token not found in environment variables.');
    }
    const res = await fetch(`/services/data/${API_VERSION}${endpoint}`, {
        ...options,
        headers: {
            'Authorization': `Bearer ${TOKEN}`,
            'Content-Type': 'application/json',
            ...options.headers,
        },
    });
    if (!res.ok) {
        const err = await res.json();
        console.error('Salesforce API Error:', err);
        throw new Error(err[0]?.message || 'Salesforce API Error');
    }
    return res.json();
};

export const getPatients = async () => {
    // Query fields matching what we need. Note: Using Custom Object naming conventions
    const q = 'SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, Gender__c FROM Patient__c';
    const data = await sfFetch(`/query?q=${encodeURIComponent(q)}`);
    // Map to flatter structure if needed, or return as is.
    // The previous mock had 'Name', but we have First/Last.
    return data.records.map(r => ({
        Id: r.Id,
        Name: `${r.First_Name__c} ${r.Last_Name__c}`,
        ...r
    }));
};

export const getDoctors = async () => {
    const q = 'SELECT Id, First_Name__c, Last_Name__c, Email__c, Specialization__c FROM Doctor__c';
    const data = await sfFetch(`/query?q=${encodeURIComponent(q)}`);
    return data.records.map(r => ({
        Id: r.Id,
        Name: `${r.First_Name__c} ${r.Last_Name__c}`,
        Specialty__c: r.Specialization__c, // Mapping to match mock usage expected by UI
        ...r
    }));
};

export const getAppointments = async () => {
    // Fetching related fields
    const q = `SELECT Id, Date_Time__c, Status__c, Notes__c, 
               Doctor__r.First_Name__c, Doctor__r.Last_Name__c, 
               Patient__r.First_Name__c, Patient__r.Last_Name__c 
               FROM Appointment__c`;
    const data = await sfFetch(`/query?q=${encodeURIComponent(q)}`);
    return data.records;
};

export const createPatient = async (patient) => {
    // Format patient data for Salesforce
    // Expecting patient object to have keys matching fields or we map them
    // Assuming 'patient' comes with { First_Name__c, Last_Name__c, ... } or similar.
    // If it comes as { Name, ... } we need to split.
    // For now, let's assume the UI sends the correct API names or we adjust.
    // We'll trust the payload for now but adding basic mapping if keys match standard naming.

    // Simple pass-through for demo 
    return sfFetch(`/sobjects/Patient__c`, {
        method: 'POST',
        body: JSON.stringify(patient)
    });
};
