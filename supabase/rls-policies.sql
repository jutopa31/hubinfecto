-- HubInfecto - Row Level Security Policies
-- Security configuration for medical data protection
-- Generated: 2025-09-15

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_capacity ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- AUTHENTICATION FUNCTIONS
-- =====================================================

-- Function to check if user is authenticated
CREATE OR REPLACE FUNCTION auth.is_authenticated()
RETURNS boolean AS $$
BEGIN
  RETURN auth.uid() IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has admin role
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() ->> 'role')::text = 'admin',
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is a doctor
CREATE OR REPLACE FUNCTION auth.is_doctor()
RETURNS boolean AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() ->> 'role')::text IN ('doctor', 'admin'),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is staff (doctor, nurse, admin, receptionist)
CREATE OR REPLACE FUNCTION auth.is_staff()
RETURNS boolean AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() ->> 'role')::text IN ('doctor', 'nurse', 'admin', 'receptionist'),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current user's doctor ID
CREATE OR REPLACE FUNCTION auth.get_doctor_id()
RETURNS uuid AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() ->> 'doctor_id')::uuid,
    NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PATIENTS TABLE POLICIES
-- =====================================================

-- Patients can be read by all authenticated staff
CREATE POLICY "Staff can view all patients"
ON patients FOR SELECT
TO authenticated
USING (auth.is_staff());

-- Only admins and doctors can create patients
CREATE POLICY "Doctors and admins can create patients"
ON patients FOR INSERT
TO authenticated
WITH CHECK (auth.is_doctor());

-- Only admins and doctors can update patients
CREATE POLICY "Doctors and admins can update patients"
ON patients FOR UPDATE
TO authenticated
USING (auth.is_doctor())
WITH CHECK (auth.is_doctor());

-- Only admins can delete patients
CREATE POLICY "Only admins can delete patients"
ON patients FOR DELETE
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- DOCTORS TABLE POLICIES
-- =====================================================

-- All staff can view active doctors
CREATE POLICY "Staff can view active doctors"
ON doctors FOR SELECT
TO authenticated
USING (auth.is_staff() AND is_active = true);

-- Only admins can manage doctors
CREATE POLICY "Only admins can manage doctors"
ON doctors FOR ALL
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

-- =====================================================
-- APPOINTMENTS TABLE POLICIES
-- =====================================================

-- All staff can view appointments
CREATE POLICY "Staff can view appointments"
ON appointments FOR SELECT
TO authenticated
USING (auth.is_staff());

-- Staff can create appointments
CREATE POLICY "Staff can create appointments"
ON appointments FOR INSERT
TO authenticated
WITH CHECK (auth.is_staff());

-- Staff can update appointments, doctors can only update their own
CREATE POLICY "Staff can update appointments"
ON appointments FOR UPDATE
TO authenticated
USING (
  auth.is_admin() OR
  auth.is_staff() OR
  (auth.is_doctor() AND doctor_id = auth.get_doctor_id())
)
WITH CHECK (
  auth.is_admin() OR
  auth.is_staff() OR
  (auth.is_doctor() AND doctor_id = auth.get_doctor_id())
);

-- Only admins can delete appointments
CREATE POLICY "Only admins can delete appointments"
ON appointments FOR DELETE
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- PENDING TASKS TABLE POLICIES
-- =====================================================

-- All staff can view pending tasks
CREATE POLICY "Staff can view pending tasks"
ON pending_tasks FOR SELECT
TO authenticated
USING (auth.is_staff());

-- Staff can create pending tasks
CREATE POLICY "Staff can create pending tasks"
ON pending_tasks FOR INSERT
TO authenticated
WITH CHECK (auth.is_staff());

-- Staff can update tasks, doctors can update their assigned tasks
CREATE POLICY "Staff can update pending tasks"
ON pending_tasks FOR UPDATE
TO authenticated
USING (
  auth.is_admin() OR
  auth.is_staff() OR
  (auth.is_doctor() AND assigned_doctor_id = auth.get_doctor_id())
)
WITH CHECK (
  auth.is_admin() OR
  auth.is_staff() OR
  (auth.is_doctor() AND assigned_doctor_id = auth.get_doctor_id())
);

-- Only admins can delete pending tasks
CREATE POLICY "Only admins can delete pending tasks"
ON pending_tasks FOR DELETE
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- MEDICAL NOTES TABLE POLICIES
-- =====================================================

-- Doctors can view notes for their patients or their own notes
CREATE POLICY "Doctors can view relevant medical notes"
ON medical_notes FOR SELECT
TO authenticated
USING (
  auth.is_admin() OR
  (auth.is_doctor() AND (
    doctor_id = auth.get_doctor_id() OR
    patient_id IN (
      SELECT patient_id FROM appointments
      WHERE doctor_id = auth.get_doctor_id()
    )
  ))
);

-- Only doctors can create medical notes
CREATE POLICY "Only doctors can create medical notes"
ON medical_notes FOR INSERT
TO authenticated
WITH CHECK (auth.is_doctor());

-- Doctors can only update their own notes
CREATE POLICY "Doctors can update their own notes"
ON medical_notes FOR UPDATE
TO authenticated
USING (
  auth.is_admin() OR
  (auth.is_doctor() AND doctor_id = auth.get_doctor_id())
)
WITH CHECK (
  auth.is_admin() OR
  (auth.is_doctor() AND doctor_id = auth.get_doctor_id())
);

-- Only admins can delete medical notes
CREATE POLICY "Only admins can delete medical notes"
ON medical_notes FOR DELETE
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- DAILY CAPACITY TABLE POLICIES
-- =====================================================

-- All staff can view daily capacity
CREATE POLICY "Staff can view daily capacity"
ON daily_capacity FOR SELECT
TO authenticated
USING (auth.is_staff());

-- Only admins can manage daily capacity
CREATE POLICY "Only admins can manage daily capacity"
ON daily_capacity FOR INSERT
TO authenticated
WITH CHECK (auth.is_admin());

CREATE POLICY "Only admins can update daily capacity"
ON daily_capacity FOR UPDATE
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

CREATE POLICY "Only admins can delete daily capacity"
ON daily_capacity FOR DELETE
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- VIEW POLICIES
-- =====================================================

-- Enable RLS on views that need it
ALTER VIEW appointment_stats ENABLE ROW LEVEL SECURITY;
ALTER VIEW daily_capacity_usage ENABLE ROW LEVEL SECURITY;
ALTER VIEW patient_summary ENABLE ROW LEVEL SECURITY;

-- Policies for views (inherit from base tables)
CREATE POLICY "Staff can view appointment stats"
ON appointment_stats FOR SELECT
TO authenticated
USING (auth.is_staff());

CREATE POLICY "Staff can view daily capacity usage"
ON daily_capacity_usage FOR SELECT
TO authenticated
USING (auth.is_staff());

CREATE POLICY "Staff can view patient summary"
ON patient_summary FOR SELECT
TO authenticated
USING (auth.is_staff());

-- =====================================================
-- UTILITY FUNCTIONS FOR POLICY MANAGEMENT
-- =====================================================

-- Function to create a new user with role
CREATE OR REPLACE FUNCTION create_user_with_role(
  email text,
  password text,
  user_role text,
  doctor_id uuid DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  new_user_id uuid;
BEGIN
  -- Validate role
  IF user_role NOT IN ('admin', 'doctor', 'nurse', 'receptionist') THEN
    RAISE EXCEPTION 'Invalid role. Must be one of: admin, doctor, nurse, receptionist';
  END IF;

  -- Create user in auth.users (this would typically be done via Supabase Auth API)
  -- This is a placeholder - actual implementation depends on your auth setup
  RAISE NOTICE 'User creation should be handled via Supabase Auth API';
  RAISE NOTICE 'After user creation, update their profile with role: % and doctor_id: %', user_role, doctor_id;

  RETURN NULL; -- Return the actual user ID when implemented
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(
  user_id uuid,
  new_role text,
  new_doctor_id uuid DEFAULT NULL
)
RETURNS boolean AS $$
BEGIN
  -- Validate role
  IF new_role NOT IN ('admin', 'doctor', 'nurse', 'receptionist') THEN
    RAISE EXCEPTION 'Invalid role. Must be one of: admin, doctor, nurse, receptionist';
  END IF;

  -- Update user metadata (implementation depends on your user profile setup)
  RAISE NOTICE 'Update user % with role: % and doctor_id: %', user_id, new_role, new_doctor_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- AUDIT AND LOGGING
-- =====================================================

-- Create audit log table
CREATE TABLE audit_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    table_name text NOT NULL,
    operation text NOT NULL, -- INSERT, UPDATE, DELETE
    record_id uuid,
    old_data jsonb,
    new_data jsonb,
    user_id uuid,
    user_email text,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function for audit logging
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS trigger AS $$
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation,
        record_id,
        old_data,
        new_data,
        user_id,
        user_email
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) ELSE NULL END,
        auth.uid(),
        auth.email()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_patients_trigger
    AFTER INSERT OR UPDATE OR DELETE ON patients
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_appointments_trigger
    AFTER INSERT OR UPDATE OR DELETE ON appointments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_medical_notes_trigger
    AFTER INSERT OR UPDATE OR DELETE ON medical_notes
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- RLS policy for audit log (only admins can view)
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only admins can view audit log"
ON audit_log FOR SELECT
TO authenticated
USING (auth.is_admin());

-- =====================================================
-- SECURITY NOTES AND RECOMMENDATIONS
-- =====================================================

/*
SECURITY IMPLEMENTATION NOTES:

1. JWT Token Structure:
   Your JWT tokens should include:
   {
     "role": "doctor|nurse|admin|receptionist",
     "doctor_id": "uuid-if-doctor",
     "email": "user@example.com"
   }

2. User Profile Setup:
   - Create a user_profiles table if needed
   - Link users to doctors table for medical staff
   - Implement proper role assignment

3. API Security:
   - Always validate user permissions on the client side
   - Use Supabase client with proper JWT handling
   - Implement proper session management

4. Data Privacy:
   - Medical notes should be encrypted at rest
   - Implement audit logging for all sensitive operations
   - Regular security audits recommended

5. Backup and Recovery:
   - Regular encrypted backups
   - Test restore procedures
   - Document access procedures for emergencies

6. Compliance:
   - Ensure HIPAA compliance if applicable
   - Document all access patterns
   - Regular access reviews
*/