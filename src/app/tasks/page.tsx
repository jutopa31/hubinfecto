'use client';

import { useState } from 'react';
import { format } from 'date-fns';
import FilterInput from '../../components/FilterInput';
import TaskModal from '../../components/TaskModal';
import { useTasks } from '../../hooks/useTasks';

export default function TasksPage() {
  const { tasks, addTask, loading } = useTasks();
  const [filter, setFilter] = useState({ patient: '', doctor: '' });
  const [showModal, setShowModal] = useState(false);

  const formatDate = (date: any) => {
    if (!date) return 'Sin fecha';
    
    try {
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        return 'Fecha inválida';
      }
      return format(dateObj, 'dd/MM/yyyy');
    } catch (error) {
      return 'Fecha inválida';
    }
  };

  const filteredTasks = tasks.filter(task => 
    (task.patient_name?.toLowerCase() || '').includes(filter.patient.toLowerCase()) &&
    task.assigned_doctor.toLowerCase().includes(filter.doctor.toLowerCase())
  );

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgente': return 'text-red-600 bg-red-100';
      case 'alta': return 'text-orange-600 bg-orange-100';
      case 'media': return 'text-yellow-600 bg-yellow-100';
      case 'baja': return 'text-green-600 bg-green-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  return (
    <div className="flex flex-col sm:flex-row min-h-screen bg-white">
      {/* Mobile Header */}
      <div className="sm:hidden bg-white shadow-md p-4 flex justify-between items-center">
        <h1 className="text-xl font-bold">HubInfecto</h1>
        <p className="text-sm text-gray-700">Pendientes</p>
      </div>

      {/* Sidebar */}
      <nav className="bg-gray-50 border-r border-gray-200 sm:w-64 p-4 sm:p-6">
        <div className="hidden sm:block mb-8">
          <h1 className="text-xl font-bold text-blue-600">HubInfecto</h1>
          <p className="text-sm text-gray-700">Pendientes</p>
        </div>
        
        <div className="flex sm:flex-col space-x-2 sm:space-x-0 sm:space-y-2 overflow-x-auto sm:overflow-visible">
          <a href="/home" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Inicio
          </a>
          <a href="/agenda" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Agenda
          </a>
          <a href="/patients" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pacientes
          </a>
          <div className="bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg flex-shrink-0 sm:w-full text-center">
            Pendientes
          </div>
        </div>
        
        <div className="mt-8 pt-6 border-t border-gray-200">
          <button 
            onClick={() => setShowModal(true)} 
            className="w-full bg-green-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-green-700 focus:ring-4 focus:ring-green-200 transition-colors duration-200"
          >
            + Agregar Tarea
          </button>
        </div>
      </nav>

      {/* Main content */}
      <main className="flex-1 p-4 sm:p-6 bg-gray-50">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Tareas Pendientes
          </h1>
          <p className="text-gray-600">
            Gestión de estudios, controles y seguimientos
          </p>
        </div>

        {/* Filters */}
        <div className="flex gap-4 mb-6">
          <FilterInput 
            label="Paciente" 
            value={filter.patient} 
            onChange={val => setFilter({...filter, patient: val})} 
          />
          <FilterInput 
            label="Doctor" 
            value={filter.doctor} 
            onChange={val => setFilter({...filter, doctor: val})} 
          />
        </div>

        {/* Tasks list */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-lg text-gray-500">Cargando tareas...</div>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredTasks.map((task) => (
              <div key={task.id} className="bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900">{task.description}</h3>
                    <p className="text-sm text-gray-600">Paciente: {task.patient_name}</p>
                    <p className="text-sm text-gray-600">Doctor: {task.assigned_doctor}</p>
                  </div>
                  <div className="flex flex-col items-end space-y-2">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${getPriorityColor(task.priority)}`}>
                      {task.priority.toUpperCase()}
                    </span>
                    <span className="text-sm text-gray-500">
                      Vence: {formatDate(task.due_date)}
                    </span>
                  </div>
                </div>
                
                <div className="flex justify-between items-center">
                  <div className="flex items-center space-x-4">
                    <span className="text-sm text-gray-500 capitalize">
                      Tipo: {task.type}
                    </span>
                    <span className={`text-sm font-medium ${
                      task.status === 'pendiente' ? 'text-yellow-600' :
                      task.status === 'en_progreso' ? 'text-blue-600' :
                      'text-green-600'
                    }`}>
                      {task.status === 'pendiente' ? 'Pendiente' :
                       task.status === 'en_progreso' ? 'En Progreso' :
                       'Completada'}
                    </span>
                  </div>
                  {task.notes && (
                    <p className="text-sm text-gray-500 italic">{task.notes}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total Tareas</h3>
            <p className="text-2xl font-bold text-gray-900">{filteredTasks.length}</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Urgentes</h3>
            <p className="text-2xl font-bold text-red-600">
              {filteredTasks.filter(t => t.priority === 'urgente').length}
            </p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Completadas</h3>
            <p className="text-2xl font-bold text-green-600">
              {filteredTasks.filter(t => t.status === 'completada').length}
            </p>
          </div>
        </div>
      </main>

      {/* Modal */}
      {showModal && (
        <TaskModal
          onSave={async (taskData) => {
            await addTask(taskData);
            setShowModal(false);
          }}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  );
}