-- ============================================
-- FETCH STAFF ACCOUNTS FROM DATABASE
-- ============================================

-- 1. GET ALL STAFF ACCOUNTS
SELECT 
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active,
  created_at,
  last_login_at
FROM public.users
WHERE role = 'staff'
ORDER BY created_at DESC;

-- 2. GET ALL ACTIVE STAFF ACCOUNTS
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  is_active,
  created_at
FROM public.users
WHERE role = 'staff' 
  AND is_active = true
ORDER BY name ASC;

-- 3. GET STAFF COUNT
SELECT 
  COUNT(*) as total_staff
FROM public.users
WHERE role = 'staff';

-- 4. GET STAFF COUNT BY STATUS
SELECT 
  is_active,
  COUNT(*) as count
FROM public.users
WHERE role = 'staff'
GROUP BY is_active;

-- 5. GET STAFF BY DEPARTMENT
SELECT 
  department,
  COUNT(*) as staff_count,
  array_agg(name) as staff_names
FROM public.users
WHERE role = 'staff'
  AND is_active = true
GROUP BY department
ORDER BY staff_count DESC;

-- 6. GET SPECIFIC STAFF BY EMAIL
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

-- 7. GET STAFF WITH AUTHENTICATION INFO
SELECT 
  u.id,
  u.email,
  u.name,
  u.role,
  u.department,
  u.position,
  u.is_active,
  u.created_at,
  au.email_confirmed_at,
  au.last_sign_in_at
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.role = 'staff'
ORDER BY u.created_at DESC;

-- 8. SEARCH STAFF BY NAME OR EMAIL
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position
FROM public.users
WHERE role = 'staff'
  AND (
    name ILIKE '%staff%' 
    OR email ILIKE '%staff%'
  )
ORDER BY name;

-- 9. GET ALL USERS WITH ROLE INFORMATION
SELECT 
  id,
  email,
  name,
  role,
  department,
  is_active,
  created_at
FROM public.users
ORDER BY 
  CASE role 
    WHEN 'admin' THEN 1 
    WHEN 'staff' THEN 2 
  END,
  created_at DESC;

-- 10. VERIFY STAFF CAN LOGIN
-- Check if staff account exists in both auth and public tables
SELECT 
  'Auth Table' as table_name,
  COUNT(*) as count
FROM auth.users
WHERE email = 'staff@ssu.edu.ph'
UNION ALL
SELECT 
  'Public Table' as table_name,
  COUNT(*) as count
FROM public.users
WHERE email = 'staff@ssu.edu.ph' AND role = 'staff';

-- ============================================
-- USEFUL FUNCTIONS FOR STAFF MANAGEMENT
-- ============================================

-- Function to get staff summary
CREATE OR REPLACE FUNCTION get_staff_summary()
RETURNS TABLE (
  total_staff INTEGER,
  active_staff INTEGER,
  inactive_staff INTEGER
) 
LANGUAGE SQL
AS $$
  SELECT 
    COUNT(*)::INTEGER as total_staff,
    COUNT(*) FILTER (WHERE is_active = true)::INTEGER as active_staff,
    COUNT(*) FILTER (WHERE is_active = false)::INTEGER as inactive_staff
  FROM public.users
  WHERE role = 'staff';
$$;

-- Use the function
SELECT * FROM get_staff_summary();

-- ============================================
-- CREATE VIEW FOR EASY STAFF ACCESS
-- ============================================

CREATE OR REPLACE VIEW staff_list AS
SELECT 
  u.id,
  u.email,
  u.name,
  u.phone_number,
  u.department,
  u.position,
  u.is_active,
  u.created_at,
  u.last_login_at,
  au.last_sign_in_at as last_authenticated_at
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.role = 'staff';

-- Now you can simply query:
SELECT * FROM staff_list ORDER BY name;

-- ============================================
-- QUICK VERIFICATION QUERIES
-- ============================================

-- Check if staff@ssu.edu.ph exists and can login
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM auth.users WHERE email = 'staff@ssu.edu.ph'
    ) 
    AND EXISTS (
      SELECT 1 FROM public.users WHERE email = 'staff@ssu.edu.ph' AND role = 'staff'
    )
    THEN '✅ Staff account exists and ready to login'
    ELSE '❌ Staff account not found or incomplete'
  END as status;

-- Get staff account details for login verification
SELECT 
  u.email,
  u.name,
  u.role,
  u.is_active,
  CASE 
    WHEN au.email_confirmed_at IS NOT NULL THEN '✅ Email Confirmed'
    ELSE '⚠️ Email Not Confirmed'
  END as email_status,
  CASE 
    WHEN u.is_active = true THEN '✅ Account Active'
    ELSE '❌ Account Inactive'
  END as account_status
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE u.email = 'staff@ssu.edu.ph';









