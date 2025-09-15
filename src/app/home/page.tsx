'use client';

import { useState } from 'react';
import { format, isToday, isAfter, differenceInDays } from 'date-fns';
import { useAppointments } from '../../hooks/useAppointments';
import { useTasks } from '../../hooks/useTasks';
import { useCapacity } from '../../hooks/useCapacity';

export default function HomePage() {
  const { appointments, toggleAppointmentStatus } = useAppointments();
  const { tasks, toggleTaskStatus } = useTasks();
  const { getCapacityForDate, getWeeklyStats } = useCapacity();

  // Filtrar citas de hoy
  const todayAppointments = appointments.filter(apt => 
    isToday(apt.date)
  );

  // Obtener capacidad de hoy
  const todayCapacity = getCapacityForDate('2025-09-10');
  const weeklyStats = getWeeklyStats();

  // Estadísticas de pacientes nuevos vs recitados
  const newPatients = todayAppointments.filter(apt => apt.is_new_patient);
  const returningPatients = todayAppointments.filter(apt => !apt.is_new_patient);
  const spontaneousToday = todayAppointments.filter(apt => apt.is_spontaneous);

  // Agrupar tareas por paciente y ordenar por proximidad de cita
  const patientTasks = todayAppointments.map(appointment => {
    const patientTasksList = tasks.filter(task => 
      task.patient_id === appointment.patient_id
    );
    
    return {
      patient: appointment,
      tasks: patientTasksList,
      proximityDays: differenceInDays(appointment.date, new Date())
    };
  }).sort((a, b) => a.proximityDays - b.proximityDays);

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgente': return 'border-red-400 bg-red-50';
      case 'alta': return 'border-orange-400 bg-orange-50';
      case 'media': return 'border-yellow-400 bg-yellow-50';
      case 'baja': return 'border-green-400 bg-green-50';
      default: return 'border-gray-400 bg-gray-50';
    }
  };

  return (
    <div className="flex flex-col sm:flex-row min-h-screen bg-white">
      {/* Mobile Header */}
      <div className="sm:hidden bg-white shadow-md p-4 flex justify-between items-center">
        <h1 className="medical-title">HubInfecto</h1>
        <p className="medical-caption text-slate-700">Inicio</p>
      </div>

      {/* Sidebar */}
      <nav className="bg-gray-50 border-r border-gray-200 sm:w-64 p-4 sm:p-6">
        <div className="hidden sm:block mb-8">
          <h1 className="medical-title text-medical-primary">HubInfecto</h1>
          <p className="medical-caption text-slate-700">Inicio</p>
        </div>
        
        <div className="flex sm:flex-col space-x-2 sm:space-x-0 sm:space-y-2 overflow-x-auto sm:overflow-visible">
          <div className="btn-medical-primary flex-shrink-0 sm:w-full text-center">
            Inicio
          </div>
          <a href="/agenda" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-slate-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Agenda
          </a>
          <a href="/patients" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-slate-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pacientes
          </a>
          <a href="/tasks" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-slate-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pendientes
          </a>
        </div>
      </nav>

      {/* Main content */}
      <main className="flex-1 p-4 sm:p-6 bg-gray-50">
        <div className="mb-6">
          <h1 className="medical-title mb-2">
            Panel de Inicio - {format(new Date('2025-09-10'), 'dd/MM/yyyy')}
          </h1>
          <p className="medical-body text-slate-700">
            Pacientes de hoy y tareas pendientes
          </p>
        </div>

        {/* Today's appointments summary */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6 sm:mb-8">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Citas de Hoy</h2>
          <div className="medical-grid-mobile">
            {todayAppointments.map((appointment) => (
              <div key={appointment.id} className={`bg-white border border-gray-200 rounded-lg p-4 mb-4 touch-target cursor-pointer transition-all duration-200 shadow-sm ${
                appointment.status === 'completed' ? 'bg-gray-50 opacity-75' : 'hover:shadow-md hover:border-blue-300'
              }`}
              onClick={() => toggleAppointmentStatus(appointment.id)}>
                <div className="flex justify-between items-start mb-3">
                  <div className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      checked={appointment.status === 'completed'}
                      onChange={() => toggleAppointmentStatus(appointment.id)}
                      className="w-5 h-5 text-blue-600 bg-white border-2 border-gray-400 rounded focus:ring-blue-500 focus:ring-2 cursor-pointer"
                      onClick={(e) => e.stopPropagation()}
                    />
                    <h3 className={`text-lg font-bold ${
                      appointment.status === 'completed' 
                        ? 'line-through text-gray-500' 
                        : 'text-gray-900'
                    }`}>
                      {appointment.time}
                    </h3>
                  </div>
                  <div className="flex flex-col items-end space-y-1">
                    {appointment.is_spontaneous && (
                      <span className="bg-red-100 text-red-800 font-semibold px-2 py-1 rounded text-xs border border-red-200">
                        Espontánea
                      </span>
                    )}
                    {appointment.is_new_patient && (
                      <span className="bg-blue-100 text-blue-800 font-semibold px-2 py-1 rounded text-xs border border-blue-200">
                        Nuevo
                      </span>
                    )}
                    {appointment.status === 'completed' && (
                      <span className="bg-green-100 text-green-800 font-semibold px-2 py-1 rounded text-xs border border-green-200">
                        ✓ Visto
                      </span>
                    )}
                  </div>
                </div>
                <p className={`text-lg font-bold mb-2 ${
                  appointment.status === 'completed' 
                    ? 'line-through text-gray-500' 
                    : 'text-gray-900'
                }`}>
                  {appointment.patient_name}
                </p>
                <p className={`text-sm font-medium text-gray-700 mb-1 ${
                  appointment.status === 'completed' 
                    ? 'line-through text-gray-500' 
                    : ''
                }`}>
                  {appointment.doctor_name}
                </p>
                <p className={`text-sm text-gray-600 mt-2 ${
                  appointment.status === 'completed' 
                    ? 'line-through text-gray-500' 
                    : ''
                }`}>
                  {appointment.notes}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Sticky notes style pending tasks */}
        <div className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Pendientes por Paciente</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {patientTasks.map(({ patient, tasks: patientTasksList }) => (
              <div key={patient.id} className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm border-l-4 border-blue-500">
                {/* Patient header */}
                <div className="mb-3 pb-3 border-b border-gray-200">
                  <h3 className="text-lg font-bold text-gray-900 mb-1">{patient.patient_name}</h3>
                  <p className="text-sm font-medium text-gray-700">{patient.time} - {patient.doctor_name}</p>
                  <p className="text-sm text-gray-600 mt-1">{patient.notes}</p>
                </div>

                {/* Task list */}
                <div className="space-y-2">
                  {patientTasksList.length > 0 ? (
                    patientTasksList.map((task) => (
                      <div key={task.id} className="flex items-start space-x-2">
                        <input
                          type="checkbox"
                          checked={task.status === 'completada'}
                          onChange={() => toggleTaskStatus(task.id)}
                          className="w-4 h-4 text-blue-600 bg-white border-2 border-gray-400 rounded focus:ring-blue-500 focus:ring-2 cursor-pointer mt-1 flex-shrink-0"
                        />
                        <div className="flex-1 min-w-0">
                          <p className={`text-sm font-medium ${
                            task.status === 'completada' 
                              ? 'line-through text-gray-500' 
                              : 'text-gray-900'
                          }`}>
                            {task.description}
                          </p>
                          <div className="flex justify-between items-center mt-1">
                            <span className={`text-xs px-2 py-1 rounded ${getPriorityColor(task.priority)}`}>
                              {task.priority === 'urgente' ? 'Urgente' :
                               task.priority === 'alta' ? 'Alta' :
                               task.priority === 'media' ? 'Media' : 'Baja'}
                            </span>
                            <span className="text-xs font-medium text-gray-600">
                              {format(task.due_date, 'dd/MM')}
                            </span>
                          </div>
                          {task.notes && (
                            <p className="text-xs text-gray-600 mt-1">{task.notes}</p>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-gray-600 italic">Sin pendientes</p>
                  )}
                </div>

                {/* Task summary */}
                {patientTasksList.length > 0 && (
                  <div className="mt-3 pt-3 border-t border-gray-200">
                    <div className="flex justify-between text-xs text-gray-600">
                      <span>
                        {patientTasksList.filter(t => t.status === 'completada').length} / {patientTasksList.length} completadas
                      </span>
                      <span>
                        {patientTasksList.filter(t => t.priority === 'urgente').length > 0 && 
                          `⚠️ ${patientTasksList.filter(t => t.priority === 'urgente').length} urgente(s)`
                        }
                      </span>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Summary stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Citas Hoy</h3>
            <p className="text-3xl font-bold text-blue-600">{todayAppointments.length}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Tareas Urgentes</h3>
            <p className="text-3xl font-bold text-red-600">
              {tasks.filter(t => t.priority === 'urgente' && t.status === 'pendiente').length}
            </p>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Pacientes Vistos</h3>
            <p className="text-3xl font-bold text-green-600">
              {todayAppointments.filter(a => a.status === 'completed').length}
            </p>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Espontáneas</h3>
            <p className="text-3xl font-bold text-orange-600">
              {spontaneousToday.length}
            </p>
          </div>
        </div>

        {/* Capacity Management Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Today's Capacity */}
          <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Gestión de Capacidad - Hoy</h2>
            {todayCapacity && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-700">Capacidad máxima</span>
                  <span className="text-sm font-semibold text-gray-900">{todayCapacity.max_appointments} citas</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-700">Citas programadas</span>
                  <span className="text-sm font-semibold text-gray-900">{todayCapacity.current_scheduled} / {todayCapacity.max_appointments}</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-3 mt-2">
                  <div 
                    className="bg-blue-600 h-3 rounded-full transition-all duration-300" 
                    style={{ width: `${(todayCapacity.current_scheduled / todayCapacity.max_appointments) * 100}%` }}
                  ></div>
                </div>
                
                <div className="border-t border-gray-200 pt-4">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-gray-700">Espontáneas (máx {todayCapacity.max_spontaneous})</span>
                    <span className="text-sm font-semibold text-gray-900">{todayCapacity.current_spontaneous} / {todayCapacity.max_spontaneous}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-700">Predicción espontáneas</span>
                    <span className="text-sm font-semibold text-orange-600">{todayCapacity.predicted_spontaneous} pacientes</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-3 mt-2">
                    <div 
                      className="bg-orange-500 h-3 rounded-full transition-all duration-300" 
                      style={{ width: `${(todayCapacity.current_spontaneous / todayCapacity.max_spontaneous) * 100}%` }}
                    ></div>
                  </div>
                </div>

                <div className="border-t border-gray-200 pt-4">
                  <div className="text-sm text-gray-700 mb-2">Disponibilidad restante:</div>
                  <div className="text-lg font-bold text-green-600">
                    {todayCapacity.max_appointments - todayCapacity.current_scheduled} turnos disponibles
                  </div>
                  <div className="text-sm text-orange-600">
                    {todayCapacity.max_spontaneous - todayCapacity.current_spontaneous} espontáneas disponibles
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Patient Type Analysis */}
          <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Análisis de Pacientes</h2>
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold mb-3 text-gray-900">Distribución por Tipo</h3>
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-700">👤 Pacientes Nuevos</span>
                    <span className="text-sm font-bold text-blue-600">{newPatients.length}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-700">🔄 Pacientes Recitados</span>
                    <span className="text-sm font-bold text-green-600">{returningPatients.length}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-700">⚡ Consultas Espontáneas</span>
                    <span className="text-sm font-bold text-orange-600">{spontaneousToday.length}</span>
                  </div>
                </div>
              </div>

              <div className="border-t border-gray-300 pt-4">
                <h3 className="medical-body font-semibold mb-3 text-slate-900">Estadísticas Semanales</h3>
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="medical-body text-slate-700">Capacidad total semanal</span>
                    <span className="medical-body font-semibold text-slate-900">{weeklyStats.totalCapacity}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="medical-body text-slate-700">Utilización de capacidad</span>
                    <span className="medical-body font-semibold text-slate-900">{weeklyStats.capacityUtilization}%</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="medical-body text-slate-700">Turnos disponibles</span>
                    <span className="medical-body font-semibold text-medical-secondary">{weeklyStats.availableSlots}</span>
                  </div>
                </div>
              </div>

              <div className="border-t border-gray-300 pt-4">
                <h3 className="medical-body font-semibold mb-2 text-slate-900">⚠️ Alertas de Capacidad</h3>
                <div className="space-y-1">
                  {todayCapacity && todayCapacity.current_scheduled / todayCapacity.max_appointments > 0.8 && (
                    <div className="medical-body text-medical-warning">• Capacidad del día al 80%+</div>
                  )}
                  {todayCapacity && todayCapacity.current_spontaneous >= todayCapacity.max_spontaneous && (
                    <div className="medical-body text-medical-danger">• Máximo de espontáneas alcanzado</div>
                  )}
                  {todayCapacity && todayCapacity.predicted_spontaneous > todayCapacity.max_spontaneous && (
                    <div className="medical-body text-yellow-700">• Predicción supera capacidad espontánea</div>
                  )}
                  {!todayCapacity?.current_scheduled || todayCapacity.current_scheduled / todayCapacity.max_appointments < 0.8 ? (
                    <div className="medical-body text-medical-secondary">• Capacidad bajo control</div>
                  ) : null}
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}