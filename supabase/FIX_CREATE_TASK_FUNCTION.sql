-- Fix create_task function to handle NULL values properly
-- This ensures tasks can be created even when trashcan_id is NULL
-- The original function failed when trashcan_id was NULL because it tried to SELECT from trashcans

-- Drop the existing function first (with all possible parameter signatures)
DROP FUNCTION IF EXISTS create_task(TEXT, TEXT, UUID, UUID, UUID, TEXT, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS create_task(TEXT, TEXT, UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_task(TEXT, TEXT, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS create_task;

-- Create the new function with correct parameter order
CREATE OR REPLACE FUNCTION create_task(
  p_title TEXT,
  p_description TEXT,
  p_assigned_staff_id UUID,
  p_created_by_admin_id UUID,
  p_trashcan_id UUID DEFAULT NULL,
  p_priority TEXT DEFAULT 'medium',
  p_due_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_task_id UUID;
BEGIN
  -- Validate required fields
  IF p_title IS NULL OR p_title = '' THEN
    RAISE EXCEPTION 'Task title is required';
  END IF;
  
  IF p_assigned_staff_id IS NULL THEN
    RAISE EXCEPTION 'Assigned staff ID is required';
  END IF;
  
  IF p_created_by_admin_id IS NULL THEN
    RAISE EXCEPTION 'Created by admin ID is required';
  END IF;
  
  -- Insert task (trashcan_id can be NULL)
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
    p_trashcan_id,  -- Can be NULL
    p_assigned_staff_id,
    p_created_by_admin_id,
    COALESCE(p_priority, 'medium'),
    'pending',
    p_due_date
  )
  RETURNING id INTO v_task_id;
  
  -- Create notification for assigned staff
  -- Only insert notification if we have a valid task_id
  IF v_task_id IS NOT NULL THEN
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
      COALESCE(p_priority, 'medium'),
      p_assigned_staff_id,
      v_task_id,
      p_trashcan_id  -- Can be NULL
    );
  END IF;
  
  RETURN v_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_task TO authenticated;

-- Add comment
COMMENT ON FUNCTION create_task IS 'Creates a new task and notification. Handles NULL trashcan_id properly.';

