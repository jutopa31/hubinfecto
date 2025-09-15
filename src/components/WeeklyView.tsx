import { format, eachDayOfInterval, startOfWeek, endOfWeek, isToday } from 'date-fns';
import type { Appointment } from '../types';

interface WeeklyViewProps {
  appointments: Appointment[];
  currentDate: Date;
}

export default function WeeklyView({ appointments, currentDate }: WeeklyViewProps) {
  const weekDays = eachDayOfInterval({ 
    start: startOfWeek(currentDate), 
    end: endOfWeek(currentDate) 
  });

  return (
    <div className="grid grid-cols-7 gap-2">
      {weekDays.map(day => {
        const dayAppts = appointments.filter(appt => 
          format(appt.date, 'yyyy-MM-dd') === format(day, 'yyyy-MM-dd')
        );
        
        return (
          <div key={day.toString()} className="border rounded-lg p-3 bg-white shadow-sm">
            <h3 className={`font-semibold text-sm mb-2 ${isToday(day) ? 'text-blue-600' : 'text-gray-700'}`}>
              {format(day, 'EEE dd')}
            </h3>
            <div className="space-y-1">
              {dayAppts.map(appt => (
                <div 
                  key={appt.id} 
                  className={`p-2 rounded text-xs ${
                    appt.is_spontaneous && isToday(appt.date) 
                      ? 'bg-red-100 border-l-4 border-red-400' 
                      : 'bg-blue-50 border-l-4 border-blue-400'
                  }`}
                >
                  <div className="font-medium">{appt.time}</div>
                  <div className="text-gray-700">{appt.patient_name}</div>
                  <div className="text-gray-500">({appt.doctor_name})</div>
                  {appt.is_spontaneous && (
                    <div className="text-red-600 font-medium">Espontánea</div>
                  )}
                </div>
              ))}
              {dayAppts.length === 0 && (
                <div className="text-gray-400 text-xs italic">Sin citas</div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}