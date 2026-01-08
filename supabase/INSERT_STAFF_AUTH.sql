-- =====================================================
-- INSERT STAFF USER INTO public.users TABLE
-- =====================================================
-- Run this in Supabase SQL Editor to add staff user
-- https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

-- =====================================================
-- 1. INSERT TEST STAFF USER
-- =====================================================

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
  '00000000-0000-0000-0000-000000000002'::uuid,
  'staff@ssu.edu.ph',
  'Staff Member',
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
  phone_number = EXCLUDED.phone_number,
  department = EXCLUDED.department,
  position = EXCLUDED.position,
  is_active = true,
  updated_at = now();

-- =====================================================
-- 2. INSERT ADMIN USER (OPTIONAL)
-- =====================================================

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
  '00000000-0000-0000-0000-000000000001'::uuid,
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  NULL,
  NULL,
  45,
  '456 Admin Avenue',
  'Mindanao',
  'Zamboanga del Sur',
  '6400',
  'Administration',
  'System Administrator',
  '1980-03-20'::date,
  'Admin Contact',
  '+639123456788',
  true,
  now(),
  now(),
  NULL
)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  role = 'admin',
  department = 'Administration',
  is_active = true,
  updated_at = now();

-- =====================================================
-- 3. INSERT ADDITIONAL STAFF MEMBERS (OPTIONAL)
-- =====================================================

INSERT INTO public.users (
  email,
  name,
  phone_number,
  role,
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
  updated_at
) VALUES
  (
    'john.doe@ssu.edu.ph',
    'John Doe',
    '+639111111111',
    'staff',
    35,
    '456 Collection Ave',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Sanitation Department',
    'Waste Collection Officer',
    '1989-07-12'::date,
    'Jane Doe',
    '+639111111112',
    true,
    now(),
    now()
  ),
  (
    'jane.smith@ssu.edu.ph',
    'Jane Smith',
    '+639222222222',
    'staff',
    32,
    '789 Maintenance Blvd',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Maintenance Department',
    'Maintenance Staff',
    '1992-11-08'::date,
    'John Smith',
    '+639222222223',
    true,
    now(),
    now()
  ),
  (
    'mike.johnson@ssu.edu.ph',
    'Mike Johnson',
    '+639333333333',
    'staff',
    40,
    '321 Senior St',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Sanitation Department',
    'Senior Collection Staff',
    '1984-02-14'::date,
    'Sarah Johnson',
    '+639333333334',
    true,
    now(),
    now()
  ),
  (
    'sarah.williams@ssu.edu.ph',
    'Sarah Williams',
    '+639444444444',
    'staff',
    26,
    '654 Admin Place',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Administration',
    'Coordinator',
    '1998-09-22'::date,
    'Michael Williams',
    '+639444444445',
    true,
    now(),
    now()
  )
ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- 4. VERIFY INSERTS
-- =====================================================

SELECT '=== STAFF USERS ===' as section;
SELECT id, email, name, role, department, position, is_active FROM public.users WHERE role = 'staff' ORDER BY created_at;

SELECT '=== ADMIN USERS ===' as section;
SELECT id, email, name, role, is_active FROM public.users WHERE role = 'admin';

SELECT '=== TOTAL USERS ===' as section;
SELECT COUNT(*) as total_users, 
       SUM(CASE WHEN role = 'staff' THEN 1 ELSE 0 END) as staff_count,
       SUM(CASE WHEN role = 'admin' THEN 1 ELSE 0 END) as admin_count
FROM public.users;

-- =====================================================
-- 5. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Staff users inserted successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Test Credentials:';
  RAISE NOTICE '';
  RAISE NOTICE 'ADMIN:';
  RAISE NOTICE '  Email: admin@ssu.edu.ph';
  RAISE NOTICE '  Password: admin123';
  RAISE NOTICE '';
  RAISE NOTICE 'STAFF:';
  RAISE NOTICE '  Email: staff@ssu.edu.ph';
  RAISE NOTICE '  Password: staff123';
  RAISE NOTICE '';
  RAISE NOTICE 'ADDITIONAL STAFF:';
  RAISE NOTICE '  john.doe@ssu.edu.ph';
  RAISE NOTICE '  jane.smith@ssu.edu.ph';
  RAISE NOTICE '  mike.johnson@ssu.edu.ph';
  RAISE NOTICE '  sarah.williams@ssu.edu.ph';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Now create these users in Supabase Auth:';
  RAISE NOTICE '1. Go to: Authentication → Users';
  RAISE NOTICE '2. Click: Add user';
  RAISE NOTICE '3. Email: staff@ssu.edu.ph';
  RAISE NOTICE '4. Password: staff123';
  RAISE NOTICE '5. Click: Create user';
  RAISE NOTICE '==============================================';
END $$;

