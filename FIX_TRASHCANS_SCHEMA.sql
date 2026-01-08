-- =====================================================
-- FIX TRASHCANS TABLE SCHEMA AND TRIGGER
-- =====================================================
-- This file ensures the trashcans table matches the exact schema
-- and the trigger works correctly for fill_level updates

-- =====================================================
-- 1. DROP EXISTING TRIGGER IF EXISTS
-- =====================================================
DROP TRIGGER IF EXISTS trigger_notify_trashcan_full ON trashcans;
DROP FUNCTION IF EXISTS notify_trashcan_full() CASCADE;

-- =====================================================
-- 2. ENSURE TRASHCANS TABLE MATCHES SCHEMA
-- =====================================================

-- Update status constraint to include all valid statuses
ALTER TABLE trashcans 
DROP CONSTRAINT IF EXISTS trashcans_status_check;

ALTER TABLE trashcans
ADD CONSTRAINT trashcans_status_check CHECK (
  status = ANY (
    ARRAY[
      'empty'::text,
      'half'::text,
      'full'::text,
      'maintenance'::text,
      'offline'::text,
      'alive'::text
    ]
  )
);

-- Ensure fill_level constraint exists
ALTER TABLE trashcans 
DROP CONSTRAINT IF EXISTS trashcans_fill_level_check;

ALTER TABLE trashcans
ADD CONSTRAINT trashcans_fill_level_check CHECK (
  (fill_level >= 0::numeric) AND (fill_level <= 1::numeric)
);

-- Ensure battery_level constraint exists
ALTER TABLE trashcans 
DROP CONSTRAINT IF EXISTS trashcans_battery_level_check;

ALTER TABLE trashcans
ADD CONSTRAINT trashcans_battery_level_check CHECK (
  (battery_level >= 0) AND (battery_level <= 100)
);

-- Ensure device_id is unique
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'trashcans_device_id_key'
  ) THEN
    ALTER TABLE trashcans 
    ADD CONSTRAINT trashcans_device_id_key UNIQUE (device_id);
  END IF;
END $$;

-- =====================================================
-- 3. CREATE/UPDATE NOTIFY_TRASHCAN_FULL FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION notify_trashcan_full()
RETURNS TRIGGER AS $$
DECLARE
  v_trashcan_name TEXT;
  v_location TEXT;
BEGIN
  -- Only trigger notification when fill_level changes to full (>= 0.8)
  -- and status is 'full' or becomes 'full'
  IF NEW.fill_level >= 0.8 AND NEW.status = 'full' THEN
    -- Check if it was not full before (to avoid duplicate notifications)
    IF OLD.fill_level IS NULL OR OLD.fill_level < 0.8 OR OLD.status != 'full' THEN
      -- Get trashcan details
      v_trashcan_name := NEW.name;
      v_location := NEW.location;
      
      -- Create notification for admins (user_id = NULL means all admins)
      INSERT INTO notifications (
        title,
        body,
        type,
        priority,
        trashcan_id,
        created_at
      )
      VALUES (
        '🚨 Trashcan Full',
        v_trashcan_name || ' at ' || v_location || ' is full and needs immediate attention',
        'trashcan_full',
        'urgent',
        NEW.id,
        NOW()
      );
      
      RAISE NOTICE 'Notification created for full trashcan: %', v_trashcan_name;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. CREATE TRIGGER FOR FILL_LEVEL UPDATES
-- =====================================================

CREATE TRIGGER trigger_notify_trashcan_full
AFTER UPDATE OF fill_level ON trashcans
FOR EACH ROW
WHEN (OLD.fill_level IS DISTINCT FROM NEW.fill_level)
EXECUTE FUNCTION notify_trashcan_full();

-- =====================================================
-- 5. CREATE/UPDATE AUTO STATUS UPDATE FUNCTION
-- =====================================================

-- Function to auto-update trashcan status based on fill level
-- This ensures status matches fill_level (but respects manual status changes)
CREATE OR REPLACE FUNCTION update_trashcan_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only auto-update status if it's not manually set to maintenance, offline, or alive
  IF NEW.status NOT IN ('maintenance', 'offline', 'alive') THEN
    IF NEW.fill_level >= 0.8 THEN
      NEW.status = 'full';
    ELSIF NEW.fill_level >= 0.4 THEN
      NEW.status = 'half';
    ELSIF NEW.fill_level < 0.4 THEN
      NEW.status = 'empty';
    END IF;
  END IF;
  
  NEW.last_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto status update
DROP TRIGGER IF EXISTS auto_update_trashcan_status ON trashcans;

CREATE TRIGGER auto_update_trashcan_status
BEFORE UPDATE OF fill_level ON trashcans
FOR EACH ROW
WHEN (OLD.fill_level IS DISTINCT FROM NEW.fill_level)
EXECUTE FUNCTION update_trashcan_status();

-- =====================================================
-- 6. CREATE INDEXES IF NOT EXISTS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_trashcans_status ON trashcans USING btree (status);
CREATE INDEX IF NOT EXISTS idx_trashcans_device_id ON trashcans USING btree (device_id);
CREATE INDEX IF NOT EXISTS idx_trashcans_is_active ON trashcans USING btree (is_active);

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON trashcans TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- =====================================================
-- 8. VERIFICATION
-- =====================================================

-- Check if trigger exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_notify_trashcan_full'
  ) THEN
    RAISE NOTICE '✅ Trigger trigger_notify_trashcan_full created successfully';
  ELSE
    RAISE WARNING '❌ Trigger trigger_notify_trashcan_full was not created';
  END IF;
END $$;

-- Check if function exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'notify_trashcan_full'
  ) THEN
    RAISE NOTICE '✅ Function notify_trashcan_full created successfully';
  ELSE
    RAISE WARNING '❌ Function notify_trashcan_full was not created';
  END IF;
END $$;

-- =====================================================
-- NOTES
-- =====================================================
-- 1. The trigger fires AFTER update of fill_level
-- 2. It only creates notifications when fill_level >= 0.8 and status = 'full'
-- 3. It prevents duplicate notifications by checking if it was already full
-- 4. Status can be: empty, half, full, maintenance, offline, alive
-- 5. Auto status update respects manual status changes (maintenance, offline, alive)


