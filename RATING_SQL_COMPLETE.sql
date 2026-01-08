-- =====================================================
-- COMPLETE RATING SYSTEM SQL
-- =====================================================
-- This file contains all SQL needed for the rating system
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. ADD RATING COLUMN TO USERS TABLE
-- =====================================================

-- Add rating column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5);

-- Add comment
COMMENT ON COLUMN users.rating IS 'Staff rating from 0.0 to 5.0, set by admin';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_rating ON users(rating);

-- Update existing users to have default rating of 0.0 if null
UPDATE users SET rating = 0.0 WHERE rating IS NULL;

-- =====================================================
-- 2. UPDATE RLS POLICIES FOR RATING
-- =====================================================

-- Allow admins to update ratings for staff members
DROP POLICY IF EXISTS "Admins can update staff ratings" ON users;
CREATE POLICY "Admins can update staff ratings"
  ON users FOR UPDATE
  TO authenticated
  USING (
    -- Admin can update ratings
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
    AND (
      -- Can only update rating field for staff members
      (SELECT role FROM users WHERE id = users.id) = 'staff'
    )
  )
  WITH CHECK (
    -- Ensure rating is between 0 and 5
    rating >= 0 AND rating <= 5
  );

-- Allow users to view ratings (their own and others)
-- This is already covered by existing "Admins can view all users" and "Users can view their own profile" policies

-- =====================================================
-- 3. CREATE FUNCTION TO UPDATE STAFF RATING
-- =====================================================

DROP FUNCTION IF EXISTS update_staff_rating(UUID, DECIMAL);

CREATE OR REPLACE FUNCTION update_staff_rating(
  p_staff_id UUID,
  p_rating DECIMAL(3,1)
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
  v_is_admin BOOLEAN;
  v_staff_role TEXT;
BEGIN
  -- Check if current user is admin
  SELECT role = 'admin' INTO v_is_admin
  FROM users
  WHERE id = auth.uid();
  
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can update staff ratings';
  END IF;
  
  -- Check if target user is staff
  SELECT role INTO v_staff_role
  FROM users
  WHERE id = p_staff_id;
  
  IF v_staff_role != 'staff' THEN
    RAISE EXCEPTION 'Can only rate staff members';
  END IF;
  
  -- Validate rating range
  IF p_rating < 0 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 0.0 and 5.0';
  END IF;
  
  -- Update rating
  UPDATE users
  SET rating = p_rating,
      updated_at = NOW()
  WHERE id = p_staff_id;
  
  -- Return success message
  SELECT json_build_object(
    'success', true,
    'message', 'Rating updated successfully',
    'staff_id', p_staff_id,
    'new_rating', p_rating
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_staff_rating(UUID, DECIMAL) TO authenticated;

-- Add comment
COMMENT ON FUNCTION update_staff_rating(UUID, DECIMAL) IS 'Allows admins to update staff member ratings';

-- =====================================================
-- 4. VERIFICATION QUERIES (Optional - for testing)
-- =====================================================

-- Check if rating column exists
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' AND column_name = 'rating';

-- Check ratings for all staff
-- SELECT id, name, email, role, rating 
-- FROM users 
-- WHERE role = 'staff' 
-- ORDER BY rating DESC;

-- Check if function exists
-- SELECT routine_name, routine_type 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_name = 'update_staff_rating';

-- =====================================================
-- 5. TASK COMPLETION REPORT SYSTEM
-- =====================================================

-- Function to extract floor number from location text
CREATE OR REPLACE FUNCTION extract_floor(location_text TEXT)
RETURNS TEXT AS $$
DECLARE
  floor_match TEXT[];
BEGIN
  -- Try to extract floor information from location text
  -- Pattern: "Building Name - Xst/nd/rd/th Floor" or "Building Name - Floor X"
  IF location_text IS NULL THEN
    RETURN 'Unknown';
  END IF;
  
  -- Pattern 1: "1st Floor", "2nd Floor", "3rd Floor", "4th Floor", etc.
  floor_match := regexp_match(location_text, '(\d+)(st|nd|rd|th)\s+floor', 'i');
  IF floor_match IS NOT NULL THEN
    RETURN floor_match[1] || floor_match[2] || ' Floor';
  END IF;
  
  -- Pattern 2: "Floor 1", "Floor 2", etc.
  floor_match := regexp_match(location_text, 'floor\s+(\d+)', 'i');
  IF floor_match IS NOT NULL THEN
    RETURN 'Floor ' || floor_match[1];
  END IF;
  
  -- Pattern 3: Any number followed by "floor" (e.g., "1 floor", "2 floor")
  floor_match := regexp_match(location_text, '(\d+).*floor', 'i');
  IF floor_match IS NOT NULL THEN
    RETURN floor_match[1] || ' Floor';
  END IF;
  
  -- Pattern 4: Return the part after the last dash if no floor pattern found
  IF location_text LIKE '% - %' THEN
    RETURN split_part(location_text, ' - ', -1);
  END IF;
  
  -- Default: return "Unknown"
  RETURN 'Unknown';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create view for task completion reports
CREATE OR REPLACE VIEW task_completion_report AS
SELECT 
  t.id AS task_id,
  t.title AS task_title,
  t.description,
  t.status,
  t.priority,
  
  -- Time information
  t.completed_at AS completion_time,
  TO_CHAR(t.completed_at, 'YYYY-MM-DD HH24:MI:SS') AS completion_time_formatted,
  TO_CHAR(t.completed_at, 'HH24:MI') AS completion_time_only,
  TO_CHAR(t.completed_at, 'YYYY-MM-DD') AS completion_date,
  
  -- Days since completion
  CASE 
    WHEN t.completed_at IS NOT NULL THEN
      EXTRACT(DAY FROM (NOW() - t.completed_at))::INTEGER
    ELSE NULL
  END AS days_since_completion,
  
  -- Floor information
  extract_floor(tc.location) AS floor,
  tc.location AS full_location,
  tc.name AS trashcan_name,
  
  -- Staff information (who got the bin)
  u.id AS staff_id,
  u.name AS staff_name,
  u.email AS staff_email,
  u.phone_number AS staff_phone,
  u.rating AS staff_rating,
  
  -- Task metadata
  t.created_at AS task_created_at,
  t.started_at AS task_started_at,
  t.due_date AS task_due_date,
  t.completion_notes,
  t.estimated_duration,
  
  -- Trashcan information
  tc.id AS trashcan_id,
  tc.status AS trashcan_status,
  tc.fill_level AS trashcan_fill_level
  
FROM tasks t
LEFT JOIN trashcans tc ON t.trashcan_id = tc.id
LEFT JOIN users u ON t.assigned_staff_id = u.id
WHERE t.status = 'completed'
ORDER BY t.completed_at DESC;

-- Grant access to the view
GRANT SELECT ON task_completion_report TO authenticated;

-- Add comment
COMMENT ON VIEW task_completion_report IS 'Comprehensive report of completed tasks showing time, days since completion, floor, and assigned staff';

-- =====================================================
-- 6. REPORT QUERIES
-- =====================================================

-- Query to get all completed tasks with report information
-- SELECT * FROM task_completion_report;

-- Query to get recent completions (last 30 days)
-- SELECT 
--   task_title,
--   completion_time_formatted,
--   days_since_completion,
--   floor,
--   staff_name,
--   trashcan_name
-- FROM task_completion_report
-- WHERE completion_time >= NOW() - INTERVAL '30 days'
-- ORDER BY completion_time DESC;

-- Query to get completions by staff member
-- SELECT 
--   staff_name,
--   COUNT(*) AS total_completions,
--   AVG(days_since_completion) AS avg_days_since_completion,
--   MAX(completion_time) AS last_completion
-- FROM task_completion_report
-- GROUP BY staff_name
-- ORDER BY total_completions DESC;

-- Query to get completions by floor
-- SELECT 
--   floor,
--   COUNT(*) AS total_completions,
--   COUNT(DISTINCT staff_id) AS unique_staff_count
-- FROM task_completion_report
-- GROUP BY floor
-- ORDER BY floor;

-- Query for daily report summary
-- SELECT 
--   completion_date,
--   COUNT(*) AS tasks_completed,
--   COUNT(DISTINCT staff_id) AS staff_count,
--   COUNT(DISTINCT floor) AS floors_covered
-- FROM task_completion_report
-- GROUP BY completion_date
-- ORDER BY completion_date DESC;

-- =====================================================
-- 7. OPTIONAL: ADD FLOOR COLUMN TO TRASHCANS TABLE
-- =====================================================

-- If you want to store floor as a separate column instead of extracting from location:
-- ALTER TABLE trashcans ADD COLUMN IF NOT EXISTS floor TEXT;
-- CREATE INDEX IF NOT EXISTS idx_trashcans_floor ON trashcans(floor);
-- COMMENT ON COLUMN trashcans.floor IS 'Floor number or description (e.g., "1st Floor", "2nd Floor", "Ground Floor")';

-- Then update the view to use the column instead of extracting:
-- Replace: extract_floor(tc.location) AS floor,
-- With: COALESCE(tc.floor, extract_floor(tc.location)) AS floor,

