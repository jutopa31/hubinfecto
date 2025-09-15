import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

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