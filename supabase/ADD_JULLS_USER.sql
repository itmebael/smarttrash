-- =====================================================
-- ADD julls@gmail.com TO public.users TABLE
-- =====================================================
-- This script adds the julls user to the database so they can login
-- Run this in Supabase SQL Editor

-- Step 1: Insert julls user into public.users table
INSERT INTO public.users (
  id,
  email,
  name,
  phone_number,
  role,
  profile_image_url,
  fcm_token,
  age,
  address,
  city,
  state,
  zip_code,
  department,
  position,
  date_of_birth,
  emergency_contact,
  emergency_phone,
  is_active,
  created_at,
  updated_at,
  last_login_at
) VALUES (
  gen_random_uuid(),  -- Generate random UUID
  'julls@gmail.com',
  'Julls User',
  '+639123456789',
  'staff',
  NULL,
  NULL,
  28,
  '123 Staff Street',
  'Mindanao',
  'Zamboanga del Sur',
  '6400',
  'Sanitation Department',
  'Collection Staff',
  '1996-05-15'::date,
  'Emergency Contact Name',
  '+639987654321',
  true,
  now(),
  now(),
  NULL
)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  role = EXCLUDED.role,
  is_active = true,
  updated_at = now();

-- Step 2: Verify the user was added
SELECT 
  id,
  email,
  name,
  role,
  department,
  position,
  is_active,
  created_at
FROM public.users 
WHERE email = 'julls@gmail.com';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'julls user added to database!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Email: julls@gmail.com';
  RAISE NOTICE 'Password: julls@gmail.com (from Supabase Auth)';
  RAISE NOTICE 'Role: staff';
  RAISE NOTICE '';
  RAISE NOTICE 'Now you can login in the app:';
  RAISE NOTICE '  1. Go to Login screen';
  RAISE NOTICE '  2. Email: julls@gmail.com';
  RAISE NOTICE '  3. Password: julls@gmail.com';
  RAISE NOTICE '  4. Click LOGIN';
  RAISE NOTICE '  5. Should see Staff Dashboard!';
  RAISE NOTICE '==============================================';
END $$;

