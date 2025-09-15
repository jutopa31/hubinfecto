-- HubInfecto - Database Functions and Procedures
-- Business logic and utility functions
-- Generated: 2025-09-15

-- =====================================================
-- APPOINTMENT MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to get available appointment slots for a specific date
CREATE OR REPLACE FUNCTION get_available_slots(
    target_date DATE,
    target_doctor_id UUID DEFAULT NULL
)
RETURNS TABLE (
    time_slot TIME,
    is_available BOOLEAN,
    doctor_id UUID,
    doctor_name TEXT
) AS $$
DECLARE
    start_hour INTEGER := 8;
    end_hour INTEGER := 18;
    slot_duration INTEGER := 30; -- minutes
BEGIN
    RETURN QUERY
    WITH time_slots AS (
        SELECT
            (start_hour::text || ':00')::TIME + (slot * (slot_duration || ' minutes')::INTERVAL) as slot_time
        FROM generate_series(0, ((end_hour - start_hour) * 60 / slot_duration) - 1) as slot
    ),
    doctor_list AS (
        SELECT d.id, d.name
        FROM doctors d
        WHERE d.is_active = true
        AND (target_doctor_id IS NULL OR d.id = target_doctor_id)
    ),
    appointments_today AS (
        SELECT
            a.time,
            a.doctor_id,
            a.time + (a.duration_minutes || ' minutes')::INTERVAL as end_time
        FROM appointments a
        WHERE a.date = target_date
        AND a.status NOT IN ('cancelled')
    )
    SELECT
        ts.slot_time,
        NOT EXISTS (
            SELECT 1 FROM appointments_today at
            WHERE at.doctor_id = dl.id
            AND (
                ts.slot_time >= at.time AND ts.slot_time < at.end_time
                OR
                (ts.slot_time + (slot_duration || ' minutes')::INTERVAL) > at.time
                AND ts.slot_time < at.end_time
            )
        ) as is_available,
        dl.id as doctor_id,
        dl.name as doctor_name
    FROM time_slots ts
    CROSS JOIN doctor_list dl
    ORDER BY dl.name, ts.slot_time;
END;
$$ LANGUAGE plpgsql;

-- Function to book an appointment with conflict checking
CREATE OR REPLACE FUNCTION book_appointment(
    p_patient_id UUID,
    p_patient_name TEXT,
    p_doctor_id UUID,
    p_doctor_name TEXT,
    p_date DATE,
    p_time TIME,
    p_duration_minutes INTEGER DEFAULT 30,
    p_notes TEXT DEFAULT '',
    p_is_spontaneous BOOLEAN DEFAULT false,
    p_is_new_patient BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
    new_appointment_id UUID;
    capacity_check RECORD;
BEGIN
    -- Check daily capacity
    SELECT dc.*,
           COALESCE(scheduled.count, 0) as current_scheduled,
           COALESCE(spontaneous.count, 0) as current_spontaneous
    INTO capacity_check
    FROM daily_capacity dc
    LEFT JOIN (
        SELECT COUNT(*) as count
        FROM appointments
        WHERE date = p_date AND is_spontaneous = false AND status != 'cancelled'
    ) scheduled ON true
    LEFT JOIN (
        SELECT COUNT(*) as count
        FROM appointments
        WHERE date = p_date AND is_spontaneous = true AND status != 'cancelled'
    ) spontaneous ON true
    WHERE dc.date = p_date;

    -- Create capacity record if it doesn't exist
    IF capacity_check IS NULL THEN
        INSERT INTO daily_capacity (date) VALUES (p_date);
        SELECT 20 as max_appointments, 5 as max_spontaneous, 0 as current_scheduled, 0 as current_spontaneous
        INTO capacity_check;
    END IF;

    -- Check capacity limits
    IF p_is_spontaneous THEN
        IF capacity_check.current_spontaneous >= capacity_check.max_spontaneous THEN
            RAISE EXCEPTION 'No spontaneous appointment slots available for this date';
        END IF;
    ELSE
        IF capacity_check.current_scheduled >= capacity_check.max_appointments THEN
            RAISE EXCEPTION 'No scheduled appointment slots available for this date';
        END IF;
    END IF;

    -- Check for doctor availability (overlap check is handled by trigger)
    INSERT INTO appointments (
        patient_id,
        patient_name,
        doctor_id,
        doctor_name,
        date,
        time,
        duration_minutes,
        notes,
        is_spontaneous,
        is_new_patient,
        status
    ) VALUES (
        p_patient_id,
        p_patient_name,
        p_doctor_id,
        p_doctor_name,
        p_date,
        p_time,
        p_duration_minutes,
        p_notes,
        p_is_spontaneous,
        p_is_new_patient,
        'scheduled'
    ) RETURNING id INTO new_appointment_id;

    RETURN new_appointment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to check in a patient (mark as arrived)
CREATE OR REPLACE FUNCTION checkin_patient(
    appointment_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE appointments
    SET
        status = 'arrived',
        arrived_at = NOW()
    WHERE id = appointment_id
    AND status = 'scheduled'
    AND date = CURRENT_DATE;

    IF FOUND THEN
        RETURN true;
    ELSE
        RAISE EXCEPTION 'Appointment not found or cannot be checked in';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to start a consultation
CREATE OR REPLACE FUNCTION start_consultation(
    appointment_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE appointments
    SET
        status = 'in_progress',
        started_at = NOW()
    WHERE id = appointment_id
    AND status = 'arrived';

    IF FOUND THEN
        RETURN true;
    ELSE
        RAISE EXCEPTION 'Appointment not found or patient has not arrived';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to complete a consultation
CREATE OR REPLACE FUNCTION complete_consultation(
    appointment_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE appointments
    SET
        status = 'completed',
        completed_at = NOW()
    WHERE id = appointment_id
    AND status = 'in_progress';

    IF FOUND THEN
        RETURN true;
    ELSE
        RAISE EXCEPTION 'Appointment not found or consultation has not started';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PATIENT MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to search patients with fuzzy matching
CREATE OR REPLACE FUNCTION search_patients(
    search_term TEXT,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    dni TEXT,
    phone TEXT,
    email TEXT,
    last_appointment_date DATE,
    pending_tasks_count INTEGER,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.dni,
        p.phone,
        p.email,
        ps.last_appointment_date,
        ps.pending_tasks_count::INTEGER,
        GREATEST(
            similarity(p.name, search_term),
            similarity(p.dni, search_term),
            similarity(p.phone, search_term),
            similarity(p.email, search_term)
        ) as similarity_score
    FROM patients p
    LEFT JOIN patient_summary ps ON p.id = ps.id
    WHERE
        p.name ILIKE '%' || search_term || '%'
        OR p.dni ILIKE '%' || search_term || '%'
        OR p.phone ILIKE '%' || search_term || '%'
        OR p.email ILIKE '%' || search_term || '%'
        OR similarity(p.name, search_term) > 0.3
    ORDER BY similarity_score DESC, p.name
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get patient's complete medical history
CREATE OR REPLACE FUNCTION get_patient_history(
    patient_id UUID
)
RETURNS TABLE (
    event_date DATE,
    event_type TEXT,
    description TEXT,
    doctor_name TEXT,
    details JSONB
) AS $$
BEGIN
    RETURN QUERY
    -- Appointments
    SELECT
        a.date,
        'Cita Médica'::TEXT,
        CASE
            WHEN a.is_spontaneous THEN 'Consulta Espontánea'
            ELSE 'Consulta Programada'
        END || ' - ' || a.status,
        a.doctor_name,
        jsonb_build_object(
            'time', a.time,
            'notes', a.notes,
            'duration', a.duration_minutes,
            'appointment_id', a.id
        )
    FROM appointments a
    WHERE a.patient_id = get_patient_history.patient_id

    UNION ALL

    -- Medical Notes
    SELECT
        mn.created_at::DATE,
        'Nota Médica'::TEXT,
        'Nota ' || mn.note_type,
        mn.doctor_name,
        jsonb_build_object(
            'note_text', mn.note_text,
            'note_type', mn.note_type,
            'is_confidential', mn.is_confidential,
            'note_id', mn.id
        )
    FROM medical_notes mn
    WHERE mn.patient_id = get_patient_history.patient_id

    UNION ALL

    -- Completed Tasks
    SELECT
        pt.completed_at::DATE,
        'Tarea Completada'::TEXT,
        pt.type || ': ' || pt.description,
        pt.assigned_doctor,
        jsonb_build_object(
            'priority', pt.priority,
            'notes', pt.notes,
            'task_id', pt.id
        )
    FROM pending_tasks pt
    WHERE pt.patient_id = get_patient_history.patient_id
    AND pt.status = 'completada'

    ORDER BY event_date DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TASK MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create a pending task
CREATE OR REPLACE FUNCTION create_pending_task(
    p_patient_id UUID,
    p_type task_type,
    p_description TEXT,
    p_due_date DATE,
    p_priority task_priority DEFAULT 'media',
    p_assigned_doctor_id UUID DEFAULT NULL,
    p_assigned_doctor TEXT DEFAULT '',
    p_notes TEXT DEFAULT ''
)
RETURNS UUID AS $$
DECLARE
    new_task_id UUID;
    patient_name_var TEXT;
    doctor_name_var TEXT;
BEGIN
    -- Get patient name
    SELECT name INTO patient_name_var
    FROM patients
    WHERE id = p_patient_id;

    IF patient_name_var IS NULL THEN
        RAISE EXCEPTION 'Patient not found';
    END IF;

    -- Get doctor name if ID provided
    IF p_assigned_doctor_id IS NOT NULL THEN
        SELECT name INTO doctor_name_var
        FROM doctors
        WHERE id = p_assigned_doctor_id;
    ELSE
        doctor_name_var := p_assigned_doctor;
    END IF;

    INSERT INTO pending_tasks (
        patient_id,
        patient_name,
        type,
        description,
        due_date,
        priority,
        assigned_doctor_id,
        assigned_doctor,
        notes
    ) VALUES (
        p_patient_id,
        patient_name_var,
        p_type,
        p_description,
        p_due_date,
        p_priority,
        p_assigned_doctor_id,
        doctor_name_var,
        p_notes
    ) RETURNING id INTO new_task_id;

    RETURN new_task_id;
END;
$$ LANGUAGE plpgsql;

-- Function to complete a pending task
CREATE OR REPLACE FUNCTION complete_task(
    task_id UUID,
    completion_notes TEXT DEFAULT ''
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE pending_tasks
    SET
        status = 'completada',
        completed_at = NOW(),
        notes = CASE
            WHEN completion_notes != '' THEN
                COALESCE(notes, '') ||
                CASE WHEN notes IS NOT NULL AND notes != '' THEN E'\n\n' ELSE '' END ||
                'Completada: ' || completion_notes
            ELSE notes
        END
    WHERE id = task_id
    AND status != 'completada';

    IF FOUND THEN
        RETURN true;
    ELSE
        RAISE EXCEPTION 'Task not found or already completed';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get overdue tasks
CREATE OR REPLACE FUNCTION get_overdue_tasks()
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    patient_name TEXT,
    type task_type,
    description TEXT,
    due_date DATE,
    priority task_priority,
    assigned_doctor TEXT,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pt.id,
        pt.patient_id,
        pt.patient_name,
        pt.type,
        pt.description,
        pt.due_date,
        pt.priority,
        pt.assigned_doctor,
        (CURRENT_DATE - pt.due_date)::INTEGER as days_overdue
    FROM pending_tasks pt
    WHERE pt.status != 'completada'
    AND pt.due_date < CURRENT_DATE
    ORDER BY pt.priority DESC, pt.due_date ASC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- REPORTING FUNCTIONS
-- =====================================================

-- Function to get daily statistics
CREATE OR REPLACE FUNCTION get_daily_stats(
    target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    total_appointments INTEGER,
    scheduled_appointments INTEGER,
    spontaneous_appointments INTEGER,
    completed_appointments INTEGER,
    cancelled_appointments INTEGER,
    arrived_patients INTEGER,
    in_progress_consultations INTEGER,
    average_wait_time_minutes NUMERIC,
    average_consultation_time_minutes NUMERIC,
    unique_doctors INTEGER,
    new_patients INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_appointments,
        COUNT(*) FILTER (WHERE is_spontaneous = false)::INTEGER as scheduled_appointments,
        COUNT(*) FILTER (WHERE is_spontaneous = true)::INTEGER as spontaneous_appointments,
        COUNT(*) FILTER (WHERE status = 'completed')::INTEGER as completed_appointments,
        COUNT(*) FILTER (WHERE status = 'cancelled')::INTEGER as cancelled_appointments,
        COUNT(*) FILTER (WHERE status IN ('arrived', 'in_progress', 'completed'))::INTEGER as arrived_patients,
        COUNT(*) FILTER (WHERE status = 'in_progress')::INTEGER as in_progress_consultations,
        AVG(EXTRACT(EPOCH FROM (started_at - arrived_at))/60) FILTER (WHERE started_at IS NOT NULL AND arrived_at IS NOT NULL) as average_wait_time_minutes,
        AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/60) FILTER (WHERE completed_at IS NOT NULL AND started_at IS NOT NULL) as average_consultation_time_minutes,
        COUNT(DISTINCT doctor_id)::INTEGER as unique_doctors,
        COUNT(*) FILTER (WHERE is_new_patient = true)::INTEGER as new_patients
    FROM appointments
    WHERE date = target_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get doctor performance metrics
CREATE OR REPLACE FUNCTION get_doctor_performance(
    doctor_id UUID,
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    doctor_name TEXT,
    total_appointments INTEGER,
    completed_appointments INTEGER,
    completion_rate NUMERIC,
    average_consultation_time_minutes NUMERIC,
    patient_satisfaction_score NUMERIC,
    punctuality_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.name,
        COUNT(a.id)::INTEGER as total_appointments,
        COUNT(a.id) FILTER (WHERE a.status = 'completed')::INTEGER as completed_appointments,
        ROUND(
            (COUNT(a.id) FILTER (WHERE a.status = 'completed')::NUMERIC /
            NULLIF(COUNT(a.id), 0) * 100), 2
        ) as completion_rate,
        ROUND(
            AVG(EXTRACT(EPOCH FROM (a.completed_at - a.started_at))/60)
            FILTER (WHERE a.completed_at IS NOT NULL AND a.started_at IS NOT NULL), 2
        ) as average_consultation_time_minutes,
        -- Placeholder for patient satisfaction (would need separate table)
        NULL::NUMERIC as patient_satisfaction_score,
        -- Punctuality: percentage of appointments that started within 15 minutes of scheduled time
        ROUND(
            (COUNT(a.id) FILTER (WHERE
                a.started_at IS NOT NULL AND
                a.started_at <= (a.date + a.time + INTERVAL '15 minutes')
            )::NUMERIC / NULLIF(COUNT(a.id) FILTER (WHERE a.started_at IS NOT NULL), 0) * 100), 2
        ) as punctuality_score
    FROM doctors d
    LEFT JOIN appointments a ON d.id = a.doctor_id
        AND a.date BETWEEN start_date AND end_date
    WHERE d.id = get_doctor_performance.doctor_id
    GROUP BY d.id, d.name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to cleanup old data (for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_data(
    days_to_keep INTEGER DEFAULT 365
)
RETURNS TEXT AS $$
DECLARE
    cutoff_date DATE;
    deleted_count INTEGER;
    total_deleted INTEGER := 0;
BEGIN
    cutoff_date := CURRENT_DATE - days_to_keep;

    -- Delete old completed appointments
    DELETE FROM appointments
    WHERE date < cutoff_date
    AND status = 'completed';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;

    -- Delete old audit logs (keep 2 years)
    DELETE FROM audit_log
    WHERE timestamp < CURRENT_DATE - INTERVAL '2 years';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;

    -- Delete old capacity records with no appointments
    DELETE FROM daily_capacity dc
    WHERE dc.date < cutoff_date
    AND NOT EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.date = dc.date
    );
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;

    RETURN 'Cleanup completed. Deleted ' || total_deleted || ' records older than ' || cutoff_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get database health status
CREATE OR REPLACE FUNCTION get_database_health()
RETURNS TABLE (
    metric TEXT,
    value TEXT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Patients'::TEXT, COUNT(*)::TEXT, 'INFO'::TEXT FROM patients
    UNION ALL
    SELECT 'Active Doctors'::TEXT, COUNT(*)::TEXT, 'INFO'::TEXT FROM doctors WHERE is_active = true
    UNION ALL
    SELECT 'Appointments This Month'::TEXT, COUNT(*)::TEXT, 'INFO'::TEXT
    FROM appointments WHERE date >= date_trunc('month', CURRENT_DATE)
    UNION ALL
    SELECT 'Pending Tasks'::TEXT, COUNT(*)::TEXT,
           CASE WHEN COUNT(*) > 100 THEN 'WARNING' ELSE 'OK' END
    FROM pending_tasks WHERE status != 'completada'
    UNION ALL
    SELECT 'Overdue Tasks'::TEXT, COUNT(*)::TEXT,
           CASE WHEN COUNT(*) > 10 THEN 'ERROR' WHEN COUNT(*) > 5 THEN 'WARNING' ELSE 'OK' END
    FROM pending_tasks WHERE status != 'completada' AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;