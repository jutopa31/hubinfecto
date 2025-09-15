export interface Appointment {
  id: string;
  patient_id?: string;
  patient_name: string;
  doctor_name: string;
  date: Date;
  time: string;
  notes: string;
  is_spontaneous: boolean;
  is_new_patient: boolean; // true = nuevo paciente, false = recitado
  status: 'scheduled' | 'arrived' | 'in_progress' | 'completed' | 'cancelled';
}

export interface DailyCapacity {
  date: string; // YYYY-MM-DD format
  max_appointments: number;
  max_spontaneous: number;
  predicted_spontaneous: number;
  current_scheduled: number;
  current_spontaneous: number;
}

export interface Patient {
  id: string;
  name: string;
  dni: string;
  phone: string;
  email: string;
  address: string;
  birth_date: Date;
  created_at: Date;
  updated_at: Date;
}

export interface PendingTask {
  id: string;
  patient_id: string;
  patient_name?: string; // Para propósitos de visualización
  type: 'estudio' | 'control' | 'cultivo' | 'seguimiento';
  description: string;
  due_date: Date;
  priority: 'baja' | 'media' | 'alta' | 'urgente';
  status: 'pendiente' | 'en_progreso' | 'completada';
  assigned_doctor: string;
  notes: string;
  created_at: Date;
  completed_at?: Date;
}

export interface MedicalNote {
  id: string;
  patient_id: string;
  appointment_id?: string;
  doctor_name: string;
  note_text: string;
  note_type: 'consultation' | 'diagnosis' | 'treatment' | 'follow_up';
  created_at: Date;
}