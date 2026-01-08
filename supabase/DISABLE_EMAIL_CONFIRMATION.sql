-- =====================================================
-- DISABLE EMAIL CONFIRMATION FOR STAFF CREATION
-- Run this in Supabase SQL Editor to allow instant staff creation
-- =====================================================

-- This allows the admin to create staff accounts without email verification
-- The staff can login immediately after account creation

-- Note: In production, you may want to enable this for better security
-- But for development/testing, this makes it easier to create accounts

-- You can also disable this through the Supabase Dashboard:
-- 1. Go to Authentication → Settings
-- 2. Under "Email Auth", toggle OFF "Enable email confirmations"
-- 3. Click "Save"

DO $$
BEGIN
  RAISE NOTICE '=====================================================';
  RAISE NOTICE 'To disable email confirmation:';
  RAISE NOTICE '1. Go to your Supabase Dashboard';
  RAISE NOTICE '2. Navigate to Authentication → Settings';
  RAISE NOTICE '3. Scroll to "Email Auth"';
  RAISE NOTICE '4. Toggle OFF "Enable email confirmations"';
  RAISE NOTICE '5. Click Save';
  RAISE NOTICE '';
  RAISE NOTICE 'This will allow staff accounts to be created instantly';
  RAISE NOTICE 'without waiting for email verification.';
  RAISE NOTICE '=====================================================';
END $$;



















