-- =====================================================
-- TASK COMPLETION REPORT SETUP
-- =====================================================
-- Run this FIRST to create the view and function
-- Then you can query task_completion_report

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


