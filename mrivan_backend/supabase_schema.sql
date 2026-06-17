-- Enable UUID extension if not already done
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create Classes Table (Organizes students into sections)
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    room_number TEXT
);

-- 2. Alter Profiles to add CRM details (references classes, self-references profiles for parent)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS student_roll_number TEXT,
ADD COLUMN IF NOT EXISTS teacher_specialization TEXT;

-- 3. Create Class Teachers Table (Many-to-many relationship)
CREATE TABLE IF NOT EXISTS class_teachers (
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (class_id, teacher_id)
);

-- 4. Alter Attendance to add class_id link
ALTER TABLE attendance
ADD COLUMN IF NOT EXISTS class_id UUID REFERENCES classes(id) ON DELETE SET NULL;

-- 5. Create Homework Table
CREATE TABLE IF NOT EXISTS homework (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. Create Homework Submissions Table
CREATE TABLE IF NOT EXISTS homework_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    homework_id UUID REFERENCES homework(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    submission_text TEXT,
    file_url TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    grade TEXT,
    feedback TEXT,
    UNIQUE (homework_id, student_id)
);

-- 7. Create AI Chat Sessions Table (Tracks sessions per user)
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 8. Create AI Chat Messages Table
CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    sender TEXT CHECK (sender IN ('user', 'ai')) NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 9. Create Notes Table (For study materials and AI-generated summaries)
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL, -- Markdown formatting
    subject TEXT,
    class_level TEXT,
    is_ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 10. Create Mock Tests Table
CREATE TABLE IF NOT EXISTS mock_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    subject TEXT NOT NULL,
    duration_minutes INTEGER DEFAULT 60 NOT NULL,
    total_marks INTEGER DEFAULT 100 NOT NULL,
    questions JSONB DEFAULT '[]'::jsonb NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 11. Create Test Attempts Table
CREATE TABLE IF NOT EXISTS test_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID REFERENCES mock_tests(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    score INTEGER,
    answers JSONB DEFAULT '{}'::jsonb NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Additional Scale Indexing
CREATE INDEX IF NOT EXISTS idx_profiles_school ON profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_classes_school ON classes(school_id);
CREATE INDEX IF NOT EXISTS idx_homework_class ON homework(class_id);
CREATE INDEX IF NOT EXISTS idx_submissions_homework ON homework_submissions(homework_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON ai_chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_student ON test_attempts(student_id);

-- Additional profile fields for custom registration
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS class TEXT,
ADD COLUMN IF NOT EXISTS age TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT;
