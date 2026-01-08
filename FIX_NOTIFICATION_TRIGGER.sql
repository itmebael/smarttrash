-- =====================================================
-- QUICK FIX: Update Notification Trigger
-- =====================================================
-- This fixes the error: "record 'new' has no field 'assigned_to'"
-- Run this in Supabase SQL Editor

-- Drop and recreate the notify_task_completed function
DROP FUNCTION IF EXISTS notify_task_completed() CASCADE;

CREATE OR REPLACE FUNCTION notify_task_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  trashcan_name TEXT;
  assigned_user_id UUID;
  assigned_time TIMESTAMP WITH TIME ZONE;
  completed_time TIMESTAMP WITH TIME ZONE;
  staff_name TEXT;
BEGIN
  -- Only trigger when status changes to completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Get assigned user ID (use assigned_staff_id only)
    assigned_user_id := NEW.assigned_staff_id;
    
    -- Get trashcan name if exists
    IF NEW.trashcan_id IS NOT NULL THEN
      SELECT name INTO trashcan_name FROM trashcans WHERE id = NEW.trashcan_id;
    END IF;
    
    -- Get staff name
    IF assigned_user_id IS NOT NULL THEN
      SELECT name INTO staff_name FROM users WHERE id = assigned_user_id;
    END IF;
    
    -- Get assignment time (when task was created)
    assigned_time := NEW.created_at;
    
    -- Get completion time
    completed_time := COALESCE(NEW.completed_at, NOW());
    
    -- Notify the assigned user
    IF assigned_user_id IS NOT NULL THEN
      INSERT INTO notifications (title, body, type, priority, task_id, user_id, trashcan_id, data)
      VALUES (
        '✅ Task Completed',
        COALESCE(trashcan_name, 'Task') || ': ' || NEW.title || ' has been completed.',
        'task_completed',
        'low',
        NEW.id,
        assigned_user_id,
        NEW.trashcan_id,
        jsonb_build_object(
          'task_title', NEW.title,
          'task_description', NEW.description,
          'assigned_at', assigned_time,
          'assigned_time', to_char(assigned_time, 'YYYY-MM-DD HH24:MI:SS'),
          'completed_at', completed_time,
          'completed_time', to_char(completed_time, 'YYYY-MM-DD HH24:MI:SS'),
          'completion_notes', NEW.completion_notes,
          'trashcan_name', trashcan_name,
          'staff_name', staff_name
        )
      );
    END IF;
    
    -- Notify admins
    INSERT INTO notifications (title, body, type, priority, task_id, trashcan_id, user_id, data)
    SELECT 
      '✅ Task Completed',
      COALESCE(trashcan_name, 'Task') || ': ' || NEW.title || ' has been completed by ' || COALESCE(staff_name, 'Staff'),
      'task_completed',
      'low',
      NEW.id,
      NEW.trashcan_id,
      u.id,
      jsonb_build_object(
        'task_title', NEW.title,
        'task_description', NEW.description,
        'assigned_at', assigned_time,
        'assigned_time', to_char(assigned_time, 'YYYY-MM-DD HH24:MI:SS'),
        'completed_at', completed_time,
        'completed_time', to_char(completed_time, 'YYYY-MM-DD HH24:MI:SS'),
        'completion_notes', NEW.completion_notes,
        'trashcan_name', trashcan_name,
        'staff_name', staff_name
      )
    FROM users u
    WHERE u.role = 'admin' AND u.id != assigned_user_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_notify_task_completed ON tasks;

CREATE TRIGGER trigger_notify_task_completed
  AFTER UPDATE OF status ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION notify_task_completed();

-- Verify the fix
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_name = 'notify_task_completed';






