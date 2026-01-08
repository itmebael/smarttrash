-- ============================================
-- CREATE STAFF ACCOUNT FOR TESTING
-- ============================================

-- Step 1: Insert into auth.users (Supabase authentication)
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
  '{"name":"Test Staff Member"}',
  FALSE,
  'authenticated',
  'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- Step 2: Get the staff user ID and insert into public.users
DO $$
DECLARE
  staff_user_id UUID;
BEGIN
  -- Get the user ID
  SELECT id INTO staff_user_id 
  FROM auth.users 
  WHERE email = 'staff@ssu.edu.ph';
  
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
    created_at
  ) VALUES (
    staff_user_id,
    'staff@ssu.edu.ph',
    'Test Staff Member',
    '+639123456789',
    'staff',
    'Sanitation Department',
    'Collection Staff',
    TRUE,
    NOW()
  ) ON CONFLICT (id) DO UPDATE SET
    role = 'staff',
    name = 'Test Staff Member',
    is_active = TRUE;
  
  RAISE NOTICE 'Staff account created successfully!';
  RAISE NOTICE 'Email: staff@ssu.edu.ph';
  RAISE NOTICE 'Password: staff123';
  RAISE NOTICE 'User ID: %', staff_user_id;
END $$;

-- Step 3: Verify the staff account was created
SELECT 
  u.id,
  u.email,
  u.name,
  u.role,
  u.department,
  u.position,
  u.is_active,
  u.created_at
FROM public.users u
WHERE u.email = 'staff@ssu.edu.ph';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check all users and their roles
SELECT 
  id,
  email,
  name,
  role,
  is_active
FROM public.users
ORDER BY created_at DESC;

-- Count users by role
SELECT 
  role,
  COUNT(*) as count
FROM public.users
GROUP BY role;

