# HubInfecto - Sistema de Gestión de Citas Médicas

## 📋 Proposición del Proyecto

HubInfecto es un sistema integral de gestión de citas médicas diseñado específicamente para clínicas y consultorios de infectología. El sistema permite la administración eficiente de citas, seguimiento de pacientes y gestión del flujo de trabajo diario del personal médico y administrativo.

## 🎯 Objetivos Principales

### Objetivos Actuales (v1.0 - ✅ Completado)
- **Gestión de Citas**: Sistema completo para programar, visualizar y administrar citas médicas
- **Vistas Múltiples**: Calendario semanal y mensual para diferentes necesidades de visualización
- **Sistema de Filtros**: Búsqueda por paciente y doctor para navegación eficiente
- **Citas Espontáneas**: Manejo especial de consultas de emergencia o walk-ins
- **Interfaz Intuitiva**: Dashboard moderno y responsive con Tailwind CSS

### Objetivos Futuros (Roadmap)

#### v2.0 - Dashboard Operativo (🔄 Próximo)
- **Dashboard Principal**: Vista de inicio con información del día actual
- **Check-in de Pacientes**: Sistema para que secretarias marquen llegada de pacientes
- **Estado de Consultas**: Seguimiento en tiempo real del progreso de las citas
- **Panel de Control**: Métricas y estadísticas en tiempo real

#### v3.0 - Gestión Avanzada de Flujo
- **Estados de Cita**: Programada → Llegada → En Consulta → Completada
- **Notificaciones**: Alertas automáticas para retrasos y urgencias
- **Base de Datos de Pacientes**: Registro completo de pacientes con historial
- **Sistema de Pendientes**: Tareas y seguimientos por paciente (estudios, controles)
- **Historia Clínica Básica**: Notas rápidas y seguimiento de tratamientos
- **Reportes**: Generación de informes de productividad y estadísticas

#### v4.0 - Funcionalidades Avanzadas
- **Integración con Historia Clínica**: Conexión con sistemas EHR existentes
- **Telemedicina**: Soporte para consultas virtuales
- **Sistema de Facturación**: Integración con sistemas de cobro
- **API Completa**: Para integración con otros sistemas

## 🏗️ Arquitectura Técnica

### Stack Tecnológico
- **Frontend**: Next.js 14, React 18, TypeScript
- **Styling**: Tailwind CSS
- **Base de Datos**: Supabase (PostgreSQL)
- **Fechas**: date-fns
- **Estado**: React Hooks + Context API

### Estructura del Proyecto
```
HubInfecto/
├── src/
│   ├── app/                    # Páginas de Next.js App Router
│   ├── components/             # Componentes reutilizables
│   ├── hooks/                  # Custom hooks
│   ├── lib/                    # Utilidades y configuración
│   └── types.ts               # Definiciones TypeScript
├── docs/                      # Documentación del proyecto
└── tests/                     # Pruebas unitarias e integración
```

## 🚀 Funcionalidades Implementadas

### ✅ Versión 1.0 (Actual)
- [x] Dashboard principal con navegación lateral
- [x] Vista semanal con grid de 7 días
- [x] Vista mensual tipo calendario
- [x] Modal para agregar nuevas citas
- [x] Sistema de filtros por paciente y doctor
- [x] Manejo de citas espontáneas
- [x] Estadísticas básicas (total citas, espontáneas, doctores)
- [x] Datos de demostración para testing
- [x] Preparación para integración con Supabase

## 🔮 Funcionalidades Futuras

### 📊 Dashboard Operativo (v2.0)
```typescript
interface DashboardToday {
  todayAppointments: Appointment[];
  arrivedPatients: Patient[];
  inProgressConsults: Consultation[];
  completedToday: number;
  pendingArrivals: number;
}
```

#### Componentes Planificados:
- **TodayOverview**: Resumen del día actual
- **PatientCheckIn**: Interface para marcar llegadas
- **ConsultationFlow**: Seguimiento de estados de consulta
- **DoctorQueue**: Cola de pacientes por doctor

### 🏥 Sistema de Check-in (v2.0)
- **Recepción**: Interface para secretarias
  - Lista de citas del día
  - Botón de "Paciente Llegó"
  - Tiempos de espera estimados
- **Sala de Espera**: Display público con turnos
- **Doctores**: Panel para marcar consultas completadas

### 👥 Base de Datos de Pacientes (v3.0)
```typescript
interface Patient {
  id: string;
  name: string;
  dni: string;
  phone: string;
  email: string;
  address: string;
  birthDate: Date;
  medicalHistory: MedicalNote[];
  pendingTasks: PendingTask[];
  appointments: Appointment[];
}

interface PendingTask {
  id: string;
  patientId: string;
  type: 'study' | 'control' | 'test' | 'follow_up';
  description: string;
  dueDate: Date;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in_progress' | 'completed';
  assignedDoctor: string;
  notes: string;
}
```

#### Componentes Planificados:
- **PatientDatabase**: Registro completo de pacientes
- **PendingTasksManager**: Gestión de tareas pendientes
- **PatientProfile**: Vista detallada del paciente
- **TaskReminders**: Alertas de tareas vencidas

### 📈 Métricas y Reportes (v3.0)
- Tiempo promedio de consulta
- Puntualidad de pacientes
- Eficiencia por doctor
- Seguimiento de tareas pendientes
- Reportes mensuales/anuales

## 🛠️ Guía de Desarrollo

### Setup Inicial
```bash
# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env.local

# Ejecutar en desarrollo
npm run dev
```

### Convenciones de Código
- **Componentes**: PascalCase con descriptive names
- **Hooks**: camelCase starting with 'use'
- **Types**: Interfaces con sufijo claro (Appointment, Patient, etc.)
- **Archivos**: kebab-case para archivos de utilidad

### Base de Datos (Supabase Schema)
```sql
-- Tabla de pacientes
CREATE TABLE patients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR NOT NULL,
  dni VARCHAR UNIQUE,
  phone VARCHAR,
  email VARCHAR,
  address TEXT,
  birth_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla principal de citas
CREATE TABLE appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  patient_name VARCHAR NOT NULL, -- Mantener para compatibilidad
  doctor_name VARCHAR NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  notes TEXT,
  is_spontaneous BOOLEAN DEFAULT false,
  status VARCHAR DEFAULT 'scheduled', -- scheduled, arrived, in_progress, completed, cancelled
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de tareas pendientes
CREATE TABLE pending_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  type VARCHAR NOT NULL, -- study, control, test, follow_up
  description TEXT NOT NULL,
  due_date DATE,
  priority VARCHAR DEFAULT 'medium', -- low, medium, high, urgent
  status VARCHAR DEFAULT 'pending', -- pending, in_progress, completed
  assigned_doctor VARCHAR,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);

-- Tabla de notas médicas
CREATE TABLE medical_notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  appointment_id UUID REFERENCES appointments(id),
  doctor_name VARCHAR NOT NULL,
  note_text TEXT NOT NULL,
  note_type VARCHAR DEFAULT 'consultation', -- consultation, diagnosis, treatment, follow_up
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX idx_appointments_date ON appointments(date);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_name);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_pending_tasks_patient ON pending_tasks(patient_id);
CREATE INDEX idx_pending_tasks_due_date ON pending_tasks(due_date);
CREATE INDEX idx_pending_tasks_status ON pending_tasks(status);
CREATE INDEX idx_medical_notes_patient ON medical_notes(patient_id);
```

## 📝 Changelog

### v1.0.0 (2025-09-10)
- ✅ Implementación inicial del sistema de citas
- ✅ Vistas semanal y mensual
- ✅ Sistema de filtros y búsqueda
- ✅ Modal de creación de citas
- ✅ Datos de demostración
- ✅ Configuración completa del proyecto

### Próximas Versiones
- **v2.0.0**: Dashboard operativo y check-in system
- **v2.1.0**: Estados de cita y notificaciones
- **v3.0.0**: Reportes y métricas avanzadas

## 🤝 Contribución

Para contribuir al proyecto:
1. Fork del repositorio
2. Crear branch de feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📞 Contacto

- **Desarrollador**: Dr. Julián Alonso
- **Especialidad**: Infectología
- **Email**: [contacto@hubinfecto.com]
- **Versión**: 1.0.0