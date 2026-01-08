-- ============================================
-- VERIFY TRASHCAN SAVE TO DATABASE
-- ============================================

-- 1. Check if add_trashcan function exists
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments,
    pg_get_functiondef(oid) AS definition
FROM pg_proc 
WHERE proname = 'add_trashcan';

-- 2. View all trashcans in the database
SELECT 
    id,
    name,
    location,
    latitude,
    longitude,
    status,
    fill_level,
    device_id,
    sensor_type,
    is_active,
    created_at,
    last_updated_at
FROM public.trashcans
ORDER BY created_at DESC;

-- 3. Count total trashcans
SELECT COUNT(*) as total_trashcans FROM public.trashcans;

-- 4. Count active trashcans (what the app shows)
SELECT COUNT(*) as active_trashcans 
FROM public.trashcans 
WHERE is_active = true;

-- 5. View most recently added trashcan
SELECT 
    id,
    name,
    location,
    latitude,
    longitude,
    device_id,
    sensor_type,
    created_at
FROM public.trashcans
ORDER BY created_at DESC
LIMIT 1;

-- ============================================
-- TEST THE add_trashcan FUNCTION MANUALLY
-- ============================================

-- Test adding a trashcan (uncomment to test)
/*
SELECT add_trashcan(
    'Test Bin - DELETE ME',
    'Test Location',
    12.8797,
    124.8447,
    'TEST-001',
    'Ultrasonic'
);
*/

-- Verify the test trashcan was added
/*
SELECT * FROM public.trashcans 
WHERE name = 'Test Bin - DELETE ME'
ORDER BY created_at DESC
LIMIT 1;
*/

-- Delete the test trashcan
/*
DELETE FROM public.trashcans 
WHERE name = 'Test Bin - DELETE ME';
*/

-- ============================================
-- TROUBLESHOOTING QUERIES
-- ============================================

-- Check table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'trashcans'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check constraints
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.trashcans'::regclass;

-- Check if table has insert permissions
SELECT 
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'trashcans'
AND table_schema = 'public';

-- ============================================
-- EXPECTED RESULTS WHEN ADDING TRASHCAN
-- ============================================

/*
When you add a trashcan through the app:

1. The add_trashcan function is called
2. A new row is inserted into public.trashcans with:
   - id: auto-generated UUID
   - name: your input
   - location: your input
   - latitude: selected on map
   - longitude: selected on map
   - status: 'empty' (default)
   - fill_level: 0.0 (default)
   - device_id: your input or NULL
   - sensor_type: your input or NULL
   - is_active: true (default)
   - created_at: current timestamp (default)
   - last_updated_at: current timestamp (default)
   - battery_level: NULL (default)
   - last_emptied_at: NULL (default)
   - notes: NULL (default)

3. The function returns the new trashcan's UUID
4. The app reloads all active trashcans
5. The map shows the new trashcan
*/

