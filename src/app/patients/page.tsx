'use client';

import { useState } from 'react';
import FilterInput from '../../components/FilterInput';
import PatientModal from '../../components/PatientModal';
import { usePatients } from '../../hooks/usePatients';

export default function PatientsPage() {
  const { patients, addPatient, loading } = usePatients();
  const [filter, setFilter] = useState({ name: '', dni: '' });
  const [showModal, setShowModal] = useState(false);

  const filteredPatients = patients.filter(patient => 
    patient.name.toLowerCase().includes(filter.name.toLowerCase()) &&
    patient.dni.includes(filter.dni)
  );

  return (
    <div className="flex flex-col sm:flex-row min-h-screen bg-white">
      {/* Mobile Header */}
      <div className="sm:hidden bg-white shadow-md p-4 flex justify-between items-center">
        <h1 className="text-xl font-bold">HubInfecto</h1>
        <p className="text-sm text-gray-700">Pacientes</p>
      </div>

      {/* Sidebar */}
      <nav className="bg-gray-50 border-r border-gray-200 sm:w-64 p-4 sm:p-6">
        <div className="hidden sm:block mb-8">
          <h1 className="text-xl font-bold text-blue-600">HubInfecto</h1>
          <p className="text-sm text-gray-700">Pacientes</p>
        </div>
        
        <div className="flex sm:flex-col space-x-2 sm:space-x-0 sm:space-y-2 overflow-x-auto sm:overflow-visible">
          <a href="/home" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Inicio
          </a>
          <a href="/agenda" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Agenda
          </a>
          <div className="bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg flex-shrink-0 sm:w-full text-center">
            Pacientes
          </div>
          <a href="/tasks" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pendientes
          </a>
        </div>
        
        <div className="mt-8 pt-6 border-t border-gray-200">
          <button 
            onClick={() => setShowModal(true)} 
            className="w-full bg-green-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-green-700 focus:ring-4 focus:ring-green-200 transition-colors duration-200"
          >
            + Agregar Paciente
          </button>
        </div>
      </nav>

      {/* Main content */}
      <main className="flex-1 p-4 sm:p-6 bg-gray-50">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Base de Pacientes
          </h1>
          <p className="text-gray-600">
            Gestión completa de pacientes registrados
          </p>
        </div>

        {/* Filters */}
        <div className="flex gap-4 mb-6">
          <FilterInput 
            label="Nombre" 
            value={filter.name} 
            onChange={val => setFilter({...filter, name: val})} 
          />
          <FilterInput 
            label="DNI" 
            value={filter.dni} 
            onChange={val => setFilter({...filter, dni: val})} 
          />
        </div>

        {/* Patients list */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-lg text-gray-500">Cargando pacientes...</div>
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Nombre
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    DNI
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Teléfono
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Email
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredPatients.map((patient) => (
                  <tr key={patient.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{patient.name}</div>
                      <div className="text-sm text-gray-500">{patient.address}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {patient.dni}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {patient.phone}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {patient.email}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total Pacientes</h3>
            <p className="text-2xl font-bold text-gray-900">{filteredPatients.length}</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Registrados Hoy</h3>
            <p className="text-2xl font-bold text-blue-600">0</p>
          </div>
        </div>
      </main>

      {/* Modal */}
      {showModal && (
        <PatientModal 
          onSave={addPatient} 
          onClose={() => setShowModal(false)} 
        />
      )}
    </div>
  );
}