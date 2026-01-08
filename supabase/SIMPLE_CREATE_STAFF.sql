-- ============================================
-- SIMPLE STAFF ACCOUNT CREATION
-- ============================================
-- Based on public.users table with role check
-- If role = 'staff' → Staff Dashboard
-- If role = 'admin' → Admin Dashboard
-- ============================================

-- Step 1: Create authentication user
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
) ON CONFLICT (email) DO NOTHING;

-- Step 2: Create user profile with role = 'staff'
INSERT INTO public.users (
  id,
  email,
  name,
  phone_number,
  role,  -- 'staff' will route to staff dashboard
  department,
  position,
  is_active
)
SELECT 
  au.id,
  'staff@ssu.edu.ph',
  'Staff Member',
  '+639123456789',
  'staff',  -- ← This determines the dashboard!
  'Sanitation',
  'Collection Staff',
  true
FROM auth.users au
WHERE au.email = 'staff@ssu.edu.ph'
ON CONFLICT (id) DO UPDATE SET
  role = 'staff',
  is_active = true;

-- Verify the account
SELECT 
  email,
  name,
  role,
  department,
  is_active,
  created_at
FROM public.users
WHERE email = 'staff@ssu.edu.ph';

