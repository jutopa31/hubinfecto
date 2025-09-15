-- HubInfecto - Sample Data Migration
-- Migration: 002_sample_data
-- Created: 2025-09-15
-- Description: Adds sample patients, appointments, and tasks for development/demo

-- Check if migration already ran
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM migrations WHERE name = '002_sample_data') THEN
        RAISE NOTICE 'Migration 002_sample_data already applied, skipping...';
        RETURN;
    END IF;

    -- Insert sample patients
    INSERT INTO patients (id, name, dni, phone, email, address, birth_date) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Ana García López', '12345678', '+54 11 1234-5678', 'ana.garcia@email.com', 'Av. Corrientes 1234, CABA', '1985-03-15'),
    ('22222222-2222-2222-2222-222222222222', 'Carlos Rodríguez', '23456789', '+54 11 2345-6789', 'carlos.rodriguez@email.com', 'Av. Santa Fe 5678, CABA', '1978-07-22'),
    ('33333333-3333-3333-3333-333333333333', 'María Elena Fernández', '34567890', '+54 11 3456-7890', 'maria.fernandez@email.com', 'Av. Rivadavia 9012, CABA', '1992-11-08'),
    ('44444444-4444-4444-4444-444444444444', 'Roberto Silva', '45678901', '+54 11 4567-8901', 'roberto.silva@email.com', 'Av. Cabildo 3456, CABA', '1965-02-14'),
    ('55555555-5555-5555-5555-555555555555', 'Laura Martínez', '56789012', '+54 11 5678-9012', 'laura.martinez@email.com', 'Av. Las Heras 7890, CABA', '1988-09-30');

    -- Get doctor IDs for appointments
    WITH doctor_ids AS (
        SELECT id, name FROM doctors WHERE name IN ('Dr. Julián Alonso', 'Dra. María González', 'Dr. Carlos Rodríguez')
    )
    -- Insert sample appointments for current week
    INSERT INTO appointments (
        patient_id, patient_name, doctor_id, doctor_name,
        date, time, duration_minutes, notes, is_spontaneous, is_new_patient, status
    )
    SELECT
        p.id, p.name, d.id, d.name,
        CURRENT_DATE + (random() * 7)::int, -- Random day this week
        ('08:00'::time + (random() * 10 * interval '1 hour'))::time, -- Random time 8AM-6PM
        30 + (random() * 30)::int, -- 30-60 minutes
        'Consulta de control infectológico',
        random() < 0.2, -- 20% spontaneous
        random() < 0.3, -- 30% new patients
        CASE
            WHEN random() < 0.1 THEN 'completed'
            WHEN random() < 0.05 THEN 'cancelled'
            WHEN random() < 0.1 THEN 'in_progress'
            WHEN random() < 0.2 THEN 'arrived'
            ELSE 'scheduled'
        END
    FROM (
        SELECT * FROM (VALUES
            ('11111111-1111-1111-1111-111111111111', 'Ana García López'),
            ('22222222-2222-2222-2222-222222222222', 'Carlos Rodríguez'),
            ('33333333-3333-3333-3333-333333333333', 'María Elena Fernández'),
            ('44444444-4444-4444-4444-444444444444', 'Roberto Silva'),
            ('55555555-5555-5555-5555-555555555555', 'Laura Martínez')
        ) AS t(id, name)
    ) p
    CROSS JOIN doctor_ids d
    WHERE random() < 0.6; -- Not all combinations

    -- Insert sample pending tasks
    INSERT INTO pending_tasks (
        patient_id, patient_name, type, description, due_date, priority,
        assigned_doctor_id, assigned_doctor, notes, status
    )
    SELECT
        p.id, p.name,
        (ARRAY['estudio', 'control', 'cultivo', 'seguimiento']::task_type[])[floor(random() * 4 + 1)],
        CASE floor(random() * 4)
            WHEN 0 THEN 'Hemograma completo y hepatograma'
            WHEN 1 THEN 'Control de función renal'
            WHEN 2 THEN 'Urocultivo y antibiograma'
            ELSE 'Seguimiento post-tratamiento'
        END,
        CURRENT_DATE + (random() * 30 - 10)::int, -- Due dates ±10 days from today
        (ARRAY['baja', 'media', 'alta', 'urgente']::task_priority[])[floor(random() * 4 + 1)],
        d.id, d.name,
        'Tarea asignada durante la consulta',
        CASE
            WHEN random() < 0.3 THEN 'completada'
            WHEN random() < 0.1 THEN 'en_progreso'
            ELSE 'pendiente'
        END
    FROM (
        SELECT * FROM (VALUES
            ('11111111-1111-1111-1111-111111111111', 'Ana García López'),
            ('22222222-2222-2222-2222-222222222222', 'Carlos Rodríguez'),
            ('33333333-3333-3333-3333-333333333333', 'María Elena Fernández'),
            ('44444444-4444-4444-4444-444444444444', 'Roberto Silva'),
            ('55555555-5555-5555-5555-555555555555', 'Laura Martínez')
        ) AS t(id, name)
    ) p
    CROSS JOIN (SELECT id, name FROM doctors) d
    WHERE random() < 0.4; -- Some patients have multiple tasks

    -- Insert sample medical notes
    INSERT INTO medical_notes (
        patient_id, doctor_id, doctor_name, note_text, note_type
    )
    SELECT
        p.id, d.id, d.name,
        CASE floor(random() * 4)
            WHEN 0 THEN 'Paciente presenta cuadro febril de 3 días de evolución. Se indica tratamiento antibiótico empírico.'
            WHEN 1 THEN 'Control post-tratamiento. Evolución favorable. Continuar con medicación actual.'
            WHEN 2 THEN 'Resultados de laboratorio dentro de parámetros normales. Alta médica.'
            ELSE 'Seguimiento de infección urinaria. Respuesta adecuada al tratamiento.'
        END,
        (ARRAY['consultation', 'diagnosis', 'treatment', 'follow_up']::note_type[])[floor(random() * 4 + 1)]
    FROM (
        SELECT * FROM (VALUES
            ('11111111-1111-1111-1111-111111111111'),
            ('22222222-2222-2222-2222-222222222222'),
            ('33333333-3333-3333-3333-333333333333'),
            ('44444444-4444-4444-4444-444444444444'),
            ('55555555-5555-5555-5555-555555555555')
        ) AS t(id)
    ) p
    CROSS JOIN (SELECT id, name FROM doctors) d
    WHERE random() < 0.3;

    -- Mark migration as complete
    INSERT INTO migrations (name) VALUES ('002_sample_data');

    RAISE NOTICE 'Sample data migration completed successfully';
END $$;