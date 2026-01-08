-- =====================================================
-- GET WORK STATISTICS FUNCTION
-- =====================================================
-- This function fetches work statistics for a user
-- Returns: tasks completed, hours worked, efficiency rate, and rating
-- Run this in Supabase SQL Editor

-- Drop function if exists
DROP FUNCTION IF EXISTS get_work_statistics(UUID);

-- Create function to get work statistics
CREATE OR REPLACE FUNCTION get_work_statistics(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_stats JSON;
  v_tasks_completed INTEGER;
  v_hours_worked DECIMAL(10, 2);
  v_efficiency_rate DECIMAL(5, 2);
  v_rating DECIMAL(3, 1);
  v_on_time_tasks INTEGER;
  v_total_completed INTEGER;
BEGIN
  -- Get tasks completed count
  SELECT COUNT(*)
  INTO v_tasks_completed
  FROM tasks
  WHERE assigned_staff_id = p_user_id
    AND status = 'completed';
  
  -- Calculate hours worked from task timestamps
  SELECT COALESCE(
    SUM(
      CASE 
        WHEN started_at IS NOT NULL AND completed_at IS NOT NULL THEN
          EXTRACT(EPOCH FROM (completed_at - started_at)) / 3600.0
        WHEN estimated_duration IS NOT NULL THEN
          estimated_duration / 60.0  -- Convert minutes to hours
        ELSE 0
      END
    ),
    0
  )
  INTO v_hours_worked
  FROM tasks
  WHERE assigned_staff_id = p_user_id
    AND status = 'completed';
  
  -- Calculate efficiency rate (tasks completed on time / total completed)
  SELECT 
    COUNT(*) FILTER (WHERE completed_at <= due_date OR (due_date IS NULL AND completed_at IS NOT NULL)),
    COUNT(*)
  INTO v_on_time_tasks, v_total_completed
  FROM tasks
  WHERE assigned_staff_id = p_user_id
    AND status = 'completed';
  
  IF v_total_completed > 0 THEN
    v_efficiency_rate := (v_on_time_tasks::DECIMAL / v_total_completed::DECIMAL) * 100.0;
  ELSE
    v_efficiency_rate := 0.0;
  END IF;
  
  -- Get rating from users table
  SELECT COALESCE(rating, 0.0)
  INTO v_rating
  FROM users
  WHERE id = p_user_id;
  
  -- Build JSON response
  SELECT json_build_object(
    'tasks_completed', v_tasks_completed,
    'hours_worked', ROUND(v_hours_worked, 1),
    'efficiency_rate', ROUND(v_efficiency_rate, 1),
    'rating', v_rating
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_work_statistics(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_work_statistics(UUID) IS 'Returns work statistics for a user including tasks completed, hours worked, efficiency rate, and rating';






