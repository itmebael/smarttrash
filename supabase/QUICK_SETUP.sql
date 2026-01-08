-- =====================================================
-- QUICK SETUP - Run this entire file to set up your database
-- Copy and paste this ENTIRE file into Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CREATE USERS TABLE
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

-- =====================================================
-- 2. CREATE TRASHCANS TABLE
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

-- =====================================================
-- 3. CREATE SMART BIN TABLE (Real-time Sensor Data)
-- =====================================================
CREATE TABLE IF NOT EXISTS smart_bin (
  id SERIAL PRIMARY KEY,
  distance_cm DOUBLE PRECISION NOT NULL,
  latitude DOUBLE PRECISION NULL,
  longitude DOUBLE PRECISION NULL,
  status TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_smart_bin_created_at ON smart_bin USING BTREE (created_at);

-- =====================================================
-- 4. CREATE TASKS TABLE
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
  estimated_duration INTEGER
);

-- =====================================================
-- 5. CREATE NOTIFICATIONS TABLE
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
-- 6. CREATE ACTIVITY LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 7. CREATE SYSTEM SETTINGS TABLE
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
-- 8. CREATE INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_trashcans_status ON trashcans(status);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_staff ON tasks(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- =====================================================
-- 9. ENABLE ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE trashcans ENABLE ROW LEVEL SECURITY;
ALTER TABLE smart_bin ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 10. CREATE RLS POLICIES
-- =====================================================

-- Users policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can insert users" ON users;
CREATE POLICY "Admins can insert users"
  ON users FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Trashcans policies
DROP POLICY IF EXISTS "Anyone authenticated can view trashcans" ON trashcans;
CREATE POLICY "Anyone authenticated can view trashcans"
  ON trashcans FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can manage trashcans" ON trashcans;
CREATE POLICY "Admins can manage trashcans"
  ON trashcans FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Tasks policies
DROP POLICY IF EXISTS "Users can view tasks" ON tasks;
CREATE POLICY "Users can view tasks"
  ON tasks FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can manage tasks" ON tasks;
CREATE POLICY "Admins can manage tasks"
  ON tasks FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Notifications policies
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid() OR user_id IS NULL);

DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- System settings policies
DROP POLICY IF EXISTS "Authenticated users can view settings" ON system_settings;
CREATE POLICY "Authenticated users can view settings"
  ON system_settings FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Smart bin policies (public read for sensor data)
DROP POLICY IF EXISTS "Anyone authenticated can view smart_bin" ON smart_bin;
CREATE POLICY "Anyone authenticated can view smart_bin"
  ON smart_bin FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Service role can insert smart_bin data" ON smart_bin;
CREATE POLICY "Service role can insert smart_bin data"
  ON smart_bin FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can manage smart_bin" ON smart_bin;
CREATE POLICY "Admins can manage smart_bin"
  ON smart_bin FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- 11. INSERT DEFAULT SETTINGS
-- =====================================================
INSERT INTO system_settings (key, value, description)
VALUES
  ('alert_threshold', '80', 'Trashcan fill level alert percentage'),
  ('notification_enabled', 'true', 'Enable push notifications')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- SUCCESS!
-- =====================================================
-- =====================================================
-- 12. CREATE FUNCTION TO SYNC SMART BIN TO TRASHCANS
-- =====================================================
CREATE OR REPLACE FUNCTION sync_smart_bin_to_trashcan()
RETURNS TRIGGER AS $$
DECLARE
  bin_fill_level DECIMAL(3, 2);
  bin_status TEXT;
BEGIN
  -- Calculate fill level from distance (assumes 100cm max depth)
  -- Closer distance = fuller bin
  bin_fill_level := GREATEST(0, LEAST(1, (100 - NEW.distance_cm) / 100));
  
  -- Determine status from fill level
  IF bin_fill_level >= 0.8 THEN
    bin_status := 'full';
  ELSIF bin_fill_level >= 0.4 THEN
    bin_status := 'half';
  ELSE
    bin_status := 'empty';
  END IF;
  
  -- Update or insert into trashcans table
  INSERT INTO trashcans (
    name,
    location,
    latitude,
    longitude,
    status,
    fill_level,
    last_updated_at
  )
  VALUES (
    'Smart Bin #' || NEW.id,
    'SSU Campus',
    COALESCE(NEW.latitude, 11.7711),
    COALESCE(NEW.longitude, 124.8866),
    bin_status,
    bin_fill_level,
    NEW.created_at
  )
  ON CONFLICT (device_id) 
  DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    status = EXCLUDED.status,
    fill_level = EXCLUDED.fill_level,
    last_updated_at = EXCLUDED.last_updated_at;
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-sync smart_bin data to trashcans
DROP TRIGGER IF EXISTS trigger_sync_smart_bin ON smart_bin;
CREATE TRIGGER trigger_sync_smart_bin
  AFTER INSERT ON smart_bin
  FOR EACH ROW
  EXECUTE FUNCTION sync_smart_bin_to_trashcan();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ Database setup completed successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Tables created:';
  RAISE NOTICE '  ✅ users';
  RAISE NOTICE '  ✅ trashcans';
  RAISE NOTICE '  ✅ smart_bin (real-time sensor data)';
  RAISE NOTICE '  ✅ tasks';
  RAISE NOTICE '  ✅ notifications';
  RAISE NOTICE '  ✅ activity_logs';
  RAISE NOTICE '  ✅ system_settings';
  RAISE NOTICE '';
  RAISE NOTICE 'Features enabled:';
  RAISE NOTICE '  ✅ Auto-sync smart_bin → trashcans';
  RAISE NOTICE '  ✅ Auto calculate fill level from distance';
  RAISE NOTICE '  ✅ Auto update bin status';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Step: Create admin account';
  RAISE NOTICE '1. Go to Authentication → Users → Add User';
  RAISE NOTICE '2. Email: admin@ssu.edu.ph';
  RAISE NOTICE '3. Password: admin123';
  RAISE NOTICE '4. Check "Auto Confirm User"';
  RAISE NOTICE '5. Copy the User UUID';
  RAISE NOTICE '6. Run: INSERT INTO users (id, email, name, role, is_active)';
  RAISE NOTICE '   VALUES (''YOUR_UUID'', ''admin@ssu.edu.ph'', ''Admin'', ''admin'', true);';
  RAISE NOTICE '==============================================';
END $$;

