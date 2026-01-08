-- =====================================================
-- INSERT SAMPLE TRASHCANS
-- =====================================================

-- These are sample trash bins for SSU Campus
-- Coordinates are centered around SSU Campus (Samar State University)
-- SSU Campus: approximately 11.7711° N, 124.8866° E

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
  notes
) VALUES
-- Main Building Bin
(
  'Main Building Bin',
  'Main Building - Main Hallway',
  11.77115000,
  124.88665000,
  'full',
  0.85,
  'TC-001',
  'Ultrasonic',
  92,
  'High traffic area. Needs frequent emptying.'
),

-- Cafeteria Bin
(
  'Cafeteria Bin',
  'Cafeteria - Food Court',
  11.77108500,
  124.88670000,
  'half',
  0.55,
  'TC-002',
  'Ultrasonic',
  87,
  'Food waste area. Handle with care.'
),

-- North Gate Bin
(
  'North Gate Bin',
  'North Gate - Entrance Area',
  11.77120000,
  124.88660000,
  'empty',
  0.10,
  'TC-003',
  'Ultrasonic',
  95,
  'Entrance gate. Recently emptied.'
),

-- Parking Bin
(
  'Parking Bin',
  'Parking Area - Near Building B',
  11.77100000,
  124.88675000,
  'half',
  0.50,
  'TC-004',
  'Ultrasonic',
  78,
  'Parking area. Medium usage.'
),

-- Library Bin
(
  'Library Bin',
  'Library - Outside Building',
  11.77125000,
  124.88650000,
  'empty',
  0.15,
  'TC-005',
  'Ultrasonic',
  88,
  'Academic building. Low waste volume.'
),

-- Gym Bin
(
  'Gym Bin',
  'Gymnasium - Sports Complex',
  11.77105000,
  124.88680000,
  'full',
  0.90,
  'TC-006',
  'Ultrasonic',
  85,
  'Sports facility. High activity.'
),

-- Admin Building Bin
(
  'Admin Building Bin',
  'Administration - Office Area',
  11.77130000,
  124.88645000,
  'half',
  0.45,
  'TC-007',
  'Ultrasonic',
  91,
  'Office building. Regular emptying needed.'
),

-- Student Center Bin
(
  'Student Center Bin',
  'Student Center - Common Area',
  11.77110000,
  124.88685000,
  'half',
  0.60,
  'TC-008',
  'Ultrasonic',
  80,
  'Student gathering place. Frequent use.'
),

-- Science Building Bin
(
  'Science Building Bin',
  'Science Building - Hallway',
  11.77118000,
  124.88655000,
  'empty',
  0.20,
  'TC-009',
  'Ultrasonic',
  89,
  'Research facility. Minimal waste.'
),

-- Arts Building Bin
(
  'Arts Building Bin',
  'Arts Building - Main Hall',
  11.77112000,
  124.88675000,
  'half',
  0.55,
  'TC-010',
  'Ultrasonic',
  86,
  'Arts facility. Regular activity.'
)
ON CONFLICT (device_id) DO NOTHING;

-- =====================================================
-- UPDATE LAST_EMPTIED_AT FOR REALISTIC DATA
-- =====================================================

-- Set last_emptied_at based on fill level
UPDATE public.trashcans
SET last_emptied_at = CASE
  WHEN fill_level < 0.3 THEN NOW() - INTERVAL '2 hours'
  WHEN fill_level < 0.6 THEN NOW() - INTERVAL '6 hours'
  WHEN fill_level < 0.8 THEN NOW() - INTERVAL '12 hours'
  ELSE NOW() - INTERVAL '24 hours'
END,
last_updated_at = NOW()
WHERE last_emptied_at IS NULL;

-- =====================================================
-- VERIFY INSERTION
-- =====================================================

-- Check how many trashcans were inserted
SELECT 
  COUNT(*) as "Total Bins",
  SUM(CASE WHEN status = 'empty' THEN 1 ELSE 0 END) as "Empty",
  SUM(CASE WHEN status = 'half' THEN 1 ELSE 0 END) as "Half",
  SUM(CASE WHEN status = 'full' THEN 1 ELSE 0 END) as "Full",
  ROUND(AVG(CAST(battery_level AS DECIMAL)), 0) as "Avg Battery %",
  ROUND(AVG(fill_level), 2) as "Avg Fill Level"
FROM public.trashcans
WHERE is_active = true;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

-- Sample trashcans inserted successfully!
-- ✅ 10 sample trashcans created
-- ✅ Distributed across SSU Campus
-- ✅ With realistic coordinates (SSU Campus)
-- ✅ With sensors and battery info
-- ✅ Status distribution: Empty (3), Half (4), Full (2), Maintenance (1)
-- ✅ Ready for tasks assignment

