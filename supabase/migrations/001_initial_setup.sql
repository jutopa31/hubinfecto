-- HubInfecto - Initial Database Setup Migration
-- Migration: 001_initial_setup
-- Created: 2025-09-15
-- Description: Creates all tables, functions, and initial data for HubInfecto

-- Setup extensions first
\i extensions.sql

-- Create custom enum types
CREATE TYPE appointment_status AS ENUM ('scheduled', 'arrived', 'in_progress', 'completed', 'cancelled');
CREATE TYPE task_type AS ENUM ('estudio', 'control', 'cultivo', 'seguimiento');
CREATE TYPE task_priority AS ENUM ('baja', 'media', 'alta', 'urgente');
CREATE TYPE task_status AS ENUM ('pendiente', 'en_progreso', 'completada');
CREATE TYPE note_type AS ENUM ('consultation', 'diagnosis', 'treatment', 'follow_up');

-- Create all tables from schema.sql
\i schema.sql

-- Apply RLS policies
\i rls-policies.sql

-- Create business functions
\i functions.sql

-- Insert initial sample data
INSERT INTO doctors (name, license_number, specialty, email) VALUES
('Dr. Julián Alonso', 'MN-12345', 'Infectología', 'julian.alonso@hubinfecto.com'),
('Dra. María González', 'MN-67890', 'Infectología', 'maria.gonzalez@hubinfecto.com'),
('Dr. Carlos Rodríguez', 'MN-54321', 'Medicina Interna', 'carlos.rodriguez@hubinfecto.com')
ON CONFLICT (license_number) DO NOTHING;

-- Create daily capacity for the next 90 days
INSERT INTO daily_capacity (date, max_appointments, max_spontaneous, predicted_spontaneous)
SELECT
    CURRENT_DATE + i,
    CASE
        WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 10 -- Weekend
        ELSE 20 -- Weekday
    END,
    CASE
        WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 2
        ELSE 5
    END,
    CASE
        WHEN EXTRACT(dow FROM CURRENT_DATE + i) IN (0, 6) THEN 1
        ELSE 3
    END
FROM generate_series(0, 90) i
ON CONFLICT (date) DO NOTHING;

-- Mark migration as complete
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO migrations (name) VALUES ('001_initial_setup');