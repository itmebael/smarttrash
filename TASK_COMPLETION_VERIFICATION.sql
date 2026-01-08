-- =====================================================
-- TASK COMPLETION VERIFICATION SYSTEM
-- =====================================================
-- This system captures location verification when staff completes tasks
-- Includes map display, location capture, and photo evidence storage

-- =====================================================
-- 1. CREATE TASK COMPLETION VERIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS task_completion_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  trashcan_id UUID REFERENCES trashcans(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Location verification
  verified_latitude DECIMAL(10, 8) NOT NULL,
  verified_longitude DECIMAL(11, 8) NOT NULL,
  verified_accuracy DECIMAL(8, 2), -- Accuracy in meters
  verified_altitude DECIMAL(8, 2),
  verified_heading DECIMAL(5, 2), -- Direction in degrees
  
  -- Expected location (from trashcan)
  expected_latitude DECIMAL(10, 8) NOT NULL,
  expected_longitude DECIMAL(11, 8) NOT NULL,
  
  -- Distance calculation
  distance_from_trashcan DECIMAL(10, 2), -- Distance in meters
  is_within_range BOOLEAN DEFAULT false, -- True if within acceptable range (e.g., 50 meters)
  acceptable_range_meters INTEGER DEFAULT 50, -- Configurable range
  
  -- Photo evidence
  photo_url TEXT, -- URL to photo in storage bucket
  photo_path TEXT, -- Path in storage bucket
  
  -- Verification status
  verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN (
    'pending',
    'verified',
    'failed',
    'manual_override'
  )),
  verification_notes TEXT,
  
  -- Timestamps
  verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Additional metadata
  device_info JSONB, -- Device model, OS, etc.
  location_provider TEXT, -- GPS, network, etc.
  battery_level INTEGER, -- Device battery when verified
  network_type TEXT -- WiFi, 4G, 5G, etc.
);

-- =====================================================
-- 2. CREATE INDEXES for Performance
-- =====================================================

-- Index for task lookups
CREATE INDEX IF NOT EXISTS idx_verification_task_id ON task_completion_verifications(task_id);

-- Index for staff lookups
CREATE INDEX IF NOT EXISTS idx_verification_staff_id ON task_completion_verifications(staff_id);

-- Index for trashcan lookups
CREATE INDEX IF NOT EXISTS idx_verification_trashcan_id ON task_completion_verifications(trashcan_id);

-- Index for verification status
CREATE INDEX IF NOT EXISTS idx_verification_status ON task_completion_verifications(verification_status);

-- Index for date range queries
CREATE INDEX IF NOT EXISTS idx_verification_verified_at ON task_completion_verifications(verified_at DESC);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_verification_task_staff ON task_completion_verifications(task_id, staff_id);

-- Spatial index for location queries (if PostGIS is available)
-- CREATE INDEX IF NOT EXISTS idx_verification_location ON task_completion_verifications USING GIST (
--   ST_MakePoint(verified_longitude, verified_latitude)
-- );

-- =====================================================
-- 3. FUNCTIONS for Location Verification
-- =====================================================

-- Function to calculate distance between two coordinates (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance_meters(
  lat1 DECIMAL,
  lon1 DECIMAL,
  lat2 DECIMAL,
  lon2 DECIMAL
)
RETURNS DECIMAL
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  earth_radius DECIMAL := 6371000; -- Earth's radius in meters
  dlat DECIMAL;
  dlon DECIMAL;
  a DECIMAL;
  c DECIMAL;
BEGIN
  -- Convert degrees to radians
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  -- Haversine formula
  a := sin(dlat / 2) * sin(dlat / 2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dlon / 2) * sin(dlon / 2);
  c := 2 * atan2(sqrt(a), sqrt(1 - a));
  
  RETURN earth_radius * c;
END;
$$;

-- Function to verify task completion with location
CREATE OR REPLACE FUNCTION verify_task_completion(
  p_task_id UUID,
  p_staff_id UUID,
  p_verified_latitude DECIMAL,
  p_verified_longitude DECIMAL,
  p_verified_accuracy DECIMAL DEFAULT NULL,
  p_photo_url TEXT DEFAULT NULL,
  p_photo_path TEXT DEFAULT NULL,
  p_verification_notes TEXT DEFAULT NULL,
  p_device_info JSONB DEFAULT NULL,
  p_location_provider TEXT DEFAULT NULL,
  p_battery_level INTEGER DEFAULT NULL,
  p_network_type TEXT DEFAULT NULL,
  p_acceptable_range_meters INTEGER DEFAULT 50
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_trashcan_id UUID;
  v_expected_lat DECIMAL;
  v_expected_lng DECIMAL;
  v_distance DECIMAL;
  v_is_within_range BOOLEAN;
  v_verification_id UUID;
  v_task_status TEXT;
BEGIN
  -- Get task and trashcan information
  SELECT 
    t.trashcan_id,
    t.status,
    tc.latitude,
    tc.longitude
  INTO 
    v_trashcan_id,
    v_task_status,
    v_expected_lat,
    v_expected_lng
  FROM tasks t
  LEFT JOIN trashcans tc ON t.trashcan_id = tc.id
  WHERE t.id = p_task_id;
  
  -- Check if task exists
  IF v_task_status IS NULL THEN
    RAISE EXCEPTION 'Task not found: %', p_task_id;
  END IF;
  
  -- Check if task is in progress
  IF v_task_status != 'in_progress' THEN
    RAISE EXCEPTION 'Task must be in progress to complete. Current status: %', v_task_status;
  END IF;
  
  -- Calculate distance if trashcan location is available
  IF v_expected_lat IS NOT NULL AND v_expected_lng IS NOT NULL THEN
    v_distance := calculate_distance_meters(
      p_verified_latitude,
      p_verified_longitude,
      v_expected_lat,
      v_expected_lng
    );
    v_is_within_range := v_distance <= p_acceptable_range_meters;
  ELSE
    v_distance := NULL;
    v_is_within_range := true; -- Allow if no trashcan location
  END IF;
  
  -- Create verification record
  INSERT INTO task_completion_verifications (
    task_id,
    trashcan_id,
    staff_id,
    verified_latitude,
    verified_longitude,
    verified_accuracy,
    expected_latitude,
    expected_longitude,
    distance_from_trashcan,
    is_within_range,
    acceptable_range_meters,
    photo_url,
    photo_path,
    verification_status,
    verification_notes,
    device_info,
    location_provider,
    battery_level,
    network_type
  ) VALUES (
    p_task_id,
    v_trashcan_id,
    p_staff_id,
    p_verified_latitude,
    p_verified_longitude,
    p_verified_accuracy,
    COALESCE(v_expected_lat, p_verified_latitude),
    COALESCE(v_expected_lng, p_verified_longitude),
    v_distance,
    v_is_within_range,
    p_acceptable_range_meters,
    p_photo_url,
    p_photo_path,
    CASE 
      WHEN v_is_within_range THEN 'verified'
      ELSE 'failed'
    END,
    p_verification_notes,
    p_device_info,
    p_location_provider,
    p_battery_level,
    p_network_type
  )
  RETURNING id INTO v_verification_id;
  
  -- If within range, automatically complete the task
  IF v_is_within_range THEN
    UPDATE tasks
    SET 
      status = 'completed',
      completed_at = NOW(),
      updated_at = NOW()
    WHERE id = p_task_id;
    
    -- Update verification status
    UPDATE task_completion_verifications
    SET verification_status = 'verified'
    WHERE id = v_verification_id;
  END IF;
  
  RETURN v_verification_id;
END;
$$;

-- Function to manually override verification (for admins)
CREATE OR REPLACE FUNCTION override_verification(
  p_verification_id UUID,
  p_admin_id UUID,
  p_override_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_task_id UUID;
  v_is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM users 
    WHERE id = p_admin_id AND role = 'admin'
  ) INTO v_is_admin;
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can override verifications';
  END IF;
  
  -- Get task ID
  SELECT task_id INTO v_task_id
  FROM task_completion_verifications
  WHERE id = p_verification_id;
  
  IF v_task_id IS NULL THEN
    RAISE EXCEPTION 'Verification not found';
  END IF;
  
  -- Update verification
  UPDATE task_completion_verifications
  SET 
    verification_status = 'manual_override',
    verification_notes = COALESCE(verification_notes || E'\n', '') || 
      'Manual override by admin ' || p_admin_id || ': ' || p_override_reason
  WHERE id = p_verification_id;
  
  -- Complete the task
  UPDATE tasks
  SET 
    status = 'completed',
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = v_task_id;
  
  RETURN TRUE;
END;
$$;

-- Function to get verification details with task info
CREATE OR REPLACE FUNCTION get_verification_details(p_verification_id UUID)
RETURNS TABLE (
  verification_id UUID,
  task_id UUID,
  task_title TEXT,
  trashcan_name TEXT,
  trashcan_location TEXT,
  staff_name TEXT,
  verified_latitude DECIMAL,
  verified_longitude DECIMAL,
  expected_latitude DECIMAL,
  expected_longitude DECIMAL,
  distance_meters DECIMAL,
  is_within_range BOOLEAN,
  verification_status TEXT,
  verified_at TIMESTAMP WITH TIME ZONE,
  photo_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.id,
    v.task_id,
    t.title,
    tc.name,
    tc.location,
    u.name,
    v.verified_latitude,
    v.verified_longitude,
    v.expected_latitude,
    v.expected_longitude,
    v.distance_from_trashcan,
    v.is_within_range,
    v.verification_status,
    v.verified_at,
    v.photo_url
  FROM task_completion_verifications v
  JOIN tasks t ON v.task_id = t.id
  LEFT JOIN trashcans tc ON v.trashcan_id = tc.id
  JOIN users u ON v.staff_id = u.id
  WHERE v.id = p_verification_id;
END;
$$;

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE task_completion_verifications ENABLE ROW LEVEL SECURITY;

-- Policy: Staff can view their own verifications
CREATE POLICY "Staff can view own verifications"
  ON task_completion_verifications
  FOR SELECT
  USING (staff_id = auth.uid());

-- Policy: Staff can insert their own verifications
CREATE POLICY "Staff can create own verifications"
  ON task_completion_verifications
  FOR INSERT
  WITH CHECK (staff_id = auth.uid());

-- Policy: Admins can view all verifications
CREATE POLICY "Admins can view all verifications"
  ON task_completion_verifications
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policy: Admins can update verifications (for overrides)
CREATE POLICY "Admins can update verifications"
  ON task_completion_verifications
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- 5. VIEWS for Easy Querying
-- =====================================================

-- View: Verification details with all related information
CREATE OR REPLACE VIEW verification_details_view AS
SELECT 
  v.id as verification_id,
  v.task_id,
  t.title as task_title,
  t.status as task_status,
  v.trashcan_id,
  tc.name as trashcan_name,
  tc.location as trashcan_location,
  tc.latitude as trashcan_latitude,
  tc.longitude as trashcan_longitude,
  v.staff_id,
  u.name as staff_name,
  u.email as staff_email,
  v.verified_latitude,
  v.verified_longitude,
  v.expected_latitude,
  v.expected_longitude,
  v.distance_from_trashcan,
  v.is_within_range,
  v.acceptable_range_meters,
  v.verification_status,
  v.photo_url,
  v.photo_path,
  v.verification_notes,
  v.verified_at,
  v.created_at,
  v.device_info,
  v.location_provider,
  v.battery_level,
  v.network_type
FROM task_completion_verifications v
JOIN tasks t ON v.task_id = t.id
LEFT JOIN trashcans tc ON v.trashcan_id = tc.id
JOIN users u ON v.staff_id = u.id;

-- View: Failed verifications (for admin review)
CREATE OR REPLACE VIEW failed_verifications_view AS
SELECT *
FROM verification_details_view
WHERE verification_status = 'failed'
ORDER BY verified_at DESC;

-- =====================================================
-- 6. COMMENTS for Documentation
-- =====================================================

COMMENT ON TABLE task_completion_verifications IS 'Stores location verification data when staff complete tasks';
COMMENT ON COLUMN task_completion_verifications.distance_from_trashcan IS 'Distance in meters from expected trashcan location';
COMMENT ON COLUMN task_completion_verifications.is_within_range IS 'True if staff is within acceptable range of trashcan';
COMMENT ON COLUMN task_completion_verifications.acceptable_range_meters IS 'Configurable acceptable distance in meters (default: 50m)';
COMMENT ON COLUMN task_completion_verifications.verification_status IS 'Status: pending, verified, failed, manual_override';
COMMENT ON COLUMN task_completion_verifications.photo_url IS 'URL to photo evidence in storage bucket';

-- =====================================================
-- 7. SAMPLE QUERIES
-- =====================================================

-- Get all verifications for a task
-- SELECT * FROM verification_details_view WHERE task_id = 'task-uuid-here';

-- Get failed verifications that need admin review
-- SELECT * FROM failed_verifications_view;

-- Get verification statistics
-- SELECT 
--   verification_status,
--   COUNT(*) as count,
--   AVG(distance_from_trashcan) as avg_distance
-- FROM task_completion_verifications
-- GROUP BY verification_status;






