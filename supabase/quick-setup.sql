-- HubInfecto - Quick Setup Script for Supabase
-- Run this single script in your Supabase SQL Editor
-- This script handles all setup in the correct order

-- =====================================================
-- STEP 1: EXTENSIONS
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Try to enable pg_trgm (optional)
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    RAISE NOTICE 'pg_trgm extension enabled - fuzzy search available';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'pg_trgm extension not available - using fallback search';
END $$;

-- =====================================================
-- STEP 2: ENUM TYPES
-- =====================================================

-- Create custom enum types (with existence checks)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status') THEN
        CREATE TYPE appointment_status AS ENUM ('scheduled', 'arrived', 'in_progress', 'completed', 'cancelled');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_type') THEN
        CREATE TYPE task_type AS ENUM ('estudio', 'control', 'cultivo', 'seguimiento');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority') THEN
        CREATE TYPE task_priority AS ENUM ('baja', 'media', 'alta', 'urgente');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('pendiente', 'en_progreso', 'completada');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'note_type') THEN
        CREATE TYPE note_type AS ENUM ('consultation', 'diagnosis', 'treatment', 'follow_up');
    END IF;
END $$;

-- =====================================================
-- STEP 3: CORE TABLES
-- =====================================================

-- Patients table
CREATE TABLE IF NOT EXISTS patients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    dni VARCHAR(20) UNIQUE,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    birth_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL),
    CONSTRAINT valid_dni CHECK (dni ~ '^[0-9]{7,8}$' OR dni IS NULL)
);

-- Doctors table
CREATE TABLE IF NOT EXISTS doctors (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) UNIQUE,
    specialty VARCHAR(100) DEFAULT 'Infectología',
    phone VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_doctor_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
    patient_name VARCHAR(255) NOT NULL,
    doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
    doctor_name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    notes TEXT,
    is_spontaneous BOOLEAN DEFAULT false,
    is_new_patient BOOLEAN DEFAULT false,
    status appointment_status DEFAULT 'scheduled',
    arrived_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_appointment_time CHECK (EXTRACT(HOUR FROM time) BETWEEN 8 AND 20),
    CONSTRAINT valid_duration CHECK (duration_minutes > 0 AND duration_minutes <= 480)
);

-- Pending Tasks table
CREATE TABLE IF NOT EXISTS pending_tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    patient_name VARCHAR(255),
    type task_type NOT NULL,
    description TEXT NOT NULL,
    due_date DATE,
    priority task_priority DEFAULT 'media',
    status task_status DEFAULT 'pendiente',
    assigned_doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
    assigned_doctor VARCHAR(255) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medical Notes table
CREATE TABLE IF NOT EXISTS medical_notes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
    doctor_name VARCHAR(255) NOT NULL,
    note_text TEXT NOT NULL,
    note_type note_type DEFAULT 'consultation',
    is_confidential BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily Capacity table
CREATE TABLE IF NOT EXISTS daily_capacity (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    max_appointments INTEGER DEFAULT 20,
    max_spontaneous INTEGER DEFAULT 5,
    predicted_spontaneous INTEGER DEFAULT 3,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_capacity CHECK (
        max_appointments > 0 AND
        max_spontaneous >= 0 AND
        predicted_spontaneous >= 0 AND
        max_spontaneous <= max_appointments
    )
);

-- =====================================================
-- STEP 4: INDEXES
-- =====================================================

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(date);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_patients_dni ON patients(dni);
CREATE INDEX IF NOT EXISTS idx_patients_created_at ON patients(created_at);
CREATE INDEX IF NOT EXISTS idx_pending_tasks_patient_id ON pending_tasks(patient_id);
CREATE INDEX IF NOT EXISTS idx_pending_tasks_due_date ON pending_tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_pending_tasks_status ON pending_tasks(status);

-- Conditional trigram index
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        CREATE INDEX IF NOT EXISTS idx_patients_name_trgm ON patients USING gin(name gin_trgm_ops);
    ELSE
        CREATE INDEX IF NOT EXISTS idx_patients_name_text ON patients(name);
    END IF;
END $$;

-- =====================================================
-- STEP 5: TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_doctors_updated_at ON doctors;
CREATE TRIGGER update_doctors_updated_at
    BEFORE UPDATE ON doctors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_appointments_updated_at ON appointments;
CREATE TRIGGER update_appointments_updated_at
    BEFORE UPDATE ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pending_tasks_updated_at ON pending_tasks;
CREATE TRIGGER update_pending_tasks_updated_at
    BEFORE UPDATE ON pending_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_medical_notes_updated_at ON medical_notes;
CREATE TRIGGER update_medical_notes_updated_at
    BEFORE UPDATE ON medical_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_capacity_updated_at ON daily_capacity;
CREATE TRIGGER update_daily_capacity_updated_at
    BEFORE UPDATE ON daily_capacity
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 6: INITIAL DATA
-- =====================================================

-- Insert sample doctors
INSERT INTO doctors (name, license_number, specialty, email) VALUES
('Dr. Julián Alonso', 'MN-12345', 'Infectología', 'julian.alonso@hubinfecto.com'),
('Dra. María González', 'MN-67890', 'Infectología', 'maria.gonzalez@hubinfecto.com'),
('Dr. Carlos Rodríguez', 'MN-54321', 'Medicina Interna', 'carlos.rodriguez@hubinfecto.com')
ON CONFLICT (license_number) DO NOTHING;

-- Create daily capacity for next 30 days
INSERT INTO daily_capacity (date, max_appointments, max_spontaneous, predicted_spontaneous)
SELECT
    CURRENT_DATE + i,
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 10 ELSE 20 END,
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 2 ELSE 5 END,
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 1 ELSE 3 END
FROM generate_series(0, 30) i
ON CONFLICT (date) DO NOTHING;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ HubInfecto database setup completed successfully!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Set up Row Level Security (run rls-policies.sql)';
    RAISE NOTICE '2. Add business functions (run functions.sql)';
    RAISE NOTICE '3. Add sample data (run migrations/002_sample_data.sql)';
    RAISE NOTICE '4. Configure your Next.js app with Supabase credentials';
END $$;