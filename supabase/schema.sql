-- HubInfecto - Supabase Database Schema
-- Medical Management System for Infectious Diseases
-- Generated: 2025-09-15

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom enum types
CREATE TYPE appointment_status AS ENUM ('scheduled', 'arrived', 'in_progress', 'completed', 'cancelled');
CREATE TYPE task_type AS ENUM ('estudio', 'control', 'cultivo', 'seguimiento');
CREATE TYPE task_priority AS ENUM ('baja', 'media', 'alta', 'urgente');
CREATE TYPE task_status AS ENUM ('pendiente', 'en_progreso', 'completada');
CREATE TYPE note_type AS ENUM ('consultation', 'diagnosis', 'treatment', 'follow_up');

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Patients table - Central patient registry
CREATE TABLE patients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    dni VARCHAR(20) UNIQUE,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    birth_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL),
    CONSTRAINT valid_dni CHECK (dni ~ '^[0-9]{7,8}$' OR dni IS NULL)
);

-- Doctors table - Doctor registry and specialties
CREATE TABLE doctors (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) UNIQUE,
    specialty VARCHAR(100) DEFAULT 'Infectología',
    phone VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_doctor_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Appointments table - Core appointment management
CREATE TABLE appointments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
    patient_name VARCHAR(255) NOT NULL, -- Backup for display purposes
    doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
    doctor_name VARCHAR(255) NOT NULL, -- Backup for display purposes
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

    -- Constraints
    CONSTRAINT valid_appointment_time CHECK (
        EXTRACT(HOUR FROM time) BETWEEN 8 AND 20
    ),
    CONSTRAINT valid_duration CHECK (duration_minutes > 0 AND duration_minutes <= 480),
    CONSTRAINT valid_status_flow CHECK (
        (status = 'scheduled' AND arrived_at IS NULL) OR
        (status = 'arrived' AND arrived_at IS NOT NULL AND started_at IS NULL) OR
        (status = 'in_progress' AND started_at IS NOT NULL AND completed_at IS NULL) OR
        (status = 'completed' AND completed_at IS NOT NULL) OR
        (status = 'cancelled')
    )
);

-- Pending Tasks table - Medical follow-ups and studies
CREATE TABLE pending_tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    patient_name VARCHAR(255), -- Denormalized for performance
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_completion CHECK (
        (status = 'completada' AND completed_at IS NOT NULL) OR
        (status != 'completada' AND completed_at IS NULL)
    )
);

-- Medical Notes table - Clinical documentation
CREATE TABLE medical_notes (
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

-- Daily Capacity table - Appointment capacity management
CREATE TABLE daily_capacity (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    max_appointments INTEGER DEFAULT 20,
    max_spontaneous INTEGER DEFAULT 5,
    predicted_spontaneous INTEGER DEFAULT 3,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_capacity CHECK (
        max_appointments > 0 AND
        max_spontaneous >= 0 AND
        predicted_spontaneous >= 0 AND
        max_spontaneous <= max_appointments
    )
);

-- =====================================================
-- COMPUTED VIEWS
-- =====================================================

-- View for appointment statistics
CREATE VIEW appointment_stats AS
SELECT
    date,
    COUNT(*) as total_appointments,
    COUNT(*) FILTER (WHERE is_spontaneous = true) as spontaneous_count,
    COUNT(*) FILTER (WHERE is_new_patient = true) as new_patient_count,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
    COUNT(DISTINCT doctor_name) as unique_doctors,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/60) FILTER (WHERE completed_at IS NOT NULL AND started_at IS NOT NULL) as avg_duration_minutes
FROM appointments
GROUP BY date;

-- View for daily capacity with current usage
CREATE VIEW daily_capacity_usage AS
SELECT
    dc.date,
    dc.max_appointments,
    dc.max_spontaneous,
    dc.predicted_spontaneous,
    COALESCE(a.scheduled_count, 0) as current_scheduled,
    COALESCE(a.spontaneous_count, 0) as current_spontaneous,
    dc.max_appointments - COALESCE(a.scheduled_count, 0) as available_slots,
    dc.max_spontaneous - COALESCE(a.spontaneous_count, 0) as available_spontaneous
FROM daily_capacity dc
LEFT JOIN (
    SELECT
        date,
        COUNT(*) FILTER (WHERE is_spontaneous = false) as scheduled_count,
        COUNT(*) FILTER (WHERE is_spontaneous = true) as spontaneous_count
    FROM appointments
    WHERE status != 'cancelled'
    GROUP BY date
) a ON dc.date = a.date;

-- View for patient summary with latest information
CREATE VIEW patient_summary AS
SELECT
    p.*,
    COALESCE(apt.total_appointments, 0) as total_appointments,
    apt.last_appointment_date,
    apt.next_appointment_date,
    COALESCE(pt.pending_tasks_count, 0) as pending_tasks_count,
    COALESCE(pt.urgent_tasks_count, 0) as urgent_tasks_count
FROM patients p
LEFT JOIN (
    SELECT
        patient_id,
        COUNT(*) as total_appointments,
        MAX(date) FILTER (WHERE date <= CURRENT_DATE) as last_appointment_date,
        MIN(date) FILTER (WHERE date > CURRENT_DATE AND status = 'scheduled') as next_appointment_date
    FROM appointments
    WHERE status != 'cancelled'
    GROUP BY patient_id
) apt ON p.id = apt.patient_id
LEFT JOIN (
    SELECT
        patient_id,
        COUNT(*) FILTER (WHERE status != 'completada') as pending_tasks_count,
        COUNT(*) FILTER (WHERE status != 'completada' AND priority = 'urgente') as urgent_tasks_count
    FROM pending_tasks
    GROUP BY patient_id
) pt ON p.id = pt.patient_id;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Appointments indexes
CREATE INDEX idx_appointments_date ON appointments(date);
CREATE INDEX idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_is_spontaneous ON appointments(is_spontaneous);
CREATE INDEX idx_appointments_datetime ON appointments(date, time);

-- Patient indexes
CREATE INDEX idx_patients_dni ON patients(dni);
-- Trigram index for fuzzy text search (requires pg_trgm extension)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        CREATE INDEX IF NOT EXISTS idx_patients_name_trgm ON patients USING gin(name gin_trgm_ops);
    ELSE
        -- Fallback: regular text index if pg_trgm is not available
        CREATE INDEX IF NOT EXISTS idx_patients_name_text ON patients(name);
        RAISE NOTICE 'pg_trgm extension not available, using regular text index instead';
    END IF;
END $$;
CREATE INDEX idx_patients_created_at ON patients(created_at);

-- Pending tasks indexes
CREATE INDEX idx_pending_tasks_patient_id ON pending_tasks(patient_id);
CREATE INDEX idx_pending_tasks_due_date ON pending_tasks(due_date);
CREATE INDEX idx_pending_tasks_status ON pending_tasks(status);
CREATE INDEX idx_pending_tasks_priority ON pending_tasks(priority);
CREATE INDEX idx_pending_tasks_assigned_doctor_id ON pending_tasks(assigned_doctor_id);

-- Medical notes indexes
CREATE INDEX idx_medical_notes_patient_id ON medical_notes(patient_id);
CREATE INDEX idx_medical_notes_appointment_id ON medical_notes(appointment_id);
CREATE INDEX idx_medical_notes_created_at ON medical_notes(created_at);

-- Daily capacity indexes
CREATE INDEX idx_daily_capacity_date ON daily_capacity(date);

-- Doctors indexes
CREATE INDEX idx_doctors_name ON doctors(name);
CREATE INDEX idx_doctors_is_active ON doctors(is_active);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update_updated_at trigger to all relevant tables
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_doctors_updated_at BEFORE UPDATE ON doctors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pending_tasks_updated_at BEFORE UPDATE ON pending_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medical_notes_updated_at BEFORE UPDATE ON medical_notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_capacity_updated_at BEFORE UPDATE ON daily_capacity FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically update appointment status based on timestamps
CREATE OR REPLACE FUNCTION update_appointment_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-set status based on timestamps
    IF NEW.completed_at IS NOT NULL AND OLD.completed_at IS NULL THEN
        NEW.status = 'completed';
    ELSIF NEW.started_at IS NOT NULL AND OLD.started_at IS NULL THEN
        NEW.status = 'in_progress';
    ELSIF NEW.arrived_at IS NOT NULL AND OLD.arrived_at IS NULL THEN
        NEW.status = 'arrived';
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER auto_update_appointment_status
    BEFORE UPDATE ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION update_appointment_status();

-- Function to sync patient names in related tables
CREATE OR REPLACE FUNCTION sync_patient_name()
RETURNS TRIGGER AS $$
BEGIN
    -- Update patient name in appointments
    UPDATE appointments
    SET patient_name = NEW.name
    WHERE patient_id = NEW.id;

    -- Update patient name in pending tasks
    UPDATE pending_tasks
    SET patient_name = NEW.name
    WHERE patient_id = NEW.id;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER sync_patient_name_trigger
    AFTER UPDATE OF name ON patients
    FOR EACH ROW
    EXECUTE FUNCTION sync_patient_name();

-- Function to automatically create daily capacity for new dates
CREATE OR REPLACE FUNCTION ensure_daily_capacity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO daily_capacity (date)
    VALUES (NEW.date)
    ON CONFLICT (date) DO NOTHING;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER ensure_daily_capacity_trigger
    BEFORE INSERT ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION ensure_daily_capacity();

-- Function to validate appointment overlaps for same doctor
CREATE OR REPLACE FUNCTION check_appointment_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for overlapping appointments for the same doctor
    IF EXISTS (
        SELECT 1 FROM appointments
        WHERE doctor_id = NEW.doctor_id
        AND date = NEW.date
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND status NOT IN ('cancelled', 'completed')
        AND (
            (NEW.time, NEW.time + (NEW.duration_minutes || ' minutes')::interval)
            OVERLAPS
            (time, time + (duration_minutes || ' minutes')::interval)
        )
    ) THEN
        RAISE EXCEPTION 'Doctor has overlapping appointment at this time';
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_appointment_overlap_trigger
    BEFORE INSERT OR UPDATE ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION check_appointment_overlap();

-- =====================================================
-- SAMPLE DATA (Optional - for development)
-- =====================================================

-- Insert sample doctors
INSERT INTO doctors (name, license_number, specialty, email) VALUES
('Dr. Julián Alonso', 'MN-12345', 'Infectología', 'julian.alonso@hubinfecto.com'),
('Dra. María González', 'MN-67890', 'Infectología', 'maria.gonzalez@hubinfecto.com'),
('Dr. Carlos Rodríguez', 'MN-54321', 'Medicina Interna', 'carlos.rodriguez@hubinfecto.com');

-- Insert sample daily capacity for next 30 days
INSERT INTO daily_capacity (date, max_appointments, max_spontaneous, predicted_spontaneous)
SELECT
    CURRENT_DATE + i,
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 10 ELSE 20 END, -- Weekend reduced capacity
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 2 ELSE 5 END,
    CASE WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 1 ELSE 3 END
FROM generate_series(0, 30) i;

-- Create a procedure to reset demo data
CREATE OR REPLACE FUNCTION reset_demo_data()
RETURNS void AS $$
BEGIN
    -- This function can be called to reset all data for demo purposes
    TRUNCATE patients, appointments, pending_tasks, medical_notes RESTART IDENTITY CASCADE;

    -- Re-insert sample doctors and capacity
    INSERT INTO doctors (name, license_number, specialty, email) VALUES
    ('Dr. Julián Alonso', 'MN-12345', 'Infectología', 'julian.alonso@hubinfecto.com'),
    ('Dra. María González', 'MN-67890', 'Infectología', 'maria.gonzalez@hubinfecto.com'),
    ('Dr. Carlos Rodríguez', 'MN-54321', 'Medicina Interna', 'carlos.rodriguez@hubinfecto.com');

    RAISE NOTICE 'Demo data has been reset successfully';
END;
$$ language 'plpgsql';