-- =====================================================
-- CREATE ADMIN ACCOUNT - Run this in Supabase SQL Editor
-- This creates the admin user for your app
-- =====================================================

-- First, ensure the users table exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    RAISE EXCEPTION 'Users table not found! Please run QUICK_SETUP.sql first.';
  END IF;
END $$;

-- Create admin user in auth.users (this is the authentication user)
-- Note: You may need to do this via Supabase Dashboard > Authentication > Add User
-- because direct INSERT into auth.users may not work in SQL Editor

-- Alternative: Use Supabase Dashboard to create user, then run this:
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Click "Add User"
-- 3. Enter:
--    - Email: admin@ssu.edu.ph
--    - Password: admin123
--    - Auto Confirm User: YES (enable this!)
-- 4. Click "Create User"
-- 5. Then run the SQL below to link the user to your database:

-- Link the auth user to the users table with admin role
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

-- Verify the admin account was created
DO $$
DECLARE
  admin_count INTEGER;
  auth_user_id UUID;
BEGIN
  -- Check if admin exists in public.users
  SELECT COUNT(*) INTO admin_count
  FROM public.users
  WHERE email = 'admin@ssu.edu.ph' AND role = 'admin';

  -- Get auth user id
  SELECT id INTO auth_user_id
  FROM auth.users
  WHERE email = 'admin@ssu.edu.ph';

  RAISE NOTICE '==============================================';
  IF admin_count > 0 AND auth_user_id IS NOT NULL THEN
    RAISE NOTICE '✅ Admin account created successfully!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Email: admin@ssu.edu.ph';
    RAISE NOTICE 'Password: admin123';
    RAISE NOTICE 'Auth User ID: %', auth_user_id;
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'You can now log in to your Flutter app!';
  ELSIF auth_user_id IS NULL THEN
    RAISE NOTICE '⚠️  Auth user not found!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Please create the user via Supabase Dashboard:';
    RAISE NOTICE '1. Go to Authentication > Users';
    RAISE NOTICE '2. Click "Add User"';
    RAISE NOTICE '3. Email: admin@ssu.edu.ph';
    RAISE NOTICE '4. Password: admin123';
    RAISE NOTICE '5. Auto Confirm User: YES';
    RAISE NOTICE '6. Then run this SQL script again';
  ELSE
    RAISE NOTICE '⚠️  Database user not linked!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Run this SQL script again to link the user.';
  END IF;
  RAISE NOTICE '==============================================';
END $$;

