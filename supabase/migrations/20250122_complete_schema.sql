-- =====================================================
-- EcoWaste Management System - Complete Database Schema
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
  profile_image_url TEXT,
  fcm_token TEXT,
  
  -- Additional user details
  age INTEGER,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  department TEXT,
  position TEXT,
  date_of_birth DATE,
  emergency_contact TEXT,
  emergency_phone TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- =====================================================
-- 2. TRASHCANS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS trashcans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  
  -- Coordinates
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  -- Status and fill level
  status TEXT NOT NULL DEFAULT 'empty' CHECK (status IN ('empty', 'half', 'full', 'maintenance')),
  fill_level DECIMAL(3, 2) DEFAULT 0.0 CHECK (fill_level >= 0 AND fill_level <= 1),
  
  -- Hardware information
  device_id TEXT UNIQUE,
  sensor_type TEXT,
  battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
  
  -- Timestamps
  last_emptied_at TIMESTAMP WITH TIME ZONE,
  last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Metadata
  notes TEXT,
  is_active BOOLEAN DEFAULT true
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_trashcans_status ON trashcans(status);
CREATE INDEX IF NOT EXISTS idx_trashcans_location ON trashcans USING GIST (
  point(longitude, latitude)
);
CREATE INDEX IF NOT EXISTS idx_trashcans_device_id ON trashcans(device_id);

-- =====================================================
-- 3. TASKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  
  -- Relationships
  trashcan_id UUID REFERENCES trashcans(id) ON DELETE CASCADE,
  assigned_staff_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Status and priority
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  due_date TIMESTAMP WITH TIME ZONE,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional info
  completion_notes TEXT,
  estimated_duration INTEGER -- in minutes
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_staff ON tasks(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_tasks_trashcan ON tasks(trashcan_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);

-- =====================================================
-- 4. NOTIFICATIONS TABLE
-- =====================================================
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
  
  -- Relationships (nullable for system-wide notifications)
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trashcan_id UUID REFERENCES trashcans(id) ON DELETE CASCADE,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional data (JSON for flexibility)
  data JSONB,
  image_url TEXT
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- 5. ACTIVITY LOG TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL, -- 'user', 'trashcan', 'task', 'notification'
  entity_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- =====================================================
-- 6. SYSTEM SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES users(id)
);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to auto-update trashcan status based on fill level
CREATE OR REPLACE FUNCTION update_trashcan_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.fill_level >= 0.8 THEN
    NEW.status = 'full';
  ELSIF NEW.fill_level >= 0.4 THEN
    NEW.status = 'half';
  ELSIF NEW.fill_level < 0.4 THEN
    NEW.status = 'empty';
  END IF;
  
  NEW.last_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_update_trashcan_status
  BEFORE UPDATE OF fill_level ON trashcans
  FOR EACH ROW
  WHEN (OLD.fill_level IS DISTINCT FROM NEW.fill_level)
  EXECUTE FUNCTION update_trashcan_status();

-- Function to create notification when trashcan is full
CREATE OR REPLACE FUNCTION notify_full_trashcan()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'full' AND (OLD.status IS NULL OR OLD.status != 'full') THEN
    INSERT INTO notifications (title, body, type, priority, trashcan_id)
    VALUES (
      '🚨 Trashcan Full',
      NEW.name || ' at ' || NEW.location || ' needs immediate attention',
      'trashcan_full',
      'urgent',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_on_full_trashcan
  AFTER INSERT OR UPDATE OF status ON trashcans
  FOR EACH ROW
  EXECUTE FUNCTION notify_full_trashcan();

-- Function to log user activity
CREATE OR REPLACE FUNCTION log_user_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    jsonb_build_object(
      'old', to_jsonb(OLD),
      'new', to_jsonb(NEW)
    )
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE trashcans ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert users"
  ON users FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update users"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Trashcans table policies
CREATE POLICY "Anyone authenticated can view trashcans"
  ON trashcans FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can insert trashcans"
  ON trashcans FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update trashcans"
  ON trashcans FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Staff can update trashcan status"
  ON trashcans FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role IN ('admin', 'staff')
    )
  );

CREATE POLICY "Admins can delete trashcans"
  ON trashcans FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Tasks table policies
CREATE POLICY "Anyone authenticated can view tasks"
  ON tasks FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Staff can view their assigned tasks"
  ON tasks FOR SELECT
  USING (assigned_staff_id = auth.uid());

CREATE POLICY "Admins can insert tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update tasks"
  ON tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Staff can update their assigned tasks"
  ON tasks FOR UPDATE
  USING (assigned_staff_id = auth.uid());

CREATE POLICY "Admins can delete tasks"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Notifications table policies
CREATE POLICY "Users can view their notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can update their notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- Activity logs policies
CREATE POLICY "Admins can view all activity logs"
  ON activity_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- System settings policies
CREATE POLICY "Authenticated users can view settings"
  ON system_settings FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can manage settings"
  ON system_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Note: Admin account must be created through Supabase Dashboard or API
-- See instructions below on how to create the admin account

-- Insert default system settings
INSERT INTO system_settings (key, value, description)
VALUES
  ('alert_threshold', '80', 'Trashcan fill level alert percentage'),
  ('auto_backup_enabled', 'true', 'Enable automatic system backups'),
  ('backup_frequency_days', '7', 'Backup frequency in days'),
  ('session_timeout_minutes', '30', 'Session timeout duration'),
  ('max_login_attempts', '5', 'Maximum failed login attempts'),
  ('notification_enabled', 'true', 'Enable push notifications'),
  ('email_alerts_enabled', 'true', 'Enable email notifications'),
  ('sms_alerts_enabled', 'false', 'Enable SMS notifications')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'tasks_completed', (
      SELECT COUNT(*) FROM tasks
      WHERE assigned_staff_id = user_uuid AND status = 'completed'
    ),
    'tasks_pending', (
      SELECT COUNT(*) FROM tasks
      WHERE assigned_staff_id = user_uuid AND status = 'pending'
    ),
    'tasks_in_progress', (
      SELECT COUNT(*) FROM tasks
      WHERE assigned_staff_id = user_uuid AND status = 'in_progress'
    )
  ) INTO stats;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql;

-- Function to get trashcan statistics
CREATE OR REPLACE FUNCTION get_trashcan_stats()
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total', COUNT(*),
    'empty', COUNT(*) FILTER (WHERE status = 'empty'),
    'half', COUNT(*) FILTER (WHERE status = 'half'),
    'full', COUNT(*) FILTER (WHERE status = 'full'),
    'maintenance', COUNT(*) FILTER (WHERE status = 'maintenance'),
    'active', COUNT(*) FILTER (WHERE is_active = true)
  ) INTO stats
  FROM trashcans;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql;

-- Function to get dashboard statistics for admin
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'trashcans', get_trashcan_stats(),
    'users', (
      SELECT json_build_object(
        'total', COUNT(*),
        'active', COUNT(*) FILTER (WHERE is_active = true),
        'admins', COUNT(*) FILTER (WHERE role = 'admin'),
        'staff', COUNT(*) FILTER (WHERE role = 'staff')
      )
      FROM users
    ),
    'tasks', (
      SELECT json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
        'completed', COUNT(*) FILTER (WHERE status = 'completed'),
        'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
      )
      FROM tasks
    ),
    'notifications', (
      SELECT json_build_object(
        'total', COUNT(*),
        'unread', COUNT(*) FILTER (WHERE is_read = false)
      )
      FROM notifications
    )
  ) INTO stats;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant access to tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Grant access to sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE users IS 'User accounts for admin and staff members';
COMMENT ON TABLE trashcans IS 'Smart trashcan devices and their current status';
COMMENT ON TABLE tasks IS 'Work tasks assigned to staff members';
COMMENT ON TABLE notifications IS 'System notifications for users';
COMMENT ON TABLE activity_logs IS 'Audit log of all user activities';
COMMENT ON TABLE system_settings IS 'Application-wide configuration settings';

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Database schema created successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '1. Create admin account in Supabase Dashboard';
  RAISE NOTICE '2. Go to Authentication → Users → Add User';
  RAISE NOTICE '3. Email: admin@ssu.edu.ph';
  RAISE NOTICE '4. Password: admin123 (change this later!)';
  RAISE NOTICE '5. Then insert user record (see instructions)';
  RAISE NOTICE '==============================================';
END $$;

