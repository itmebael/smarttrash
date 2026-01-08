-- =====================================================
-- ADD CASBIN1 TO THE SYSTEM
-- =====================================================
-- This script adds a smart bin named "casbin1" to the system
-- It creates the smart_bin table if needed, ensures the sync function exists,
-- and inserts the bin data which will automatically sync to trashcans
-- =====================================================

-- Step 1: Enable UUID extension (needed for trashcans table)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Ensure trashcans table exists first (required for sync function)
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

-- Step 3: Ensure smart_bin table exists with the correct structure
CREATE TABLE IF NOT EXISTS public.smart_bin (
  id SERIAL NOT NULL,
  distance_cm DOUBLE PRECISION NOT NULL,
  status TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
  CONSTRAINT smart_bin_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_smart_bin_created_at 
ON public.smart_bin USING BTREE (created_at) TABLESPACE pg_default;

-- Step 4: Ensure sync function exists (standard version)
-- Note: The sync function will create trashcans with generic names
-- We'll manually update casbin1 after insertion
CREATE OR REPLACE FUNCTION sync_smart_bin_to_trashcan()
RETURNS TRIGGER AS $$
DECLARE
  bin_fill_level DECIMAL(3, 2);
  bin_status TEXT;
BEGIN
  -- Calculate fill level from distance (assumes 100cm max depth)
  -- Closer distance = fuller bin
  bin_fill_level := GREATEST(0, LEAST(1, (100 - NEW.distance_cm) / 100));
  
  -- Determine status from fill level or use provided status
  IF NEW.status IS NOT NULL THEN
    bin_status := NEW.status;
  ELSIF bin_fill_level >= 0.8 THEN
    bin_status := 'full';
  ELSIF bin_fill_level >= 0.4 THEN
    bin_status := 'half';
  ELSE
    bin_status := 'empty';
  END IF;
  
  -- Insert or update trashcan with generic name
  -- We'll update casbin1 manually after this
  INSERT INTO trashcans (
    name,
    location,
    latitude,
    longitude,
    status,
    fill_level,
    device_id,
    sensor_type,
    last_updated_at,
    created_at,
    is_active
  )
  VALUES (
    'Smart Bin #' || NEW.id,
    'SSU Campus',
    11.7711,
    124.8866,
    bin_status,
    bin_fill_level,
    'SMARTBIN-' || NEW.id::TEXT,
    'Ultrasonic',
    NEW.created_at,
    NEW.created_at,
    true
  )
  ON CONFLICT (device_id) 
  DO UPDATE SET
    status = EXCLUDED.status,
    fill_level = EXCLUDED.fill_level,
    last_updated_at = EXCLUDED.last_updated_at;
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Ensure trigger exists
DROP TRIGGER IF EXISTS trigger_sync_smart_bin ON smart_bin;
CREATE TRIGGER trigger_sync_smart_bin
  AFTER INSERT ON smart_bin FOR EACH ROW
  EXECUTE FUNCTION sync_smart_bin_to_trashcan();

-- Step 6: Insert casbin1 data into smart_bin
-- Using a distance that represents a medium fill level (around 50cm = 50% full)
-- Get the ID of the inserted row
DO $$
DECLARE
  v_smart_bin_id INTEGER;
BEGIN
  -- Insert into smart_bin
  INSERT INTO public.smart_bin (distance_cm, status, created_at)
  VALUES (
    50.0,  -- 50cm distance = approximately 50% full
    'half',  -- Status: half full
    NOW()
  )
  RETURNING id INTO v_smart_bin_id;
  
  RAISE NOTICE 'Inserted smart_bin with ID: %', v_smart_bin_id;
  
  -- Step 5: Update the trashcan created by the trigger to have the correct name and location
  UPDATE public.trashcans
  SET
    name = 'casbin1',
    location = 'CAS Building - 1st Floor',
    latitude = 11.77118000,  -- CAS Building coordinates
    longitude = 124.88672000,
    device_id = 'CASBIN1-' || v_smart_bin_id::TEXT,
    notes = 'Smart bin synced from smart_bin table. Distance: 50cm'
  WHERE device_id = 'SMARTBIN-' || v_smart_bin_id::TEXT;
  
  RAISE NOTICE 'Updated trashcan with name: casbin1';
END $$;

-- Step 7: Verify the bin was added
SELECT 
  'smart_bin' as source_table,
  id,
  distance_cm,
  status,
  created_at
FROM public.smart_bin 
WHERE id = (SELECT MAX(id) FROM public.smart_bin)
UNION ALL
SELECT 
  'trashcans' as source_table,
  NULL::INTEGER as id,
  NULL::DOUBLE PRECISION as distance_cm,
  status,
  created_at
FROM public.trashcans 
WHERE name = 'casbin1' OR device_id LIKE 'CASBIN1-%'
ORDER BY source_table;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ casbin1 added successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Bin Details:';
  RAISE NOTICE '  Name: casbin1';
  RAISE NOTICE '  Location: CAS Building - 1st Floor';
  RAISE NOTICE '  Coordinates: 11.77118000, 124.88672000';
  RAISE NOTICE '  Status: half (50% full)';
  RAISE NOTICE '  Device ID: CASBIN1-001';
  RAISE NOTICE '';
  RAISE NOTICE 'The bin will appear in:';
  RAISE NOTICE '  - smart_bin table (sensor data)';
  RAISE NOTICE '  - trashcans table (synced automatically)';
  RAISE NOTICE '';
  RAISE NOTICE 'To update the bin status, insert new data into smart_bin:';
  RAISE NOTICE '  INSERT INTO smart_bin (distance_cm, status)';
  RAISE NOTICE '  VALUES (30.0, ''full'');  -- 30cm = 70% full';
  RAISE NOTICE '==============================================';
END $$;


-- =====================================================
-- This script adds a smart bin named "casbin1" to the system
-- It creates the smart_bin table if needed, ensures the sync function exists,
-- and inserts the bin data which will automatically sync to trashcans
-- =====================================================

-- Step 1: Enable UUID extension (needed for trashcans table)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Ensure trashcans table exists first (required for sync function)
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

-- Step 3: Ensure smart_bin table exists with the correct structure
CREATE TABLE IF NOT EXISTS public.smart_bin (
  id SERIAL NOT NULL,
  distance_cm DOUBLE PRECISION NOT NULL,
  status TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
  CONSTRAINT smart_bin_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_smart_bin_created_at 
ON public.smart_bin USING BTREE (created_at) TABLESPACE pg_default;

-- Step 4: Ensure sync function exists (standard version)
-- Note: The sync function will create trashcans with generic names
-- We'll manually update casbin1 after insertion
CREATE OR REPLACE FUNCTION sync_smart_bin_to_trashcan()
RETURNS TRIGGER AS $$
DECLARE
  bin_fill_level DECIMAL(3, 2);
  bin_status TEXT;
BEGIN
  -- Calculate fill level from distance (assumes 100cm max depth)
  -- Closer distance = fuller bin
  bin_fill_level := GREATEST(0, LEAST(1, (100 - NEW.distance_cm) / 100));
  
  -- Determine status from fill level or use provided status
  IF NEW.status IS NOT NULL THEN
    bin_status := NEW.status;
  ELSIF bin_fill_level >= 0.8 THEN
    bin_status := 'full';
  ELSIF bin_fill_level >= 0.4 THEN
    bin_status := 'half';
  ELSE
    bin_status := 'empty';
  END IF;
  
  -- Insert or update trashcan with generic name
  -- We'll update casbin1 manually after this
  INSERT INTO trashcans (
    name,
    location,
    latitude,
    longitude,
    status,
    fill_level,
    device_id,
    sensor_type,
    last_updated_at,
    created_at,
    is_active
  )
  VALUES (
    'Smart Bin #' || NEW.id,
    'SSU Campus',
    11.7711,
    124.8866,
    bin_status,
    bin_fill_level,
    'SMARTBIN-' || NEW.id::TEXT,
    'Ultrasonic',
    NEW.created_at,
    NEW.created_at,
    true
  )
  ON CONFLICT (device_id) 
  DO UPDATE SET
    status = EXCLUDED.status,
    fill_level = EXCLUDED.fill_level,
    last_updated_at = EXCLUDED.last_updated_at;
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Ensure trigger exists
DROP TRIGGER IF EXISTS trigger_sync_smart_bin ON smart_bin;
CREATE TRIGGER trigger_sync_smart_bin
  AFTER INSERT ON smart_bin FOR EACH ROW
  EXECUTE FUNCTION sync_smart_bin_to_trashcan();

-- Step 6: Insert casbin1 data into smart_bin
-- Using a distance that represents a medium fill level (around 50cm = 50% full)
-- Get the ID of the inserted row
DO $$
DECLARE
  v_smart_bin_id INTEGER;
BEGIN
  -- Insert into smart_bin
  INSERT INTO public.smart_bin (distance_cm, status, created_at)
  VALUES (
    50.0,  -- 50cm distance = approximately 50% full
    'half',  -- Status: half full
    NOW()
  )
  RETURNING id INTO v_smart_bin_id;
  
  RAISE NOTICE 'Inserted smart_bin with ID: %', v_smart_bin_id;
  
  -- Step 5: Update the trashcan created by the trigger to have the correct name and location
  UPDATE public.trashcans
  SET
    name = 'casbin1',
    location = 'CAS Building - 1st Floor',
    latitude = 11.77118000,  -- CAS Building coordinates
    longitude = 124.88672000,
    device_id = 'CASBIN1-' || v_smart_bin_id::TEXT,
    notes = 'Smart bin synced from smart_bin table. Distance: 50cm'
  WHERE device_id = 'SMARTBIN-' || v_smart_bin_id::TEXT;
  
  RAISE NOTICE 'Updated trashcan with name: casbin1';
END $$;

-- Step 7: Verify the bin was added
SELECT 
  'smart_bin' as source_table,
  id,
  distance_cm,
  status,
  created_at
FROM public.smart_bin 
WHERE id = (SELECT MAX(id) FROM public.smart_bin)
UNION ALL
SELECT 
  'trashcans' as source_table,
  NULL::INTEGER as id,
  NULL::DOUBLE PRECISION as distance_cm,
  status,
  created_at
FROM public.trashcans 
WHERE name = 'casbin1' OR device_id LIKE 'CASBIN1-%'
ORDER BY source_table;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ casbin1 added successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Bin Details:';
  RAISE NOTICE '  Name: casbin1';
  RAISE NOTICE '  Location: CAS Building - 1st Floor';
  RAISE NOTICE '  Coordinates: 11.77118000, 124.88672000';
  RAISE NOTICE '  Status: half (50% full)';
  RAISE NOTICE '  Device ID: CASBIN1-001';
  RAISE NOTICE '';
  RAISE NOTICE 'The bin will appear in:';
  RAISE NOTICE '  - smart_bin table (sensor data)';
  RAISE NOTICE '  - trashcans table (synced automatically)';
  RAISE NOTICE '';
  RAISE NOTICE 'To update the bin status, insert new data into smart_bin:';
  RAISE NOTICE '  INSERT INTO smart_bin (distance_cm, status)';
  RAISE NOTICE '  VALUES (30.0, ''full'');  -- 30cm = 70% full';
  RAISE NOTICE '==============================================';
END $$;

