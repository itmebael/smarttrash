-- ============================================
-- INSERT STAFF DIRECTLY INTO DATABASE
-- Uses the actual public.users table structure
-- ============================================

-- Method 1: Simple INSERT (if auth user already exists)
-- First, create a random UUID for the staff
DO $$
DECLARE
  new_staff_id UUID := gen_random_uuid();
BEGIN
  -- Insert into public.users table directly
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
  ) VALUES (
    new_staff_id,
    'staff@ssu.edu.ph',
    'Staff Member',
    '+639123456789',
    'staff',  -- ← This determines Staff Dashboard
    'Sanitation Department',
    'Collection Staff',
    true,
    NOW(),
    NOW()
  );

  -- Also create in auth.users for login
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
    aud,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
  ) VALUES (
    new_staff_id,
    '00000000-0000-0000-0000-000000000000',
    'staff@ssu.edu.ph',
    crypt('staff123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    ''
  );

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ STAFF ACCOUNT CREATED!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ID: %', new_staff_id;
  RAISE NOTICE 'Email: staff@ssu.edu.ph';
  RAISE NOTICE 'Password: staff123';
  RAISE NOTICE 'Role: staff';
  RAISE NOTICE '========================================';
END $$;

-- Verify the staff was created
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

-- Check both tables
SELECT 
  'public.users' as table_name,
  COUNT(*) as count,
  array_agg(email) as emails
FROM public.users
WHERE role = 'staff'
UNION ALL
SELECT 
  'auth.users' as table_name,
  COUNT(*) as count,
  array_agg(email) as emails
FROM auth.users
WHERE email = 'staff@ssu.edu.ph';









