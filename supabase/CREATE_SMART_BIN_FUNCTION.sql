-- ============================================
-- CREATE SMART BIN HELPER FUNCTION
-- ============================================

-- Function to get the latest status for each smart bin
CREATE OR REPLACE FUNCTION get_latest_smart_bin_status()
RETURNS TABLE (
  id INTEGER,
  distance_cm DOUBLE PRECISION,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE SQL
STABLE
AS $$
  SELECT DISTINCT ON (sb.id)
    sb.id,
    sb.distance_cm,
    sb.latitude,
    sb.longitude,
    sb.status,
    sb.created_at
  FROM smart_bin sb
  ORDER BY sb.id, sb.created_at DESC;
$$;

-- ============================================
-- INSERT TEST DATA (for demonstration)
-- ============================================

-- Insert test smart bin at SSU coordinates with different fill levels
INSERT INTO public.smart_bin (distance_cm, latitude, longitude, status)
VALUES
  -- Empty bin (80cm from sensor = 20% full)
  (80.0, 11.771098, 124.886579, 'empty'),
  
  -- Medium bin (50cm from sensor = 50% full)
  (50.0, 11.771500, 124.887000, 'medium'),
  
  -- Full bin (10cm from sensor = 90% full)
  (10.0, 11.770500, 124.886000, 'full'),
  
  -- Critical bin (3cm from sensor = 97% full)
  (3.0, 11.771800, 124.887500, 'overflow')
ON CONFLICT DO NOTHING;

-- ============================================
-- VERIFY DATA
-- ============================================

-- Check all smart bins
SELECT 
  id,
  distance_cm,
  CASE 
    WHEN distance_cm >= 80 THEN 'Empty (0-20%)'
    WHEN distance_cm >= 60 THEN 'Low (20-40%)'
    WHEN distance_cm >= 40 THEN 'Medium (40-60%)'
    WHEN distance_cm >= 20 THEN 'High (60-80%)'
    WHEN distance_cm >= 5 THEN 'Full (80-95%)'
    ELSE 'Overflow (95-100%)'
  END as calculated_status,
  latitude,
  longitude,
  status,
  created_at
FROM public.smart_bin
ORDER BY created_at DESC;

-- Get latest status using the function
SELECT * FROM get_latest_smart_bin_status();

-- Count bins by status
SELECT 
  CASE 
    WHEN distance_cm >= 80 THEN 'Empty'
    WHEN distance_cm >= 60 THEN 'Low'
    WHEN distance_cm >= 40 THEN 'Medium'
    WHEN distance_cm >= 20 THEN 'High'
    WHEN distance_cm >= 5 THEN 'Full'
    ELSE 'Overflow'
  END as status_category,
  COUNT(*) as count
FROM public.smart_bin
GROUP BY status_category
ORDER BY 
  CASE 
    WHEN distance_cm >= 80 THEN 1
    WHEN distance_cm >= 60 THEN 2
    WHEN distance_cm >= 40 THEN 3
    WHEN distance_cm >= 20 THEN 4
    WHEN distance_cm >= 5 THEN 5
    ELSE 6
  END;

-- ============================================
-- ENABLE REAL-TIME (for live updates)
-- ============================================

-- Enable real-time on smart_bin table
ALTER PUBLICATION supabase_realtime ADD TABLE smart_bin;

-- Verify real-time is enabled
SELECT 
  schemaname,
  tablename,
  pubname
FROM pg_publication_tables
WHERE tablename = 'smart_bin';












