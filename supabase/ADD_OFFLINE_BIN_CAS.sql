-- =====================================================
-- ADD DUMMY BIN WITH OFFLINE STATUS IN CAS BUILDING
-- =====================================================
-- This script adds a trashcan with offline status in CAS Building
-- Run this in Supabase SQL Editor

-- Step 1: Update the status constraint to allow 'offline' status
ALTER TABLE trashcans 
DROP CONSTRAINT IF EXISTS trashcans_status_check;

ALTER TABLE trashcans 
ADD CONSTRAINT trashcans_status_check 
CHECK (status IN ('empty', 'half', 'full', 'maintenance', 'offline'));

-- Step 2: Insert dummy bin in CAS Building with offline status
INSERT INTO public.trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  battery_level,
  notes,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'CAS Building Bin - Offline',
  'CAS Building - 2nd Floor',
  11.77118000,  -- CAS Building coordinates (near other SSU buildings)
  124.88672000,
  'offline',  -- Offline status
  0.0,  -- Fill level unknown when offline
  'TC-CAS-OFFLINE-001',
  'Ultrasonic',
  NULL,  -- Battery level unknown when offline
  'Dummy bin for testing offline status. Located in CAS Building.',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (device_id) DO UPDATE SET
  status = 'offline',
  last_updated_at = NOW();

-- Step 3: Verify the bin was added
SELECT 
  id,
  name,
  location,
  status,
  fill_level,
  device_id,
  battery_level,
  created_at
FROM public.trashcans 
WHERE location LIKE '%CAS%' OR name LIKE '%CAS%'
ORDER BY created_at DESC;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Offline bin added to CAS Building!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Bin Details:';
  RAISE NOTICE '  Name: CAS Building Bin - Offline';
  RAISE NOTICE '  Location: CAS Building - 2nd Floor';
  RAISE NOTICE '  Status: offline';
  RAISE NOTICE '  Device ID: TC-CAS-OFFLINE-001';
  RAISE NOTICE '';
  RAISE NOTICE 'The bin will appear in the app with offline status.';
  RAISE NOTICE '==============================================';
END $$;


-- ADD DUMMY BIN WITH OFFLINE STATUS IN CAS BUILDING
-- =====================================================
-- This script adds a trashcan with offline status in CAS Building
-- Run this in Supabase SQL Editor

-- Step 1: Update the status constraint to allow 'offline' status
ALTER TABLE trashcans 
DROP CONSTRAINT IF EXISTS trashcans_status_check;

ALTER TABLE trashcans 
ADD CONSTRAINT trashcans_status_check 
CHECK (status IN ('empty', 'half', 'full', 'maintenance', 'offline'));

-- Step 2: Insert dummy bin in CAS Building with offline status
INSERT INTO public.trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  battery_level,
  notes,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'CAS Building Bin - Offline',
  'CAS Building - 2nd Floor',
  11.77118000,  -- CAS Building coordinates (near other SSU buildings)
  124.88672000,
  'offline',  -- Offline status
  0.0,  -- Fill level unknown when offline
  'TC-CAS-OFFLINE-001',
  'Ultrasonic',
  NULL,  -- Battery level unknown when offline
  'Dummy bin for testing offline status. Located in CAS Building.',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (device_id) DO UPDATE SET
  status = 'offline',
  last_updated_at = NOW();

-- Step 3: Verify the bin was added
SELECT 
  id,
  name,
  location,
  status,
  fill_level,
  device_id,
  battery_level,
  created_at
FROM public.trashcans 
WHERE location LIKE '%CAS%' OR name LIKE '%CAS%'
ORDER BY created_at DESC;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Offline bin added to CAS Building!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Bin Details:';
  RAISE NOTICE '  Name: CAS Building Bin - Offline';
  RAISE NOTICE '  Location: CAS Building - 2nd Floor';
  RAISE NOTICE '  Status: offline';
  RAISE NOTICE '  Device ID: TC-CAS-OFFLINE-001';
  RAISE NOTICE '';
  RAISE NOTICE 'The bin will appear in the app with offline status.';
  RAISE NOTICE '==============================================';
END $$;


