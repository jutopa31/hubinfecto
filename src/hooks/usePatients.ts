import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Patient } from '../types';

export function usePatients() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPatients = async () => {
      try {
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