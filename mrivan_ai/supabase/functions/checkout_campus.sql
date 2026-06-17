-- This function acts as the /api/checkout/campus endpoint, executing atomically.
CREATE OR REPLACE FUNCTION checkout_campus(
    p_school_name TEXT,
    p_student_count INT,
    p_admin_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to create the school
AS $$
DECLARE
    v_school_id UUID;
    v_invite_code TEXT;
    v_result JSONB;
BEGIN
    -- Input validation
    IF p_school_name IS NULL OR p_school_name = '' THEN
        RAISE EXCEPTION 'School name is required';
    END IF;

    IF p_student_count <= 0 THEN
        RAISE EXCEPTION 'Student count must be greater than zero';
    END IF;

    -- Generate a random 8-character uppercase alphanumeric invite code
    v_invite_code := upper(substring(md5(random()::text), 1, 8));

    -- Create the school record atomically
    INSERT INTO schools (
        name,
        total_seats,
        invite_code,
        admin_id
    ) VALUES (
        p_school_name,
        p_student_count,
        v_invite_code,
        p_admin_id
    ) RETURNING id INTO v_school_id;

    -- Update the user's profile to indicate they are a school admin
    UPDATE profiles
    SET 
        school_id = v_school_id,
        payment_plan = 'Campus Plan',
        role = 'Admin'
    WHERE id = p_admin_id;

    -- Return success payload
    v_result := jsonb_build_object(
        'success', true,
        'school_id', v_school_id,
        'invite_code', v_invite_code,
        'student_count', p_student_count
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        -- The transaction is automatically rolled back if an exception occurs
        RAISE EXCEPTION 'Failed to create campus school: %', SQLERRM;
END;
$$;
