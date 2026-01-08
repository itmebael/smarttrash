-- Insert 5 trash bins with different statuses
-- Statuses: full, half (medium), empty, offline, and another half

-- Step 1: Enable UUID extension (needed for trashcans table)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Create trashcans table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.trashcans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  
  -- Coordinates
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  -- Status and fill level
  status TEXT NOT NULL DEFAULT 'empty' CHECK (status IN ('empty', 'half', 'full', 'maintenance', 'offline')),
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

-- Create indexes for trashcans
CREATE INDEX IF NOT EXISTS idx_trashcans_status ON trashcans(status);
CREATE INDEX IF NOT EXISTS idx_trashcans_device_id ON trashcans(device_id);

-- Insert 5 trash bins with different statuses
-- CAS Building - Old Building coordinates

-- 1. Full trash bin (bin1)
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'Trash Bin A-1',
  'CAS Building - Old Building',
  11.771040526266901,
  124.88625768899385,
  'full',
  0.95,
  'BIN-A1-001',
  'Ultrasonic',
  true,
  NOW(),
  NOW()
) ON CONFLICT (device_id) DO UPDATE SET
  status = EXCLUDED.status,
  fill_level = EXCLUDED.fill_level,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  last_updated_at = EXCLUDED.last_updated_at;

-- 2. Half/Medium trash bin (bin2)
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'Trash Bin B-2',
  'CAS Building - Old Building',
  11.770935494095584,
  124.88642398594948,
  'half',
  0.55,
  'BIN-B2-002',
  'Ultrasonic',
  true,
  NOW(),
  NOW()
) ON CONFLICT (device_id) DO UPDATE SET
  status = EXCLUDED.status,
  fill_level = EXCLUDED.fill_level,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  last_updated_at = EXCLUDED.last_updated_at;

-- 3. Empty trash bin (bin3)
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'Trash Bin C-3',
  'CAS Building - Old Building',
  11.770956500533059,
  124.88659564732302,
  'empty',
  0.15,
  'BIN-C3-003',
  'Ultrasonic',
  true,
  NOW(),
  NOW()
) ON CONFLICT (device_id) DO UPDATE SET
  status = EXCLUDED.status,
  fill_level = EXCLUDED.fill_level,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  last_updated_at = EXCLUDED.last_updated_at;

-- 4. Offline/Out of range trash bin (bin4)
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'Trash Bin D-4',
  'CAS Building - Old Building',
  11.77099588759902,
  124.88682899950274,
  'offline',
  0.0,
  'BIN-D4-004',
  'Ultrasonic',
  true,
  NOW(),
  NOW()
) ON CONFLICT (device_id) DO UPDATE SET
  status = EXCLUDED.status,
  fill_level = EXCLUDED.fill_level,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  last_updated_at = EXCLUDED.last_updated_at;

-- 5. Another Half/Medium trash bin (bin5)
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  sensor_type,
  is_active,
  created_at,
  last_updated_at
) VALUES (
  'Trash Bin E-5',
  'CAS Building - Old Building',
  11.771058906892792,
  124.8870489406376,
  'half',
  0.65,
  'BIN-E5-005',
  'Ultrasonic',
  true,
  NOW(),
  NOW()
) ON CONFLICT (device_id) DO UPDATE SET
  status = EXCLUDED.status,
  fill_level = EXCLUDED.fill_level,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  last_updated_at = EXCLUDED.last_updated_at;

-- Verify the inserts
SELECT 
  name,
  location,
  latitude,
  longitude,
  status,
  fill_level,
  device_id,
  created_at
FROM trashcans
WHERE device_id IN ('BIN-A1-001', 'BIN-B2-002', 'BIN-C3-003', 'BIN-D4-004', 'BIN-E5-005')
ORDER BY status, name;

