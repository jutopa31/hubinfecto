import { useState, useEffect } from 'react';
import { fakeAppointments } from '../lib/fakeData';
import type { Appointment } from '../types';

export function useAppointments() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // For demo: Use fake data
    setAppointments(fakeAppointments);
    setLoading(false);
    
    // For real Supabase integration (uncomment when ready):
    // const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
    // const fetchAppointments = async () => {
    //   const { data } = await supabase.from('appointments').select('*');
    //   setAppointments(data || []);
    //   setLoading(false);
    // };
    // fetchAppointments();
  }, []);

  const addAppointment = (newAppt: Omit<Appointment, 'id'>) => {
    const id = Math.random().toString(36).substr(2, 9);
    setAppointments([...appointments, { ...newAppt, id }]);
    
    // For real Supabase integration:
    // supabase.from('appointments').insert(newAppt);
  };

  const toggleAppointmentStatus = (appointmentId: string) => {
    setAppointments(appointments.map(appointment => 
      appointment.id === appointmentId 
        ? { 
            ...appointment, 
            status: appointment.status === 'completed' ? 'scheduled' : 'completed'
          }
        : appointment
    ));
    
    // For real Supabase integration:
    // supabase.from('appointments').update({ status: newStatus }).eq('id', appointmentId);
  };

  return { appointments, addAppointment, toggleAppointmentStatus, loading };
}