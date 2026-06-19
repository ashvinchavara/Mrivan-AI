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
DROP POLICY IF EXISTS select_all_authenticated_profiles ON public.profiles;
CREATE POLICY select_all_authenticated_profiles ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow users to manage (INSERT, UPDATE, DELETE) their own profile
DROP POLICY IF EXISTS update_own_profile ON public.profiles;
DROP POLICY IF EXISTS insert_own_profile ON public.profiles;
DROP POLICY IF EXISTS manage_own_profile ON public.profiles;
CREATE POLICY manage_own_profile ON public.profiles
    FOR ALL
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


-- 4. RLS policies for public.ai_chat_sessions (User's private chat sessions)
ALTER TABLE public.ai_chat_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS select_own_chat_sessions ON public.ai_chat_sessions;
CREATE POLICY select_own_chat_sessions ON public.ai_chat_sessions
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS insert_own_chat_sessions ON public.ai_chat_sessions;
CREATE POLICY insert_own_chat_sessions ON public.ai_chat_sessions
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS update_own_chat_sessions ON public.ai_chat_sessions;
CREATE POLICY update_own_chat_sessions ON public.ai_chat_sessions
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS delete_own_chat_sessions ON public.ai_chat_sessions;
CREATE POLICY delete_own_chat_sessions ON public.ai_chat_sessions
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);


-- 5. RLS policies for public.ai_chat_messages (Messages linked to user's chat sessions)
ALTER TABLE public.ai_chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS select_own_chat_messages ON public.ai_chat_messages;
CREATE POLICY select_own_chat_messages ON public.ai_chat_messages
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.ai_chat_sessions
            WHERE ai_chat_sessions.id = session_id
              AND ai_chat_sessions.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS insert_own_chat_messages ON public.ai_chat_messages;
CREATE POLICY insert_own_chat_messages ON public.ai_chat_messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ai_chat_sessions
            WHERE ai_chat_sessions.id = session_id
              AND ai_chat_sessions.user_id = auth.uid()
        )
    );


-- 6. RLS policies for public.notes (User's private study notes)
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS select_own_notes ON public.notes;
CREATE POLICY select_own_notes ON public.notes
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS insert_own_notes ON public.notes;
CREATE POLICY insert_own_notes ON public.notes
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS update_own_notes ON public.notes;
CREATE POLICY update_own_notes ON public.notes
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS delete_own_notes ON public.notes;
CREATE POLICY delete_own_notes ON public.notes
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
