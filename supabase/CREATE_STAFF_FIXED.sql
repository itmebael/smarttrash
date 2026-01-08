-- ============================================
-- CREATE STAFF ACCOUNT - FIXED VERSION
-- ============================================

-- Step 1: Check if staff already exists
DO $$
BEGIN
  -- Only create if doesn't exist
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'staff@ssu.edu.ph') THEN
    -- Create authentication user
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      role,
      aud
    ) VALUES (
      gen_random_uuid(),
      '00000000-0000-0000-0000-000000000000',
      'staff@ssu.edu.ph',
      crypt('staff123', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      FALSE,
      'authenticated',
      'authenticated'
    );
    
    RAISE NOTICE '✅ Auth user created for staff@ssu.edu.ph';
  ELSE
    RAISE NOTICE 'ℹ️  Auth user already exists for staff@ssu.edu.ph';
  END IF;
END $$;

-- Step 2: Create or update public.users profile
DO $$
DECLARE
  staff_user_id UUID;
BEGIN
  -- Get the user ID from auth.users
  SELECT id INTO staff_user_id 
  FROM auth.users 
  WHERE email = 'staff@ssu.edu.ph';
  
  -- Check if profile exists
  IF EXISTS (SELECT 1 FROM public.users WHERE id = staff_user_id) THEN
    -- Update existing profile
    UPDATE public.users
    SET 
      role = 'staff',
      name = 'Staff Member',
      phone_number = '+639123456789',
      department = 'Sanitation',
      position = 'Collection Staff',
      is_active = true
    WHERE id = staff_user_id;
    
    RAISE NOTICE '✅ Profile updated for staff@ssu.edu.ph';
  ELSE
    -- Create new profile
    INSERT INTO public.users (
      id,
      email,
      name,
      phone_number,
      role,
      department,
      position,
      is_active
    ) VALUES (
      staff_user_id,
      'staff@ssu.edu.ph',
      'Staff Member',
      '+639123456789',
      'staff',
      'Sanitation',
      'Collection Staff',
      true
    );
    
    RAISE NOTICE '✅ Profile created for staff@ssu.edu.ph';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'STAFF ACCOUNT READY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Email: staff@ssu.edu.ph';
  RAISE NOTICE 'Password: staff123';
  RAISE NOTICE 'Role: staff';
  RAISE NOTICE '========================================';
END $$;

-- Step 3: Verify the account
SELECT 
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active,
  created_at
FROM public.users
WHERE email = 'staff@ssu.edu.ph';









