-- =====================================================
-- INSERT SMART BIN TEST DATA
-- =====================================================
-- This script inserts test smart bin data for demonstration
-- purposes in the admin dashboard.
--
-- Run this in Supabase SQL Editor to add sample bins.
-- =====================================================

-- First, ensure the smart_bin table exists
-- (Based on the table structure you provided)

-- Insert test smart bins with various statuses
-- SSU Campus coordinates: 11.7711° N, 124.8866° E

-- BIN 1: Empty bin (80-100cm distance = 0-20% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  85.0,
  11.771098,
  124.886578,
  'empty'
) ON CONFLICT DO NOTHING;

-- BIN 2: Low fill bin (60-80cm = 20-40% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  65.0,
  11.771500,
  124.886800,
  'low'
) ON CONFLICT DO NOTHING;

-- BIN 3: Medium fill bin (40-60cm = 40-60% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  50.0,
  11.771200,
  124.887000,
  'medium'
) ON CONFLICT DO NOTHING;

-- BIN 4: High fill bin (20-40cm = 60-80% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  30.0,
  11.770800,
  124.886300,
  'high'
) ON CONFLICT DO NOTHING;

-- BIN 5: Full bin (5-20cm = 80-95% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  10.0,
  11.771400,
  124.886200,
  'full'
) ON CONFLICT DO NOTHING;

-- BIN 6: Overflow bin (<5cm = 95-100% full)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  2.0,
  11.770900,
  124.886900,
  'overflow'
) ON CONFLICT DO NOTHING;

-- BIN 7: Additional empty bin (different location)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  90.0,
  11.771600,
  124.886400,
  'empty'
) ON CONFLICT DO NOTHING;

-- BIN 8: Additional medium bin (different location)
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  45.0,
  11.770700,
  124.886600,
  'medium'
) ON CONFLICT DO NOTHING;

-- =====================================================
-- VERIFY THE INSERT
-- =====================================================
-- Run this query to check if the bins were inserted
SELECT 
  id,
  distance_cm,
  latitude,
  longitude,
  status,
  created_at,
  -- Calculate fill percentage for verification
  ROUND((1.0 - (distance_cm / 100.0)) * 100, 1) as fill_percentage
FROM public.smart_bin
ORDER BY created_at DESC;

-- =====================================================
-- CLEAN UP (Optional)
-- =====================================================
-- If you want to delete all test data later, run:
-- DELETE FROM public.smart_bin WHERE id > 0;

-- =====================================================
-- UPDATE EXISTING BIN STATUS (Example)
-- =====================================================
-- To update a specific bin's status:
-- UPDATE public.smart_bin 
-- SET distance_cm = 15.0, status = 'full'
-- WHERE id = 1;

-- =====================================================
-- INSERT A SINGLE CUSTOM BIN
-- =====================================================
-- Use this template to add your own custom bin:
/*
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES (
  50.0,  -- Distance in cm (0-100)
  11.771098,  -- Your latitude
  124.886578,  -- Your longitude
  'medium'  -- Status: empty, low, medium, high, full, overflow
);
*/







