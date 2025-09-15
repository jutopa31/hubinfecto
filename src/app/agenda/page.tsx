'use client';

import { useState } from 'react';
import { format, addDays, startOfWeek, endOfWeek, isSameDay, isToday } from 'date-fns';
import { es } from 'date-fns/locale';
import { useAppointments } from '../../hooks/useAppointments';

export default function AgendaPage() {
  const { appointments, toggleAppointmentStatus } = useAppointments();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<'week' | 'month'>('week');

  // Generar solo días laborables (lunes a viernes)
  const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 });
  const weekDays = Array.from({ length: 5 }, (_, i) => addDays(weekStart, i)); // Solo 5 días laborables

  // Filtrar citas por día
  const getAppointmentsForDay = (date: Date) => {
    return appointments.filter(apt => isSameDay(apt.date, date));
  };

  const goToPreviousWeek = () => {
    setCurrentDate(addDays(currentDate, -7));
  };

  const goToNextWeek = () => {
    setCurrentDate(addDays(currentDate, 7));
  };

  return (
    <div className="flex flex-col sm:flex-row min-h-screen bg-white">
      {/* Mobile Header */}
      <div className="sm:hidden bg-white shadow-md p-4 flex justify-between items-center">
        <h1 className="text-xl font-bold">HubInfecto</h1>
        <p className="text-sm text-gray-700">Agenda</p>
      </div>

      {/* Sidebar */}
      <nav className="bg-gray-50 border-r border-gray-200 sm:w-64 p-4 sm:p-6">
        <div className="hidden sm:block mb-8">
          <h1 className="text-xl font-bold text-blue-600">HubInfecto</h1>
          <p className="text-sm text-gray-700">Agenda</p>
        </div>
        
        <div className="flex sm:flex-col space-x-2 sm:space-x-0 sm:space-y-2 overflow-x-auto sm:overflow-visible">
          <a href="/home" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Inicio
          </a>
          <div className="bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg flex-shrink-0 sm:w-full text-center">
            Agenda
          </div>
          <a href="/patients" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pacientes
          </a>
          <a href="/tasks" className="touch-target flex-shrink-0 sm:w-full text-center sm:text-left bg-white text-gray-800 font-semibold rounded-lg hover:bg-blue-50 hover:text-blue-700 transition-colors border border-gray-200 shadow-sm">
            Pendientes
          </a>
        </div>
      </nav>

      {/* Main content */}
      <main className="flex-1 p-4 sm:p-6 bg-gray-50">
        <div className="mb-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
            <h1 className="text-2xl font-bold text-gray-900 mb-4 sm:mb-0">
              Agenda Semanal
            </h1>
            <div className="flex items-center space-x-4">
              <button
                onClick={goToPreviousWeek}
                className="bg-white border border-gray-200 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                ← Anterior
              </button>
              <span className="text-sm font-semibold text-gray-900">
                {format(weekStart, 'dd MMM', { locale: es })} - {format(addDays(weekStart, 4), 'dd MMM yyyy', { locale: es })}
                <span className="text-xs text-gray-600 ml-2">(Lun-Vie)</span>
              </span>
              <button
                onClick={goToNextWeek}
                className="bg-white border border-gray-200 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Siguiente →
              </button>
            </div>
          </div>
        </div>

        {/* Vista semanal - Solo días laborables */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 lg:gap-6">
          {weekDays.map((day, index) => {
            const dayAppointments = getAppointmentsForDay(day);
            const isCurrentDay = isToday(day);

            return (
              <div
                key={index}
                className={`bg-white border border-gray-200 rounded-lg p-4 min-h-96 ${
                  isCurrentDay ? 'ring-2 ring-blue-500 border-blue-300' : ''
                }`}
              >
                {/* Encabezado del día */}
                <div className="mb-4 pb-2 border-b border-gray-200">
                  <h3 className={`text-sm font-semibold ${
                    isCurrentDay ? 'text-blue-600' : 'text-gray-700'
                  }`}>
                    {format(day, 'EEEE', { locale: es })}
                  </h3>
                  <p className={`text-lg font-bold ${
                    isCurrentDay ? 'text-blue-600' : 'text-gray-900'
                  }`}>
                    {format(day, 'dd', { locale: es })}
                  </p>
                </div>

                {/* Citas del día */}
                <div className="space-y-2">
                  {dayAppointments.length > 0 ? (
                    dayAppointments.map((appointment) => (
                      <div
                        key={appointment.id}
                        className={`p-3 rounded-lg cursor-pointer transition-all duration-200 border ${
                          appointment.status === 'completed' 
                            ? 'bg-gray-50 border-gray-300 opacity-75' 
                            : 'bg-blue-50 border-blue-200 hover:bg-blue-100'
                        }`}
                        onClick={() => toggleAppointmentStatus(appointment.id)}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <span className={`text-sm font-semibold ${
                            appointment.status === 'completed' 
                              ? 'line-through text-gray-500' 
                              : 'text-gray-900'
                          }`}>
                            {appointment.time}
                          </span>
                          <input
                            type="checkbox"
                            checked={appointment.status === 'completed'}
                            onChange={() => toggleAppointmentStatus(appointment.id)}
                            className="w-4 h-4 text-blue-600 bg-white border-2 border-gray-400 rounded focus:ring-blue-500 focus:ring-2 cursor-pointer"
                            onClick={(e) => e.stopPropagation()}
                          />
                        </div>
                        
                        <p className={`text-sm font-medium mb-1 ${
                          appointment.status === 'completed' 
                            ? 'line-through text-gray-500' 
                            : 'text-gray-900'
                        }`}>
                          {appointment.patient_name}
                        </p>
                        
                        <p className={`text-xs text-gray-600 mb-2 ${
                          appointment.status === 'completed' ? 'line-through' : ''
                        }`}>
                          {appointment.doctor_name}
                        </p>
                        
                        <p className={`text-xs ${
                          appointment.status === 'completed' 
                            ? 'line-through text-gray-500' 
                            : 'text-gray-600'
                        }`}>
                          {appointment.notes}
                        </p>

                        {/* Badges */}
                        <div className="flex flex-wrap gap-1 mt-2">
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
                    ))
                  ) : (
                    <p className="text-sm text-gray-500 italic text-center mt-8">
                      Sin citas programadas
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* Resumen del día */}
        <div className="mt-8 bg-white border border-gray-200 rounded-lg p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Resumen Semanal</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-blue-600">
                {appointments.filter(apt => 
                  weekDays.some(day => isSameDay(apt.date, day))
                ).length}
              </p>
              <p className="text-sm text-gray-700">Total Citas</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-green-600">
                {appointments.filter(apt => 
                  weekDays.some(day => isSameDay(apt.date, day)) && apt.status === 'completed'
                ).length}
              </p>
              <p className="text-sm text-gray-700">Completadas</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-orange-600">
                {appointments.filter(apt => 
                  weekDays.some(day => isSameDay(apt.date, day)) && apt.is_spontaneous
                ).length}
              </p>
              <p className="text-sm text-gray-700">Espontáneas</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-blue-600">
                {appointments.filter(apt => 
                  weekDays.some(day => isSameDay(apt.date, day)) && apt.is_new_patient
                ).length}
              </p>
              <p className="text-sm text-gray-700">Nuevos Pacientes</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}