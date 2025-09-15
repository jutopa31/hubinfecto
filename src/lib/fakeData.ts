import type { Appointment, Patient, PendingTask, DailyCapacity } from '../types';

export const fakeAppointments: Appointment[] = [
  { 
    id: '1', 
    patient_id: 'p1',
    patient_name: 'María González', 
    doctor_name: 'Dr. Alonso', 
    date: new Date('2025-09-10'), 
    time: '08:30', 
    notes: 'Control VIH - Carga viral indetectable', 
    is_spontaneous: false,
    is_new_patient: false,
    status: 'scheduled'
  },
  { 
    id: '2', 
    patient_id: 'p2',
    patient_name: 'Carlos Mendoza', 
    doctor_name: 'Dr. García', 
    date: new Date('2025-09-10'), 
    time: '10:00', 
    notes: 'Seguimiento TB pulmonar - Mes 3 tratamiento', 
    is_spontaneous: false,
    is_new_patient: false,
    status: 'scheduled'
  },
  { 
    id: '3', 
    patient_id: 'p3',
    patient_name: 'Ana Rodríguez', 
    doctor_name: 'Dr. Alonso', 
    date: new Date('2025-09-10'), 
    time: '14:00', 
    notes: 'Urgencia - Fiebre en paciente VIH', 
    is_spontaneous: true,
    is_new_patient: false,
    status: 'scheduled'
  },
  { 
    id: '4', 
    patient_id: 'p4',
    patient_name: 'Roberto Silva', 
    doctor_name: 'Dr. Torres', 
    date: new Date('2025-09-10'), 
    time: '16:30', 
    notes: 'Primera consulta - Síndrome febril prolongado', 
    is_spontaneous: false,
    is_new_patient: true,
    status: 'scheduled'
  },
  { 
    id: '5', 
    patient_id: 'p5',
    patient_name: 'Laura Vega', 
    doctor_name: 'Dr. García', 
    date: new Date('2025-09-11'), 
    time: '09:00', 
    notes: 'Control hepatitis B crónica', 
    is_spontaneous: false,
    is_new_patient: false,
    status: 'scheduled'
  },
  { 
    id: '6', 
    patient_id: 'p1',
    patient_name: 'María González', 
    doctor_name: 'Dr. Alonso', 
    date: new Date('2025-09-15'), 
    time: '11:00', 
    notes: 'Control trimestral VIH', 
    is_spontaneous: false,
    is_new_patient: false,
    status: 'scheduled'
  },
  { 
    id: '7', 
    patient_id: 'p6',
    patient_name: 'Jorge Martín', 
    doctor_name: 'Dr. García', 
    date: new Date('2025-09-10'), 
    time: '12:00', 
    notes: 'Seguimiento endocarditis estafilocócica', 
    is_spontaneous: false,
    is_new_patient: false,
    status: 'scheduled'
  }
];

export const fakeCapacityData: DailyCapacity[] = [
  {
    date: '2025-09-10',
    max_appointments: 20,
    max_spontaneous: 5,
    predicted_spontaneous: 3,
    current_scheduled: 4,
    current_spontaneous: 1
  },
  {
    date: '2025-09-11',
    max_appointments: 20,
    max_spontaneous: 5,
    predicted_spontaneous: 3,
    current_scheduled: 1,
    current_spontaneous: 0
  },
  {
    date: '2025-09-12',
    max_appointments: 20,
    max_spontaneous: 5,
    predicted_spontaneous: 4,
    current_scheduled: 0,
    current_spontaneous: 0
  },
  {
    date: '2025-09-13',
    max_appointments: 18, // Viernes capacidad reducida
    max_spontaneous: 4,
    predicted_spontaneous: 2,
    current_scheduled: 0,
    current_spontaneous: 0
  }
];

export const fakePatients: Patient[] = [
  {
    id: 'p1',
    name: 'María González',
    dni: '28456789',
    phone: '11-4567-8901',
    email: 'maria.gonzalez@email.com',
    address: 'Av. Corrientes 1234, CABA',
    birth_date: new Date('1985-03-15'),
    created_at: new Date('2023-06-01'),
    updated_at: new Date('2025-09-01')
  },
  {
    id: 'p2',
    name: 'Carlos Mendoza',
    dni: '35678912',
    phone: '11-3456-7890',
    email: 'carlos.mendoza@email.com',
    address: 'Riobamba 567, CABA',
    birth_date: new Date('1978-11-22'),
    created_at: new Date('2024-02-15'),
    updated_at: new Date('2025-08-20')
  },
  {
    id: 'p3',
    name: 'Ana Rodríguez',
    dni: '42789123',
    phone: '11-2345-6789',
    email: 'ana.rodriguez@email.com',
    address: 'Callao 890, CABA',
    birth_date: new Date('1992-07-08'),
    created_at: new Date('2024-12-10'),
    updated_at: new Date('2025-09-05')
  },
  {
    id: 'p4',
    name: 'Roberto Silva',
    dni: '30123456',
    phone: '11-1234-5678',
    email: 'roberto.silva@email.com',
    address: 'Santa Fe 2345, CABA',
    birth_date: new Date('1965-12-30'),
    created_at: new Date('2025-09-08'),
    updated_at: new Date('2025-09-08')
  },
  {
    id: 'p5',
    name: 'Laura Vega',
    dni: '38901234',
    phone: '11-5678-9012',
    email: 'laura.vega@email.com',
    address: 'Pueyrredón 1567, CABA',
    birth_date: new Date('1988-04-18'),
    created_at: new Date('2024-05-20'),
    updated_at: new Date('2025-08-15')
  },
  {
    id: 'p6',
    name: 'Jorge Martín',
    dni: '26789234',
    phone: '11-6789-0123',
    email: 'jorge.martin@email.com',
    address: 'Paraguay 987, CABA',
    birth_date: new Date('1982-09-12'),
    created_at: new Date('2024-08-10'),
    updated_at: new Date('2025-09-08')
  }
];

export const fakeTasks: PendingTask[] = [
  {
    id: 't1',
    patient_id: 'p1',
    patient_name: 'María González',
    type: 'estudio',
    description: 'CD4+ y Carga Viral VIH',
    due_date: new Date('2025-09-12'),
    priority: 'alta',
    status: 'pendiente',
    assigned_doctor: 'Dr. Alonso',
    notes: 'Control trimestral - Paciente en TARV',
    created_at: new Date('2025-09-01')
  },
  {
    id: 't2',
    patient_id: 'p2',
    patient_name: 'Carlos Mendoza',
    type: 'cultivo',
    description: 'Baciloscopía y cultivo BK',
    due_date: new Date('2025-09-15'),
    priority: 'urgente',
    status: 'pendiente',
    assigned_doctor: 'Dr. García',
    notes: 'Evaluación respuesta tratamiento TB',
    created_at: new Date('2025-09-01')
  },
  {
    id: 't3',
    patient_id: 'p3',
    patient_name: 'Ana Rodríguez',
    type: 'estudio',
    description: 'Hemocultivos x3 y tipificación',
    due_date: new Date('2025-09-11'),
    priority: 'urgente',
    status: 'pendiente',
    assigned_doctor: 'Dr. Alonso',
    notes: 'Descartar bacteriemia en paciente VIH',
    created_at: new Date('2025-09-08')
  },
  {
    id: 't4',
    patient_id: 'p4',
    patient_name: 'Roberto Silva',
    type: 'estudio',
    description: 'Hemocultivos x3, Ecocardiograma',
    due_date: new Date('2025-09-13'),
    priority: 'alta',
    status: 'pendiente',
    assigned_doctor: 'Dr. Torres',
    notes: 'Descartar endocarditis - Fiebre 3 semanas',
    created_at: new Date('2025-09-09')
  },
  {
    id: 't5',
    patient_id: 'p5',
    patient_name: 'Laura Vega',
    type: 'control',
    description: 'HBsAg, Anti-HBc, Carga viral HBV',
    due_date: new Date('2025-09-14'),
    priority: 'media',
    status: 'pendiente',
    assigned_doctor: 'Dr. García',
    notes: 'Control hepatitis B crónica',
    created_at: new Date('2025-09-01')
  },
  {
    id: 't6',
    patient_id: 'p1',
    patient_name: 'María González',
    type: 'seguimiento',
    description: 'Evaluación adherencia TARV',
    due_date: new Date('2025-09-17'),
    priority: 'media',
    status: 'pendiente',
    assigned_doctor: 'Dr. Alonso',
    notes: 'Revisar efectos adversos ARV',
    created_at: new Date('2025-09-02')
  },
  {
    id: 't7',
    patient_id: 'p6',
    patient_name: 'Jorge Martín',
    type: 'cultivo',
    description: 'Urocultivo y antibiograma',
    due_date: new Date('2025-09-16'),
    priority: 'alta',
    status: 'pendiente',
    assigned_doctor: 'Dr. García',
    notes: 'ITU complicada post-endocarditis',
    created_at: new Date('2025-09-08')
  },
  {
    id: 't8',
    patient_id: 'p6',
    patient_name: 'Jorge Martín',
    type: 'estudio',
    description: 'Ecocardiograma transtorácico',
    due_date: new Date('2025-09-18'),
    priority: 'alta',
    status: 'pendiente',
    assigned_doctor: 'Dr. García',
    notes: 'Control evolución endocarditis',
    created_at: new Date('2025-09-08')
  }
];