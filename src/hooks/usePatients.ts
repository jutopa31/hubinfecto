import { useState, useEffect } from 'react';
import { fakePatients } from '../lib/fakeData';
import type { Patient } from '../types';

export function usePatients() {
  const [patients, setPatients] = useState<Patient[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // For demo: Use fake data
    setPatients(fakePatients);
    setLoading(false);
    
    // For real Supabase integration (uncomment when ready):
    // const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
    // const fetchPatients = async () => {
    //   const { data } = await supabase.from('patients').select('*');
    //   setPatients(data || []);
    //   setLoading(false);
    // };
    // fetchPatients();
  }, []);

  const addPatient = (newPatient: Omit<Patient, 'id' | 'created_at' | 'updated_at'>) => {
    const id = Math.random().toString(36).substr(2, 9);
    const now = new Date();
    setPatients([...patients, { ...newPatient, id, created_at: now, updated_at: now }]);
    
    // For real Supabase integration:
    // supabase.from('patients').insert(newPatient);
  };

  return { patients, addPatient, loading };
}