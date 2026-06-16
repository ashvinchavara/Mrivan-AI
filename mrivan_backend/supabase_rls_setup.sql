-- 1. Ensure Profiles Table is defined matching your core schema
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'teacher', 'student', 'parent')) DEFAULT 'student',
    school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL,
    full_name TEXT
);

-- Enable Row Level Security (RLS) on Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read profiles (needed for checking roles/schools)
CREATE POLICY select_all_authenticated_profiles ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow users to update their own full name
CREATE POLICY update_own_profile ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);


-- 2. Create an Automatic Profile Creation Trigger
-- This function runs automatically whenever a new user registers in Supabase Auth (e.g. via Google Login)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, school_id)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), -- Fallback to email name if name metadata doesn't exist
    'student', -- Default role set to student
    NULL -- School is initially null, to be assigned by a School Admin
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind the trigger function to the auth.users table
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 3. Row Level Security (RLS) for the Attendance Table
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Policy A: Students can only SELECT their own attendance records
CREATE POLICY student_select_own_attendance ON public.attendance
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = student_id
    );

-- Policy B: Teachers can SELECT, INSERT, and UPDATE records where their school_id matches the record
CREATE POLICY teacher_manage_school_attendance ON public.attendance
    FOR ALL -- Grants SELECT, INSERT, UPDATE, DELETE privileges
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'teacher'
              AND profiles.school_id = attendance.school_id
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'teacher'
              AND profiles.school_id = attendance.school_id
        )
    );

-- Policy C: Admins have full access to their specific school_id
CREATE POLICY admin_full_school_attendance ON public.attendance
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
              AND profiles.school_id = attendance.school_id
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
              AND profiles.school_id = attendance.school_id
        )
    );
