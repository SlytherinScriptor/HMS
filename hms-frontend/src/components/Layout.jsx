import React from 'react';
import { Link, Outlet } from 'react-router-dom';

const Layout = () => {
    return (
        <div className="min-h-screen flex flex-col font-sans text-gray-900">
            <header className="bg-blue-600 text-white shadow-md">
                <div className="container mx-auto px-4 py-4 flex justify-between items-center">
                    <Link to="/" className="text-2xl font-bold tracking-tight hover:text-blue-100 transition">
                        HMS <span className="text-blue-200 text-sm font-normal">Salesforce Edition</span>
                    </Link>
                    <nav>
                        <ul className="flex space-x-6">
                            <li><Link to="/" className="hover:text-blue-200 transition font-medium">Dashboard</Link></li>
                            <li><Link to="/patients" className="hover:text-blue-200 transition font-medium">Patients</Link></li>
                            <li><Link to="/doctors" className="hover:text-blue-200 transition font-medium">Doctors</Link></li>
                            <li><Link to="/appointments" className="hover:text-blue-200 transition font-medium">Appointments</Link></li>
                        </ul>
                    </nav>
                </div>
            </header>

            <main className="flex-grow container mx-auto px-4 py-8">
                <Outlet />
            </main>

            <footer className="bg-gray-100 text-gray-500 py-6 text-center border-t border-gray-200">
                <p>© 2025 Hospital Management System. Built with React & Salesforce.</p>
            </footer>
        </div>
    );
};

export default Layout;
