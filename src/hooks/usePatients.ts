import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Patient } from '../types';

export function usePatients() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPatients = async () => {
      try {
        // Check if Supabase is properly configured
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

        if (!supabaseUrl || !supabaseKey ||
            supabaseUrl === 'https://placeholder.supabase.co' ||
            supabaseKey === 'placeholder-key') {
          console.warn('Supabase not configured, using empty patient list');
          setPatients([]);
          setLoading(false);
          return;
        }

        const { data, error } = await supabase
          .from('patients')
          .select('*')
          .order('created_at', { ascending: false });

        if (error) {
          console.error('Error fetching patients:', error);
          setPatients([]);
        } else {
          setPatients(data || []);
        }
      } catch (error) {
        console.error('Error connecting to Supabase:', error);
        setPatients([]);
      } finally {
        setLoading(false);
      }
    };

    fetchPatients();
  }, []);

  const addPatient = async (newPatient: Omit<Patient, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      // Check if Supabase is properly configured
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

      if (!supabaseUrl || !supabaseKey ||
          supabaseUrl === 'https://placeholder.supabase.co' ||
          supabaseKey === 'placeholder-key') {
        console.warn('Supabase not configured, patient not saved to database');
        // Create a temporary local patient for demo purposes
        const tempPatient = {
          ...newPatient,
          id: Math.random().toString(36).substr(2, 9),
          created_at: new Date(),
          updated_at: new Date()
        };
        setPatients([tempPatient, ...patients]);
        return;
      }

      const { data, error } = await supabase
        .from('patients')
        .insert([newPatient])
        .select()
        .single();

      if (error) {
        console.error('Error adding patient:', error);
        return;
      }

      // Add to local state for immediate UI update
      setPatients([data, ...patients]);
    } catch (error) {
      console.error('Error saving patient:', error);
    }
  };

  return { patients, addPatient, loading };
}