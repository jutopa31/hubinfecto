import { format, eachDayOfInterval, startOfMonth, endOfMonth, isToday, isSameMonth } from 'date-fns';
import type { Appointment } from '../types';

interface MonthlyViewProps {
  appointments: Appointment[];
  currentDate: Date;
}

export default function MonthlyView({ appointments, currentDate }: MonthlyViewProps) {
  const monthDays = eachDayOfInterval({ 
    start: startOfMonth(currentDate), 
    end: endOfMonth(currentDate) 
  });

  // Create a 6x7 grid (42 days) to show full weeks
  const startDate = startOfMonth(currentDate);
  const endDate = endOfMonth(currentDate);
  const calendarDays = eachDayOfInterval({
    start: new Date(startDate.getFullYear(), startDate.getMonth(), 1 - startDate.getDay()),
    end: new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate() + (6 - endDate.getDay()))
  });

  const weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  return (
    <div className="bg-white rounded-lg shadow">
      {/* Header with day names */}
      <div className="grid grid-cols-7 gap-px bg-gray-200">
        {weekDays.map(day => (
          <div key={day} className="bg-gray-50 px-3 py-2 text-center text-sm font-medium text-gray-700">
            {day}
          </div>
        ))}
      </div>
      
      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-px bg-gray-200">
        {calendarDays.map(day => {
          const dayAppts = appointments.filter(appt => 
            format(appt.date, 'yyyy-MM-dd') === format(day, 'yyyy-MM-dd')
          );
          
          const isCurrentMonth = isSameMonth(day, currentDate);
          
          return (
            <div 
              key={day.toString()} 
              className={`bg-white p-2 h-32 ${!isCurrentMonth ? 'bg-gray-50' : ''}`}
            >
              <div className={`text-sm font-medium mb-1 ${
                isToday(day) 
                  ? 'text-white bg-blue-500 w-6 h-6 rounded-full flex items-center justify-center' 
                  : isCurrentMonth ? 'text-gray-900' : 'text-gray-400'
              }`}>
                {format(day, 'd')}
              </div>
              
              <div className="space-y-1 overflow-hidden">
                {dayAppts.slice(0, 3).map(appt => (
                  <div 
                    key={appt.id} 
                    className={`text-xs p-1 rounded truncate ${
                      appt.is_spontaneous 
                        ? 'bg-red-100 text-red-800' 
                        : 'bg-blue-100 text-blue-800'
                    }`}
                    title={`${appt.time} - ${appt.patient_name} (${appt.doctor_name})`}
                  >
                    {appt.time} {appt.patient_name}
                  </div>
                ))}
                {dayAppts.length > 3 && (
                  <div className="text-xs text-gray-500 font-medium">
                    +{dayAppts.length - 3} más
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}