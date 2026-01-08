-- =====================================================
-- STAFF MANAGEMENT - USEFUL SQL QUERIES
-- =====================================================
-- This file contains helpful SQL queries for staff management
-- Run these in Supabase SQL Editor: https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

-- =====================================================
-- 1. VIEW ALL STAFF
-- =====================================================
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  is_active,
  created_at
FROM users
WHERE role = 'staff'
ORDER BY created_at DESC;


-- =====================================================
-- 2. VIEW ACTIVE STAFF ONLY
-- =====================================================
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  created_at
FROM users
WHERE role = 'staff' AND is_active = true
ORDER BY name ASC;


-- =====================================================
-- 3. VIEW INACTIVE STAFF
-- =====================================================
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  created_at
FROM users
WHERE role = 'staff' AND is_active = false
ORDER BY name ASC;


-- =====================================================
-- 4. GET STAFF BY DEPARTMENT
-- =====================================================
-- Replace 'Sanitation' with desired department
SELECT 
  id,
  email,
  name,
  phone_number,
  position,
  is_active
FROM users
WHERE role = 'staff' AND department = 'Sanitation'
ORDER BY name ASC;


-- =====================================================
-- 5. GET STAFF STATISTICS
-- =====================================================
SELECT 
  COUNT(*) as total_staff,
  SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_staff,
  SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) as inactive_staff
FROM users
WHERE role = 'staff';


-- =====================================================
-- 6. GET STAFF COUNT BY DEPARTMENT
-- =====================================================
SELECT 
  department,
  COUNT(*) as staff_count,
  SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_count
FROM users
WHERE role = 'staff'
GROUP BY department
ORDER BY staff_count DESC;


-- =====================================================
-- 7. CREATE NEW STAFF (INSERT EXAMPLE)
-- =====================================================
-- Replace values with actual staff information
INSERT INTO users (
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
  date_of_birth,
  emergency_contact,
  emergency_phone,
  is_active
) VALUES (
  'john.doe@ssu.edu.ph',
  'John Doe',
  '+639123456789',
  'staff',
  'Sanitation',
  'Collection Staff',
  28,
  '123 Main Street',
  'Mindanao',
  'Zamboanga del Sur',
  '6400',
  '1996-05-15',
  'Jane Doe',
  '+639987654321',
  true
);


-- =====================================================
-- 8. UPDATE STAFF INFORMATION
-- =====================================================
-- Replace 'staff_id' with actual UUID
UPDATE users
SET 
  phone_number = '+639111111111',
  department = 'New Department',
  position = 'New Position',
  updated_at = NOW()
WHERE id = 'staff_id' AND role = 'staff';


-- =====================================================
-- 9. DEACTIVATE STAFF
-- =====================================================
-- Replace 'staff_id' with actual UUID
UPDATE users
SET 
  is_active = false,
  updated_at = NOW()
WHERE id = 'staff_id' AND role = 'staff';


-- =====================================================
-- 10. REACTIVATE STAFF
-- =====================================================
-- Replace 'staff_id' with actual UUID
UPDATE users
SET 
  is_active = true,
  updated_at = NOW()
WHERE id = 'staff_id' AND role = 'staff';


-- =====================================================
-- 11. DELETE STAFF
-- =====================================================
-- Replace 'staff_id' with actual UUID
-- WARNING: This is permanent deletion
DELETE FROM users
WHERE id = 'staff_id' AND role = 'staff';


-- =====================================================
-- 12. SEARCH STAFF
-- =====================================================
-- Search by name, email, or phone number
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  is_active
FROM users
WHERE role = 'staff' AND (
  name ILIKE '%john%' OR 
  email ILIKE '%john%' OR 
  phone_number ILIKE '%john%'
)
ORDER BY name ASC;


-- =====================================================
-- 13. GET STAFF WITH DETAILED INFORMATION
-- =====================================================
SELECT 
  id,
  email,
  name,
  phone_number,
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
FROM users
WHERE role = 'staff'
ORDER BY created_at DESC;


-- =====================================================
-- 14. GET STAFF CREATED IN LAST 30 DAYS
-- =====================================================
SELECT 
  id,
  email,
  name,
  department,
  created_at
FROM users
WHERE role = 'staff' AND created_at > NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;


-- =====================================================
-- 15. GET STAFF WITH UPCOMING BIRTHDAYS (30 DAYS)
-- =====================================================
SELECT 
  id,
  name,
  email,
  date_of_birth,
  department
FROM users
WHERE role = 'staff' AND 
  date_of_birth IS NOT NULL AND (
    TO_CHAR(date_of_birth, 'MM-DD') 
    BETWEEN TO_CHAR(CURRENT_DATE, 'MM-DD') 
    AND TO_CHAR(CURRENT_DATE + INTERVAL '30 days', 'MM-DD')
  )
ORDER BY date_of_birth ASC;


-- =====================================================
-- 16. GET STAFF NEVER LOGGED IN
-- =====================================================
SELECT 
  id,
  email,
  name,
  department,
  created_at
FROM users
WHERE role = 'staff' AND last_login_at IS NULL
ORDER BY created_at ASC;


-- =====================================================
-- 17. UPDATE MULTIPLE STAFF TO SAME DEPARTMENT
-- =====================================================
-- Change staff to 'Maintenance' department (replace IDs)
UPDATE users
SET 
  department = 'Maintenance',
  updated_at = NOW()
WHERE role = 'staff' AND id IN (
  'staff_id_1',
  'staff_id_2',
  'staff_id_3'
);


-- =====================================================
-- 18. GET STAFF WITH COMPLETE INFORMATION
-- =====================================================
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  position,
  is_active,
  created_at,
  (SELECT COUNT(*) FROM tasks WHERE assigned_staff_id = users.id) as assigned_tasks,
  (SELECT COUNT(*) FROM tasks WHERE assigned_staff_id = users.id AND status = 'completed') as completed_tasks
FROM users
WHERE role = 'staff'
ORDER BY name ASC;


-- =====================================================
-- 19. BULK IMPORT STAFF
-- =====================================================
-- Use CSV import or INSERT ... SELECT
-- Example: Import from temporary table
INSERT INTO users (email, name, phone_number, role, department, position, is_active)
SELECT 
  email,
  name,
  phone_number,
  'staff' as role,
  department,
  position,
  true as is_active
FROM imported_staff_data
WHERE email NOT IN (SELECT email FROM users WHERE role = 'staff');


-- =====================================================
-- 20. EXPORT STAFF DATA
-- =====================================================
-- Copy this output to CSV
COPY (
  SELECT 
    id,
    email,
    name,
    phone_number,
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
  FROM users
  WHERE role = 'staff'
  ORDER BY created_at DESC
) TO STDOUT WITH CSV HEADER;


-- =====================================================
-- 21. STAFF ACTIVITY SUMMARY
-- =====================================================
SELECT 
  u.id,
  u.name,
  u.email,
  u.department,
  COUNT(t.id) as total_tasks,
  SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
  SUM(CASE WHEN t.status = 'pending' THEN 1 ELSE 0 END) as pending_tasks,
  SUM(CASE WHEN t.status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_tasks,
  MAX(t.completed_at) as last_task_completed
FROM users u
LEFT JOIN tasks t ON u.id = t.assigned_staff_id
WHERE u.role = 'staff'
GROUP BY u.id, u.name, u.email, u.department
ORDER BY total_tasks DESC;


-- =====================================================
-- 22. GET STAFF BY POSITION
-- =====================================================
-- Replace 'Collection Staff' with desired position
SELECT 
  id,
  email,
  name,
  phone_number,
  department,
  is_active
FROM users
WHERE role = 'staff' AND position = 'Collection Staff'
ORDER BY name ASC;


-- =====================================================
-- 23. GET TOTAL STAFF PER CITY
-- =====================================================
SELECT 
  city,
  COUNT(*) as staff_count,
  SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_count
FROM users
WHERE role = 'staff' AND city IS NOT NULL
GROUP BY city
ORDER BY staff_count DESC;


-- =====================================================
-- 24. CHECK STAFF TABLE SIZE
-- =====================================================
SELECT 
  COUNT(*) as total_records,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
  COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_records,
  COUNT(DISTINCT department) as unique_departments,
  COUNT(DISTINCT position) as unique_positions
FROM users
WHERE role = 'staff';


-- =====================================================
-- 25. AUDIT LOG - RECENT STAFF CHANGES
-- =====================================================
SELECT 
  user_id,
  action,
  entity_type,
  details,
  created_at
FROM activity_logs
WHERE entity_type = 'users' AND action IN ('UPDATE', 'DELETE', 'INSERT')
ORDER BY created_at DESC
LIMIT 50;


-- =====================================================
-- HELPFUL INDEXES
-- =====================================================
-- These indexes are already created but here for reference

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_department ON users(department);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- =====================================================
-- NOTES
-- =====================================================
-- 1. Replace 'staff_id' with actual UUID from users table
-- 2. All queries are read-safe unless marked as DELETE
-- 3. Always backup before running DELETE queries
-- 4. Date format is ISO 8601 (YYYY-MM-DD)
-- 5. Phone numbers should include country code
-- 6. All timestamps are in UTC with timezone



