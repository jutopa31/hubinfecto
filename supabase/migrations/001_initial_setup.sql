-- HubInfecto - Initial Database Setup Migration
-- Migration: 001_initial_setup
-- Created: 2025-09-15
-- Description: Creates all tables, functions, and initial data for HubInfecto

-- HubInfecto Initial Setup Migration
-- This migration sets up the complete database structure

-- Create migrations tracking table first
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check if this migration has already been applied
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM migrations WHERE name = '001_initial_setup') THEN
        RAISE NOTICE 'Migration 001_initial_setup already applied, skipping...';
        RETURN;
    END IF;

    RAISE NOTICE 'Running migration 001_initial_setup...';
END $$;

-- Setup extensions first
-- Note: Run extensions.sql manually in Supabase dashboard before this migration

-- Enable necessary extensions (if not already done)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom enum types only if they don't exist
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

-- Note: For Supabase setup, run these files manually in the SQL editor:
-- 1. extensions.sql
-- 2. schema.sql
-- 3. rls-policies.sql
-- 4. functions.sql

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