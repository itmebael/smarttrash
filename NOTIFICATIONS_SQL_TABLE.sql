-- =====================================================
-- NOTIFICATIONS TABLE - Complete SQL Schema
-- =====================================================

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  
  -- Type and priority
  type TEXT NOT NULL CHECK (type IN (
    'trashcan_full',
    'task_assigned',
    'task_completed',
    'task_reminder',
    'maintenance_required',
    'system_alert'
  )),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Relationships
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trashcan_id UUID REFERENCES trashcans(id) ON DELETE CASCADE,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional data
  data JSONB,
  image_url TEXT
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Index for user notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- Index for unread notifications
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read) WHERE is_read = false;

-- Index for created_at (for sorting)
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Index for type filtering
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- Index for priority filtering
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(priority);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);

-- =====================================================
-- FUNCTIONS for Notification Management
-- =====================================================

-- Drop existing functions if they exist (to allow recreation)
-- Using CASCADE to drop dependencies (triggers) as well
DROP FUNCTION IF EXISTS mark_notification_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS mark_all_notifications_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_unread_notification_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS create_notification(TEXT, TEXT, TEXT, TEXT, UUID, UUID, UUID, JSONB, TEXT) CASCADE;
DROP FUNCTION IF EXISTS notify_trashcan_full() CASCADE;
DROP FUNCTION IF EXISTS notify_task_assigned() CASCADE;
DROP FUNCTION IF EXISTS notify_task_completed() CASCADE;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE notifications
  SET is_read = true,
      read_at = NOW()
  WHERE id = p_notification_id
    AND (user_id = auth.uid() OR user_id IS NULL);
END;
$$;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE notifications
  SET is_read = true,
      read_at = NOW()
  WHERE user_id = p_user_id
    AND is_read = false;
END;
$$;

-- Function to get unread count for a user
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO unread_count
  FROM notifications
  WHERE (user_id = p_user_id OR user_id IS NULL)
    AND is_read = false;
  
  RETURN unread_count;
END;
$$;

-- Function to create notification (for use in triggers)
CREATE OR REPLACE FUNCTION create_notification(
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_priority TEXT DEFAULT 'medium',
  p_user_id UUID DEFAULT NULL,
  p_trashcan_id UUID DEFAULT NULL,
  p_task_id UUID DEFAULT NULL,
  p_data JSONB DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (
    title,
    body,
    type,
    priority,
    user_id,
    trashcan_id,
    task_id,
    data,
    image_url
  ) VALUES (
    p_title,
    p_body,
    p_type,
    p_priority,
    p_user_id,
    p_trashcan_id,
    p_task_id,
    p_data,
    p_image_url
  )
  RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$;

-- =====================================================
-- TRIGGERS for Automatic Notifications
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_notify_trashcan_full ON trashcans;
DROP TRIGGER IF EXISTS trigger_notify_task_assigned ON tasks;
DROP TRIGGER IF EXISTS trigger_notify_task_completed ON tasks;

-- Trigger: Create notification when trashcan is full
CREATE OR REPLACE FUNCTION notify_trashcan_full()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.fill_level >= 0.9 AND (OLD.fill_level IS NULL OR OLD.fill_level < 0.9) THEN
    -- Notify all admins
    INSERT INTO notifications (title, body, type, priority, trashcan_id, user_id)
    SELECT 
      '🚨 Trashcan Full Alert',
      NEW.name || ' at ' || NEW.location || ' is full and needs immediate attention.',
      'trashcan_full',
      'urgent',
      NEW.id,
      u.id
    FROM users u
    WHERE u.role = 'admin';
    
    -- Also create a global notification
    INSERT INTO notifications (title, body, type, priority, trashcan_id)
    VALUES (
      '🚨 Trashcan Full Alert',
      NEW.name || ' at ' || NEW.location || ' is full and needs immediate attention.',
      'trashcan_full',
      'urgent',
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_trashcan_full
  AFTER UPDATE OF fill_level ON trashcans
  FOR EACH ROW
  EXECUTE FUNCTION notify_trashcan_full();

-- Trigger: Create notification when task is assigned
CREATE OR REPLACE FUNCTION notify_task_assigned()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  assigned_user_id UUID;
  trashcan_name TEXT;
  assigned_time TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get assigned user ID
  assigned_user_id := NEW.assigned_staff_id;
  
  -- Get trashcan name if exists
  IF NEW.trashcan_id IS NOT NULL THEN
    SELECT name INTO trashcan_name FROM trashcans WHERE id = NEW.trashcan_id;
  END IF;
  
  -- Get assignment time (when task was created/assigned)
  assigned_time := NEW.created_at;
  
  -- Create notification for assigned user
  IF assigned_user_id IS NOT NULL THEN
    INSERT INTO notifications (title, body, type, priority, task_id, user_id, trashcan_id, data)
    VALUES (
      '📋 New Task Assigned',
      COALESCE(trashcan_name, 'A task') || ': ' || NEW.title,
      'task_assigned',
      CASE 
        WHEN NEW.priority = 'urgent' THEN 'urgent'
        WHEN NEW.priority = 'high' THEN 'high'
        ELSE 'medium'
      END,
      NEW.id,
      assigned_user_id,
      NEW.trashcan_id,
      jsonb_build_object(
        'task_title', NEW.title,
        'task_description', NEW.description,
        'assigned_at', assigned_time,
        'assigned_time', to_char(assigned_time, 'YYYY-MM-DD HH24:MI:SS'),
        'due_date', NEW.due_date,
        'priority', NEW.priority,
        'trashcan_name', trashcan_name
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_task_assigned
  AFTER INSERT ON tasks
  FOR EACH ROW
  WHEN (NEW.assigned_staff_id IS NOT NULL)
  EXECUTE FUNCTION notify_task_assigned();

-- Trigger: Create notification when task is completed
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
    -- Get assigned user ID
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

CREATE TRIGGER trigger_notify_task_completed
  AFTER UPDATE OF status ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION notify_task_completed();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own notifications or global notifications
CREATE POLICY "Users can view own notifications"
  ON notifications
  FOR SELECT
  USING (
    user_id = auth.uid() 
    OR user_id IS NULL
  );

-- Policy: Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  USING (user_id = auth.uid() OR user_id IS NULL)
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- Policy: Only admins and system can insert notifications
CREATE POLICY "Admins can insert notifications"
  ON notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'staff')
    )
    OR user_id IS NULL
  );

-- Policy: Only admins can delete notifications
CREATE POLICY "Admins can delete notifications"
  ON notifications
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample notifications
/*
INSERT INTO notifications (title, body, type, priority, user_id) VALUES
('Welcome!', 'Welcome to Smart Trashcan Management System', 'system_alert', 'low', NULL),
('System Update', 'The system has been updated with new features', 'system_alert', 'medium', NULL);
*/

-- =====================================================
-- VIEWS for Easy Querying
-- =====================================================

-- View: Unread notifications for current user
CREATE OR REPLACE VIEW user_unread_notifications AS
SELECT 
  n.*,
  t.name as trashcan_name,
  t.location as trashcan_location,
  task.title as task_title
FROM notifications n
LEFT JOIN trashcans t ON n.trashcan_id = t.id
LEFT JOIN tasks task ON n.task_id = task.id
WHERE (n.user_id = auth.uid() OR n.user_id IS NULL)
  AND n.is_read = false
ORDER BY n.created_at DESC;

-- View: All notifications for current user
CREATE OR REPLACE VIEW user_all_notifications AS
SELECT 
  n.*,
  t.name as trashcan_name,
  t.location as trashcan_location,
  task.title as task_title
FROM notifications n
LEFT JOIN trashcans t ON n.trashcan_id = t.id
LEFT JOIN tasks task ON n.task_id = task.id
WHERE (n.user_id = auth.uid() OR n.user_id IS NULL)
ORDER BY n.created_at DESC;

-- =====================================================
-- COMMENTS for Documentation
-- =====================================================

COMMENT ON TABLE notifications IS 'Stores all system notifications for users';
COMMENT ON COLUMN notifications.type IS 'Type of notification: trashcan_full, task_assigned, task_completed, task_reminder, maintenance_required, system_alert';
COMMENT ON COLUMN notifications.priority IS 'Priority level: low, medium, high, urgent';
COMMENT ON COLUMN notifications.user_id IS 'User ID - NULL means global notification for all users';
COMMENT ON COLUMN notifications.data IS 'Additional JSON data for the notification';
COMMENT ON COLUMN notifications.image_url IS 'Optional image URL for the notification';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check table exists
-- SELECT table_name FROM information_schema.tables WHERE table_name = 'notifications';

-- Check indexes
-- SELECT indexname FROM pg_indexes WHERE tablename = 'notifications';

-- Check functions
-- SELECT routine_name FROM information_schema.routines WHERE routine_name LIKE '%notification%';

-- Check triggers
-- SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = 'notifications';

-- Check RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'notifications';

