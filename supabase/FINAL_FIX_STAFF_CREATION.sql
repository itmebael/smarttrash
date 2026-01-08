-- =====================================================
-- FINAL FIX - Staff Creation with Hardcoded Admin Support
-- Run this to make staff creation work 100%
-- =====================================================

-- Step 1: Ensure hardcoded admin exists in public.users
INSERT INTO public.users (
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
  '00000000-0000-0000-0000-000000000001'::uuid,
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  'Administration',
  'System Administrator',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  email = 'admin@ssu.edu.ph',
  name = 'System Administrator',
  is_active = true,
  updated_at = NOW();

-- Step 2: Drop and recreate the staff creation function with better error handling
DROP FUNCTION IF EXISTS create_staff_account(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

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
  hardcoded_admin_id UUID := '00000000-0000-0000-0000-000000000001'::UUID;
  is_admin BOOLEAN := FALSE;
  admin_found TEXT := '';
BEGIN
  -- Debug: Check what admin_id we received
  RAISE NOTICE 'Received admin_id: %', admin_id;
  
  -- Check if it's the hardcoded admin
  IF admin_id = hardcoded_admin_id THEN
    is_admin := TRUE;
    admin_found := 'hardcoded_admin';
    RAISE NOTICE 'Hardcoded admin detected';
  ELSE
    -- Check if it's a real admin from database
    SELECT EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = admin_id 
        AND role = 'admin' 
        AND is_active = true
    ) INTO is_admin;
    
    IF is_admin THEN
      admin_found := 'database_admin';
      RAISE NOTICE 'Database admin found';
    END IF;
  END IF;
  
  -- Reject if not admin
  IF NOT is_admin THEN
    RAISE NOTICE 'Admin check failed for ID: %', admin_id;
    RETURN json_build_object(
      'success', false,
      'error', 'Only admins can create staff accounts',
      'admin_id_received', admin_id::text,
      'hint', 'Please log out and log back in'
    );
  END IF;

  -- Generate new UUID for the staff member
  new_user_id := gen_random_uuid();
  
  RAISE NOTICE 'Creating staff with email: %', staff_email;

  -- Insert into public.users table
  INSERT INTO public.users (
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

  RAISE NOTICE 'Staff user created in public.users: %', new_user_id;

  -- Return success
  result := json_build_object(
    'success', true,
    'user_id', new_user_id,
    'email', staff_email,
    'name', staff_name,
    'password', staff_password,
    'admin_type', admin_found,
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
    RAISE NOTICE 'Error in create_staff_account: %', SQLERRM;
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_staff_account(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;

-- Step 3: Verify everything is ready
DO $$
DECLARE
  admin_exists BOOLEAN;
  func_exists BOOLEAN;
BEGIN
  -- Check hardcoded admin
  SELECT EXISTS(
    SELECT 1 FROM public.users 
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
    AND role = 'admin'
  ) INTO admin_exists;
  
  -- Check function
  SELECT EXISTS(
    SELECT 1 FROM pg_proc 
    WHERE proname = 'create_staff_account'
  ) INTO func_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ FINAL FIX COMPLETE!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Hardcoded admin exists: %', CASE WHEN admin_exists THEN 'YES ✅' ELSE 'NO ❌' END;
  RAISE NOTICE 'Function installed: %', CASE WHEN func_exists THEN 'YES ✅' ELSE 'NO ❌' END;
  RAISE NOTICE '';
  
  IF admin_exists AND func_exists THEN
    RAISE NOTICE '🎉 Everything is ready!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Restart your Flutter app (press R)';
    RAISE NOTICE '2. Try creating a staff account';
    RAISE NOTICE '3. It should work now!';
  ELSE
    RAISE NOTICE '⚠️  Something is missing - check above';
  END IF;
  
  RAISE NOTICE '==============================================';
END $$;

-- Step 4: Show admin account details
SELECT 
  '=== ADMIN ACCOUNT ===' as section,
  id,
  email,
  name,
  role,
  is_active,
  'Ready to create staff!' as status
FROM public.users
WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

