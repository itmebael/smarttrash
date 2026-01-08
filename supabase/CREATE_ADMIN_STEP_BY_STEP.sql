-- =====================================================
-- CREATE ADMIN ACCOUNT - STEP BY STEP METHOD
-- This script guides you through creating the admin account
-- =====================================================

-- STEP 1: First, you MUST create the auth user via Supabase Dashboard
-- Go to: https://app.supabase.com/project/_/auth/users
-- Click "Add User" and enter:
--   - Email: admin@ssu.edu.ph
--   - Password: admin123
--   - Auto Confirm User: YES (enable this!)
-- Then come back and run STEP 2 below

-- STEP 2: Check if auth user exists
DO $$
DECLARE
  auth_user_id UUID;
BEGIN
  SELECT id INTO auth_user_id
  FROM auth.users
  WHERE email = 'admin@ssu.edu.ph';

  IF auth_user_id IS NULL THEN
    RAISE EXCEPTION '❌ Auth user not found! Please create the user in Supabase Dashboard first (see STEP 1 above)';
  ELSE
    RAISE NOTICE '✅ Auth user found with ID: %', auth_user_id;
  END IF;
END $$;

-- STEP 3: Link auth user to public.users table with admin role
INSERT INTO public.users (
  id, 
  email, 
  name, 
  phone_number,
  role, 
  is_active,
  created_at,
  updated_at
)
SELECT 
  id,
  email,
  'System Administrator',
  '+639123456789',
  'admin',
  true,
  NOW(),
  NOW()
FROM auth.users 
WHERE email = 'admin@ssu.edu.ph'
ON CONFLICT (id) 
DO UPDATE SET 
  role = 'admin', 
  is_active = true,
  name = 'System Administrator',
  phone_number = '+639123456789',
  updated_at = NOW();

-- STEP 4: Verify everything is set up correctly
DO $$
DECLARE
  admin_record RECORD;
BEGIN
  SELECT u.id, u.email, u.name, u.role, u.is_active
  INTO admin_record
  FROM public.users u
  WHERE u.email = 'admin@ssu.edu.ph';

  IF admin_record IS NOT NULL THEN
    RAISE NOTICE '==============================================';
    RAISE NOTICE '✅ ADMIN ACCOUNT CREATED SUCCESSFULLY!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ID: %', admin_record.id;
    RAISE NOTICE 'Email: %', admin_record.email;
    RAISE NOTICE 'Name: %', admin_record.name;
    RAISE NOTICE 'Role: %', admin_record.role;
    RAISE NOTICE 'Active: %', admin_record.is_active;
    RAISE NOTICE '==============================================';
    RAISE NOTICE '🎉 You can now log in with:';
    RAISE NOTICE '   Email: admin@ssu.edu.ph';
    RAISE NOTICE '   Password: admin123';
    RAISE NOTICE '==============================================';
  ELSE
    RAISE EXCEPTION '❌ Failed to create admin account in database';
  END IF;
END $$;

