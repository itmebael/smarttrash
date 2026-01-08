-- =====================================================
-- INSERT TRASHCAN TEST DATA
-- =====================================================
-- This script inserts test trashcan data from the trashcans table
-- Run this in Supabase SQL Editor to add sample trashcans
-- =====================================================

-- SSU Campus coordinates: 11.7711° N, 124.8866° E

-- TRASHCAN 1: Empty bin
INSERT INTO public.trashcans (
  name, location, latitude, longitude, 
  status, fill_level, device_id, sensor_type, 
  battery_level, notes
)
VALUES (
  'SSU Main Gate Bin',
  'Main Entrance',
  11.771098, 124.886578,
  'empty', 0.15,
  'ESP32-001', 'Ultrasonic',
  95,
  'Located near the main gate entrance'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 2: Half full bin
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Library Bin',
  'SSU Library',
  11.771500, 124.886800,
  'half', 0.55,
  'ESP32-002', 'Ultrasonic',
  78,
  'Inside the library building'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 3: Full bin
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Cafeteria Bin',
  'Student Cafeteria',
  11.771200, 124.887000,
  'full', 0.92,
  'ESP32-003', 'Ultrasonic',
  45,
  'High traffic area - check frequently'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 4: Maintenance bin
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Engineering Building Bin',
  'Engineering Department',
  11.770800, 124.886300,
  'maintenance', 0.35,
  'ESP32-004', 'Ultrasonic',
  15,
  'Low battery - needs replacement'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 5: Empty bin (Gymnasium)
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Gymnasium Bin',
  'Sports Complex',
  11.771400, 124.886200,
  'empty', 0.08,
  'ESP32-005', 'Ultrasonic',
  88,
  'Near the sports facilities'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 6: Half full bin (Parking)
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Parking Lot Bin',
  'Student Parking Area',
  11.770900, 124.886900,
  'half', 0.48,
  'ESP32-006', 'Ultrasonic',
  62,
  'Outdoor bin - weather resistant'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 7: Empty bin (Admin Building)
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Admin Building Bin',
  'Administration Office',
  11.771600, 124.886400,
  'empty', 0.22,
  'ESP32-007', 'Ultrasonic',
  90,
  'Administrative area'
) ON CONFLICT (device_id) DO NOTHING;

-- TRASHCAN 8: Full bin (Quad Area)
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Quad Area Bin',
  'Central Quad',
  11.770700, 124.886600,
  'full', 0.88,
  'ESP32-008', 'Ultrasonic',
  58,
  'High student foot traffic'
) ON CONFLICT (device_id) DO NOTHING;

-- =====================================================
-- VERIFY THE INSERT
-- =====================================================
-- Run this query to check if the trashcans were inserted
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
  battery_level,
  is_active,
  created_at
FROM public.trashcans
WHERE is_active = true
ORDER BY created_at DESC;

-- =====================================================
-- VIEW STATISTICS
-- =====================================================
-- See count by status
SELECT 
  status,
  COUNT(*) as count
FROM public.trashcans
WHERE is_active = true
GROUP BY status
ORDER BY status;

-- =====================================================
-- CLEAN UP (Optional)
-- =====================================================
-- If you want to delete all test data later, run:
-- DELETE FROM public.trashcans WHERE device_id LIKE 'ESP32-%';

-- =====================================================
-- UPDATE EXISTING TRASHCAN (Example)
-- =====================================================
-- To update a specific trashcan's status:
/*
UPDATE public.trashcans 
SET 
  status = 'full',
  fill_level = 0.95,
  last_updated_at = NOW()
WHERE device_id = 'ESP32-001';
*/

-- =====================================================
-- INSERT A CUSTOM TRASHCAN
-- =====================================================
-- Use this template to add your own custom trashcan:
/*
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'My Custom Bin',       -- Name
  'Custom Location',     -- Location
  11.771098,            -- Latitude
  124.886578,           -- Longitude
  'empty',              -- Status: empty, half, full, maintenance
  0.0,                  -- Fill level: 0.0 to 1.0
  'ESP32-009',          -- Device ID (must be unique)
  'Ultrasonic',         -- Sensor type
  100,                  -- Battery level: 0 to 100
  'Optional notes here' -- Notes
);
*/

-- =====================================================
-- MARK TRASHCAN AS EMPTIED
-- =====================================================
-- When a trashcan is emptied:
/*
UPDATE public.trashcans 
SET 
  status = 'empty',
  fill_level = 0.0,
  last_emptied_at = NOW(),
  last_updated_at = NOW()
WHERE id = 'your-trashcan-id-here';
*/




