-- =====================================================
-- CREATE STAFF FUNCTION - Run this after QUICK_SETUP.sql
-- This allows admins to create staff accounts that save online
-- =====================================================

-- Drop all versions of the function if they exist
DROP FUNCTION IF EXISTS create_staff_account CASCADE;

-- Create function to allow admins to create staff accounts
CREATE OR REPLACE FUNCTION create_staff_account(
  admin_id UUID,
  staff_email TEXT,
  staff_name TEXT,
  staff_phone TEXT,
  staff_department TEXT,
  staff_position TEXT,
  staff_password TEXT
)
RETURNS JSON AS $$
DECLARE
  new_user_id UUID;
  result JSON;
BEGIN
  -- Check if caller is admin (works with both auth users and hardcoded admin)
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can create staff accounts';
  END IF;

  -- Generate new UUID for the staff member
  new_user_id := gen_random_uuid();

  -- Insert into users table
  INSERT INTO users (
    id,
    email,
    name,
    phone_number,
    role,
    department,
    position,
    is_active,
    created_at,
    updated_at
  )
  VALUES (
    new_user_id,
    staff_email,
    staff_name,
    staff_phone,
    'staff',
    staff_department,
    staff_position,
    true,
    NOW(),
    NOW()
  );

  -- Return success with user details
  result := json_build_object(
    'success', true,
    'user_id', new_user_id,
    'email', staff_email,
    'name', staff_name,
    'message', 'Staff account created successfully'
  );

  RETURN result;

EXCEPTION
  WHEN unique_violation THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Email already exists'
    );
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to both authenticated and anonymous users
GRANT EXECUTE ON FUNCTION create_staff_account(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;

-- =====================================================
-- SUCCESS!
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ Staff creation function installed!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Admins can now create staff accounts that save online';
  RAISE NOTICE 'Usage: SELECT create_staff_account(...);';
  RAISE NOTICE '==============================================';
END $$;

