# 🏥 HubInfecto - Sistema de Gestión de Citas Médicas

[![Next.js](https://img.shields.io/badge/Next.js-14-black?logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-blue?logo=tailwindcss)](https://tailwindcss.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Ready-green?logo=supabase)](https://supabase.com/)

> Sistema integral de gestión de citas médicas diseñado para clínicas de infectología con vistas semanal y mensual, gestión de citas espontáneas y dashboard operativo.

![HubInfecto Dashboard](docs/dashboard-preview.png)

## 🚀 Características Principales

### ✨ Funcionalidades Actuales (v1.0)

- **📅 Gestión Completa de Citas**
  - Creación, edición y visualización de citas médicas
  - Soporte para citas programadas y espontáneas
  - Información detallada: paciente, doctor, fecha, hora, notas

- **📊 Vistas Múltiples**
  - **Vista Semanal**: Grid de 7 días con citas organizadas por día
  - **Vista Mensual**: Calendario completo estilo Google Calendar
  - Navegación fluida entre vistas

- **🔍 Sistema de Filtros**
  - Búsqueda en tiempo real por nombre de paciente
  - Filtro por doctor asignado
  - Combinación de filtros para búsqueda precisa

- **⚡ Citas Espontáneas**
  - Identificación visual de citas de emergencia
  - Marcado especial para walk-ins del día actual
  - Estadísticas separadas para seguimiento

- **📈 Dashboard con Estadísticas**
  - Total de citas programadas
  - Contador de citas espontáneas
  - Número de doctores activos
  - Métricas en tiempo real

## 🛠️ Instalación y Configuración

### Prerrequisitos

- Node.js 18.0 o superior
- npm o yarn
- Git

### Instalación Rápida

```bash
# Clonar el repositorio
git clone https://github.com/usuario/hubinfecto.git
cd hubinfecto

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env.local

# Ejecutar en desarrollo
npm run dev
```

El proyecto estará disponible en `http://localhost:3000`

### Variables de Entorno

Crear archivo `.env.local`:

```env
# Supabase Configuration (Para integración futura)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# App Configuration
NEXT_PUBLIC_APP_NAME=HubInfecto
NEXT_PUBLIC_APP_VERSION=1.0.0
```

## 📁 Estructura del Proyecto

```
HubInfecto/
├── src/
│   ├── app/
│   │   ├── page.tsx              # Dashboard principal
│   │   ├── layout.tsx            # Layout raíz
│   │   └── globals.css           # Estilos globales
│   ├── components/
│   │   ├── WeeklyView.tsx        # Vista semanal
│   │   ├── MonthlyView.tsx       # Vista mensual
│   │   ├── AppointmentModal.tsx  # Modal de citas
│   │   └── FilterInput.tsx       # Componente de filtros
│   ├── hooks/
│   │   └── useAppointments.ts    # Hook de gestión de datos
│   ├── lib/
│   │   ├── fakeData.ts           # Datos de demostración
│   │   └── supabase.ts           # Cliente Supabase
│   └── types.ts                  # Definiciones TypeScript
├── docs/                         # Documentación
├── PROJECT.md                    # Especificación del proyecto
└── README.md                     # Este archivo
```

## 🎮 Uso del Sistema

### Dashboard Principal

El dashboard incluye:
- **Sidebar de navegación** con opciones de vista
- **Filtros de búsqueda** para pacientes y doctores
- **Botón de agregar cita** para nuevas citas
- **Estadísticas en tiempo real**

### Gestión de Citas

1. **Crear nueva cita**: Click en "Agregar Cita"
2. **Completar formulario**: Paciente, doctor, fecha, hora, notas
3. **Marcar como espontánea** si es necesario
4. **Guardar** para agregar al calendario

### Navegación entre Vistas

- **Vista Semanal**: Ideal para planificación diaria
- **Vista Mensual**: Perfecta para overview general
- Cambio instantáneo entre vistas sin pérdida de filtros

## 🔮 Roadmap y Futuras Implementaciones

### 📊 v2.0 - Dashboard Operativo (Próximo)

#### 🏠 Home Dashboard del Día
```typescript
// Nuevos componentes planificados
<TodayOverview 
  appointments={todayAppointments}
  arrivals={arrivedPatients}
  inProgress={activeConsultations}
/>
```

**Características:**
- Lista de citas del día actual
- Estado en tiempo real de cada paciente
- Resumen de productividad diaria
- Alertas de retrasos y urgencias

#### 👥 Sistema de Check-in para Secretarias
```typescript
interface PatientCheckIn {
  appointmentId: string;
  arrivalTime: Date;
  status: 'scheduled' | 'arrived' | 'in_progress' | 'completed';
  secretary: string;
}
```

**Funcionalidades:**
- Lista de pacientes esperados del día
- Botón "Paciente Llegó" con timestamp
- Cola de espera visual
- Notificaciones automáticas a doctores

#### 👨‍⚕️ Panel para Doctores
```typescript
interface DoctorQueue {
  doctorName: string;
  currentPatient?: Patient;
  nextPatients: Patient[];
  completedToday: number;
  averageConsultTime: number;
}
```

**Características:**
- Cola personal de pacientes
- Botón "Consulta Completada"
- Tiempo estimado por paciente
- Estadísticas personales

### 🎯 v3.0 - Gestión Avanzada de Flujo

#### Estados Completos de Cita
- **Programada** → **Paciente Llegó** → **En Consulta** → **Completada**
- Timestamps automáticos en cada transición
- Métricas de tiempo de espera y consulta

#### 👥 Base de Datos de Pacientes
```typescript
interface Patient {
  id: string;
  name: string;
  dni: string;
  phone: string;
  email: string;
  medicalHistory: MedicalNote[];
  pendingTasks: PendingTask[];
}
```

#### 📋 Sistema de Pendientes (To-Do por Paciente)
```typescript
interface PendingTask {
  id: string;
  patientId: string;
  type: 'study' | 'control' | 'test' | 'follow_up';
  description: string;
  dueDate: Date;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in_progress' | 'completed';
}
```

**Funcionalidades del Sistema de Pendientes:**
- Lista de estudios pendientes por paciente
- Seguimiento de controles médicos
- Recordatorios automáticos de vencimientos
- Priorización de tareas por urgencia
- Historial de tareas completadas

#### Sistema de Notificaciones
- Alertas de pacientes retrasados
- Notificaciones de urgencias
- Recordatorios automáticos de tareas pendientes

### 📈 v4.0 - Funcionalidades Avanzadas

- **Historia Clínica Básica**: Notas de seguimiento
- **Reportes Detallados**: Productividad, puntualidad, eficiencia
- **Integración EHR**: Conexión con sistemas existentes
- **API Completa**: Para integración con otros sistemas

## 🧪 Datos de Demostración

El sistema incluye datos de prueba con:
- 6 citas de ejemplo
- Diferentes doctores (Dr. Alonso, Dr. Smith, Dr. García, Dr. Torres)
- Mix de citas programadas y espontáneas
- Fechas variadas para testing de vistas

## 🔧 Scripts Disponibles

```bash
# Desarrollo
npm run dev          # Servidor de desarrollo

# Producción
npm run build        # Construir para producción
npm run start        # Iniciar servidor de producción

# Calidad de código
npm run lint         # Ejecutar ESLint
npm run type-check   # Verificar tipos TypeScript

# Base de datos (Futuro)
npm run db:migrate   # Ejecutar migraciones
npm run db:seed      # Poblar con datos de prueba
```

## 🤝 Contribución

### Proceso de Desarrollo

1. **Fork** del repositorio
2. **Crear branch** de feature: `git checkout -b feature/nueva-funcionalidad`
3. **Commit** cambios: `git commit -m 'feat: agregar nueva funcionalidad'`
4. **Push** al branch: `git push origin feature/nueva-funcionalidad`
5. **Crear Pull Request**

### Convenciones de Commit

```bash
feat: nueva funcionalidad
fix: corrección de bug
docs: actualización de documentación
style: cambios de formato (no afectan lógica)
refactor: refactorización de código
test: agregar o corregir tests
chore: tareas de mantenimiento
```

## 📋 Requisitos del Sistema

- **Node.js**: 18.0+
- **RAM**: 4GB mínimo
- **Espacio**: 500MB
- **Navegadores**: Chrome 90+, Firefox 88+, Safari 14+

## 🐛 Reporte de Bugs

Para reportar bugs, crear un issue con:
- Descripción detallada del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Screenshots si aplica
- Información del entorno (OS, navegador, versión)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 📞 Contacto y Soporte

- **Desarrollador**: Dr. Julián Alonso
- **Especialidad**: Infectología  
- **Email**: contacto@hubinfecto.com
- **GitHub**: @julian-alonso
- **Versión Actual**: 1.0.0

---

<div align="center">

**🏥 HubInfecto - Optimizando la gestión médica con tecnología moderna**

[Documentación](./PROJECT.md) • [Changelog](./CHANGELOG.md) • [Reportar Bug](../../issues) • [Solicitar Feature](../../issues)

</div>