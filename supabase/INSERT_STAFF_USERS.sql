-- =====================================================
-- INSERT STAFF USERS INTO DATABASE
-- =====================================================
-- Run this SQL in Supabase SQL Editor to add staff members
-- https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

-- =====================================================
-- Insert Test Staff User
-- =====================================================

INSERT INTO public.users (
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  age,
  address,
  city,
  state,
  zip_code,
  emergency_contact,
  emergency_phone,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000002'::uuid,
  'staff@ssu.edu.ph',
  'Staff Member',
  '+639123456789',
  'staff',
  'Sanitation Department',
  'Collection Staff',
  28,
  '123 Staff Street',
  'Mindanao',
  'Zamboanga del Sur',
  '6400',
  'Emergency Contact',
  '+639987654321',
  true
);

-- =====================================================
-- Insert Additional Staff Users
-- =====================================================

INSERT INTO public.users (
  email,
  name,
  phone_number,
  role,
  department,
  position,
  age,
  address,
  city,
  state,
  zip_code,
  emergency_contact,
  emergency_phone,
  is_active
) VALUES
  (
    'john.doe@ssu.edu.ph',
    'John Doe',
    '+639111111111',
    'staff',
    'Sanitation Department',
    'Waste Collection Officer',
    35,
    '456 Collection Ave',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Jane Doe',
    '+639111111112',
    true
  ),
  (
    'jane.smith@ssu.edu.ph',
    'Jane Smith',
    '+639222222222',
    'staff',
    'Maintenance Department',
    'Maintenance Staff',
    32,
    '789 Maintenance Blvd',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'John Smith',
    '+639222222223',
    true
  ),
  (
    'mike.johnson@ssu.edu.ph',
    'Mike Johnson',
    '+639333333333',
    'staff',
    'Sanitation Department',
    'Senior Collection Staff',
    40,
    '321 Senior St',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Sarah Johnson',
    '+639333333334',
    true
  ),
  (
    'sarah.williams@ssu.edu.ph',
    'Sarah Williams',
    '+639444444444',
    'staff',
    'Administration',
    'Coordinator',
    26,
    '654 Admin Place',
    'Mindanao',
    'Zamboanga del Sur',
    '6400',
    'Michael Williams',
    '+639444444445',
    true
  );

-- =====================================================
-- Insert Admin User
-- =====================================================

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
  '00000000-0000-0000-0000-000000000001'::uuid,
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  'Administration',
  'System Administrator',
  true
)
ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- VERIFY INSERTS
-- =====================================================

SELECT 'STAFF USERS:' as info;
SELECT id, email, name, role, department, position FROM public.users WHERE role = 'staff' ORDER BY created_at;

SELECT 'ADMIN USERS:' as info;
SELECT id, email, name, role FROM public.users WHERE role = 'admin';

SELECT COUNT(*) as total_users FROM public.users;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Staff users inserted successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Test Credentials:';
  RAISE NOTICE 'Admin:';
  RAISE NOTICE '  Email: admin@ssu.edu.ph';
  RAISE NOTICE '  Password: admin123';
  RAISE NOTICE '';
  RAISE NOTICE 'Staff:';
  RAISE NOTICE '  Email: staff@ssu.edu.ph';
  RAISE NOTICE '  Password: staff123';
  RAISE NOTICE '';
  RAISE NOTICE 'Additional Staff:';
  RAISE NOTICE '  Email: john.doe@ssu.edu.ph';
  RAISE NOTICE '  Email: jane.smith@ssu.edu.ph';
  RAISE NOTICE '  Email: mike.johnson@ssu.edu.ph';
  RAISE NOTICE '  Email: sarah.williams@ssu.edu.ph';
  RAISE NOTICE '==============================================';
END $$;

