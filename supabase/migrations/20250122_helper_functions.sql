-- =====================================================
-- Helper Functions for EcoWaste Management System
-- =====================================================

-- =====================================================
-- USER MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create a new staff account
CREATE OR REPLACE FUNCTION create_staff_account(
  p_email TEXT,
  p_name TEXT,
  p_phone TEXT,
  p_department TEXT DEFAULT NULL,
  p_position TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Generate UUID for new user
  v_user_id := uuid_generate_v4();
  
  -- Insert into users table
  INSERT INTO users (
    id,
    email,
    name,
    phone_number,
    role,
    department,
    position,
    is_active
  )
  VALUES (
    v_user_id,
    p_email,
    p_name,
    p_phone,
    'staff',
    p_department,
    p_position,
    true
  );
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to deactivate/activate user
CREATE OR REPLACE FUNCTION toggle_user_status(
  p_user_id UUID,
  p_is_active BOOLEAN
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE users
  SET is_active = p_is_active,
      updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user profile
CREATE OR REPLACE FUNCTION update_user_profile(
  p_user_id UUID,
  p_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_department TEXT DEFAULT NULL,
  p_position TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_state TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE users
  SET 
    name = COALESCE(p_name, name),
    phone_number = COALESCE(p_phone, phone_number),
    department = COALESCE(p_department, department),
    position = COALESCE(p_position, position),
    address = COALESCE(p_address, address),
    city = COALESCE(p_city, city),
    state = COALESCE(p_state, state),
    updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete user (soft delete by deactivating)
CREATE OR REPLACE FUNCTION soft_delete_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE users
  SET is_active = false,
      updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRASHCAN MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to add a new trashcan
CREATE OR REPLACE FUNCTION add_trashcan(
  p_name TEXT,
  p_location TEXT,
  p_latitude DECIMAL,
  p_longitude DECIMAL,
  p_device_id TEXT DEFAULT NULL,
  p_sensor_type TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_trashcan_id UUID;
BEGIN
  INSERT INTO trashcans (
    name,
    location,
    latitude,
    longitude,
    device_id,
    sensor_type,
    status,
    fill_level,
    is_active
  )
  VALUES (
    p_name,
    p_location,
    p_latitude,
    p_longitude,
    p_device_id,
    p_sensor_type,
    'empty',
    0.0,
    true
  )
  RETURNING id INTO v_trashcan_id;
  
  RETURN v_trashcan_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update trashcan location
CREATE OR REPLACE FUNCTION update_trashcan_location(
  p_trashcan_id UUID,
  p_name TEXT DEFAULT NULL,
  p_location TEXT DEFAULT NULL,
  p_latitude DECIMAL DEFAULT NULL,
  p_longitude DECIMAL DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE trashcans
  SET 
    name = COALESCE(p_name, name),
    location = COALESCE(p_location, location),
    latitude = COALESCE(p_latitude, latitude),
    longitude = COALESCE(p_longitude, longitude),
    last_updated_at = NOW()
  WHERE id = p_trashcan_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update trashcan fill level
CREATE OR REPLACE FUNCTION update_trashcan_fill_level(
  p_trashcan_id UUID,
  p_fill_level DECIMAL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE trashcans
  SET 
    fill_level = p_fill_level,
    last_updated_at = NOW()
  WHERE id = p_trashcan_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark trashcan as emptied
CREATE OR REPLACE FUNCTION mark_trashcan_emptied(p_trashcan_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE trashcans
  SET 
    fill_level = 0.0,
    status = 'empty',
    last_emptied_at = NOW(),
    last_updated_at = NOW()
  WHERE id = p_trashcan_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete trashcan
CREATE OR REPLACE FUNCTION delete_trashcan(p_trashcan_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- First, cancel all pending tasks for this trashcan
  UPDATE tasks
  SET status = 'cancelled'
  WHERE trashcan_id = p_trashcan_id
    AND status IN ('pending', 'in_progress');
  
  -- Then delete the trashcan
  DELETE FROM trashcans
  WHERE id = p_trashcan_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TASK MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create a new task
CREATE OR REPLACE FUNCTION create_task(
  p_title TEXT,
  p_description TEXT,
  p_trashcan_id UUID,
  p_assigned_staff_id UUID,
  p_created_by_admin_id UUID,
  p_priority TEXT DEFAULT 'medium',
  p_due_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_task_id UUID;
  v_staff_name TEXT;
  v_trashcan_name TEXT;
BEGIN
  -- Get staff and trashcan names for notification
  SELECT name INTO v_staff_name FROM users WHERE id = p_assigned_staff_id;
  SELECT name INTO v_trashcan_name FROM trashcans WHERE id = p_trashcan_id;
  
  -- Insert task
  INSERT INTO tasks (
    title,
    description,
    trashcan_id,
    assigned_staff_id,
    created_by_admin_id,
    priority,
    status,
    due_date
  )
  VALUES (
    p_title,
    p_description,
    p_trashcan_id,
    p_assigned_staff_id,
    p_created_by_admin_id,
    p_priority,
    'pending',
    p_due_date
  )
  RETURNING id INTO v_task_id;
  
  -- Create notification for assigned staff
  INSERT INTO notifications (
    title,
    body,
    type,
    priority,
    user_id,
    task_id,
    trashcan_id
  )
  VALUES (
    '📋 New Task Assigned',
    'You have been assigned: ' || p_title,
    'task_assigned',
    p_priority,
    p_assigned_staff_id,
    v_task_id,
    p_trashcan_id
  );
  
  RETURN v_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update task status
CREATE OR REPLACE FUNCTION update_task_status(
  p_task_id UUID,
  p_status TEXT,
  p_completion_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_started_at TIMESTAMP WITH TIME ZONE;
  v_completed_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Set timestamps based on status
  IF p_status = 'in_progress' THEN
    v_started_at := NOW();
  ELSIF p_status = 'completed' THEN
    v_completed_at := NOW();
  END IF;
  
  UPDATE tasks
  SET 
    status = p_status,
    started_at = COALESCE(v_started_at, started_at),
    completed_at = COALESCE(v_completed_at, completed_at),
    completion_notes = COALESCE(p_completion_notes, completion_notes),
    updated_at = NOW()
  WHERE id = p_task_id;
  
  -- If task is completed, mark trashcan as emptied
  IF p_status = 'completed' THEN
    UPDATE trashcans
    SET 
      fill_level = 0.0,
      status = 'empty',
      last_emptied_at = NOW(),
      last_updated_at = NOW()
    WHERE id = (SELECT trashcan_id FROM tasks WHERE id = p_task_id);
  END IF;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reassign task
CREATE OR REPLACE FUNCTION reassign_task(
  p_task_id UUID,
  p_new_staff_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE tasks
  SET 
    assigned_staff_id = p_new_staff_id,
    updated_at = NOW()
  WHERE id = p_task_id;
  
  -- Create notification for newly assigned staff
  INSERT INTO notifications (
    title,
    body,
    type,
    priority,
    user_id,
    task_id
  )
  SELECT 
    '📋 Task Reassigned',
    'You have been assigned: ' || title,
    'task_assigned',
    priority,
    p_new_staff_id,
    id
  FROM tasks
  WHERE id = p_task_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE notifications
  SET 
    is_read = true,
    read_at = NOW()
  WHERE id = p_notification_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE notifications
  SET 
    is_read = true,
    read_at = NOW()
  WHERE user_id = p_user_id
    AND is_read = false;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications(p_days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL
    AND is_read = true;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- REPORTING FUNCTIONS
-- =====================================================

-- Function to get staff performance report
CREATE OR REPLACE FUNCTION get_staff_performance(
  p_staff_id UUID,
  p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_start_date TIMESTAMP WITH TIME ZONE;
  v_end_date TIMESTAMP WITH TIME ZONE;
  v_report JSON;
BEGIN
  v_start_date := COALESCE(p_start_date, NOW() - INTERVAL '30 days');
  v_end_date := COALESCE(p_end_date, NOW());
  
  SELECT json_build_object(
    'staff_id', p_staff_id,
    'period', json_build_object(
      'start', v_start_date,
      'end', v_end_date
    ),
    'tasks', json_build_object(
      'total', COUNT(*),
      'completed', COUNT(*) FILTER (WHERE status = 'completed'),
      'pending', COUNT(*) FILTER (WHERE status = 'pending'),
      'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
      'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
    ),
    'efficiency', (
      COUNT(*) FILTER (WHERE status = 'completed' AND completed_at <= due_date)::FLOAT /
      NULLIF(COUNT(*) FILTER (WHERE status = 'completed'), 0) * 100
    ),
    'avg_completion_time_hours', (
      AVG(EXTRACT(EPOCH FROM (completed_at - created_at)) / 3600)
      FILTER (WHERE status = 'completed')
    )
  ) INTO v_report
  FROM tasks
  WHERE assigned_staff_id = p_staff_id
    AND created_at BETWEEN v_start_date AND v_end_date;
  
  RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- Function to get trashcan utilization report
CREATE OR REPLACE FUNCTION get_trashcan_report(
  p_trashcan_id UUID DEFAULT NULL,
  p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_start_date TIMESTAMP WITH TIME ZONE;
  v_end_date TIMESTAMP WITH TIME ZONE;
  v_report JSON;
BEGIN
  v_start_date := COALESCE(p_start_date, NOW() - INTERVAL '30 days');
  v_end_date := COALESCE(p_end_date, NOW());
  
  SELECT json_agg(
    json_build_object(
      'trashcan_id', t.id,
      'name', t.name,
      'location', t.location,
      'current_status', t.status,
      'current_fill_level', t.fill_level,
      'tasks', (
        SELECT json_build_object(
          'total', COUNT(*),
          'completed', COUNT(*) FILTER (WHERE status = 'completed'),
          'avg_completion_time_hours', AVG(
            EXTRACT(EPOCH FROM (completed_at - created_at)) / 3600
          ) FILTER (WHERE status = 'completed')
        )
        FROM tasks
        WHERE trashcan_id = t.id
          AND created_at BETWEEN v_start_date AND v_end_date
      ),
      'last_emptied', t.last_emptied_at,
      'days_since_last_emptied', EXTRACT(
        DAY FROM (NOW() - t.last_emptied_at)
      )
    )
  ) INTO v_report
  FROM trashcans t
  WHERE (p_trashcan_id IS NULL OR t.id = p_trashcan_id)
    AND t.is_active = true;
  
  RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to schedule regular cleanup
CREATE OR REPLACE FUNCTION schedule_maintenance()
RETURNS VOID AS $$
BEGIN
  -- Clean up old read notifications (older than 30 days)
  PERFORM cleanup_old_notifications(30);
  
  -- Clean up old activity logs (older than 90 days)
  DELETE FROM activity_logs
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Update statistics
  ANALYZE users;
  ANALYZE trashcans;
  ANALYZE tasks;
  ANALYZE notifications;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANTS
-- =====================================================

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- END OF HELPER FUNCTIONS
-- =====================================================

