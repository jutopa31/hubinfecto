import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Appointment } from '../types';

export function useAppointments() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAppointments = async () => {
      try {
        // Check if Supabase is properly configured
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

        if (!supabaseUrl || !supabaseKey ||
            supabaseUrl === 'https://placeholder.supabase.co' ||
            supabaseKey === 'placeholder-key') {
          console.warn('Supabase not configured, using empty appointment list');
          setAppointments([]);
          setLoading(false);
          return;
        }

        const { data, error } = await supabase
          .from('appointments')
          .select('*')
          .order('date', { ascending: true });

        if (error) {
          console.error('Error fetching appointments:', error);
          setAppointments([]);
        } else {
          setAppointments(data || []);
        }
      } catch (error) {
        console.error('Error connecting to Supabase:', error);
        setAppointments([]);
      } finally {
        setLoading(false);
      }
    };

    fetchAppointments();
  }, []);

  const addAppointment = async (newAppt: Omit<Appointment, 'id'>) => {
    try {
      // Check if Supabase is properly configured
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

      if (!supabaseUrl || !supabaseKey ||
          supabaseUrl === 'https://placeholder.supabase.co' ||
          supabaseKey === 'placeholder-key') {
        console.warn('Supabase not configured, appointment not saved to database');
        // Create a temporary local appointment for demo purposes
        const tempAppointment = {
          ...newAppt,
          id: Math.random().toString(36).substr(2, 9)
        };
        setAppointments([...appointments, tempAppointment]);
        return;
      }

      const { data, error } = await supabase
        .from('appointments')
        .insert([newAppt])
        .select()
        .single();

      if (error) {
        console.error('Error adding appointment:', error);
        return;
      }

      // Add to local state for immediate UI update
      setAppointments([...appointments, data]);
    } catch (error) {
      console.error('Error saving appointment:', error);
    }
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