import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'placeholder-key';

// Validar que las variables de entorno estén configuradas
if (typeof window !== 'undefined') {
  if (supabaseUrl === 'https://placeholder.supabase.co' || supabaseAnonKey === 'placeholder-key') {
    console.warn('⚠️ Supabase environment variables not configured. Please add NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY to your environment variables.');
  }
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// For future Supabase integration
export async function getAppointments() {
  const { data, error } = await supabase
    .from('appointments')
    .select('*')
    .order('date', { ascending: true });
    
  if (error) {
    console.error('Error fetching appointments:', error);
    return [];
  }
  
  return data;
}

export async function createAppointment(appointment: any) {
  const { data, error } = await supabase
    .from('appointments')
    .insert([appointment])
    .select();
    
  if (error) {
    console.error('Error creating appointment:', error);
    return null;
  }
  
  return data[0];
}