-- =====================================================
-- CREATE ADMIN ACCOUNT (Complete Solution)
-- =====================================================
-- This script creates the admin account in BOTH auth.users and public.users
-- Run this if you don't have an admin account yet

-- OPTION 1: If you already created admin in Supabase Dashboard
-- Just run FIX_ADMIN_ACCOUNT.sql instead

-- OPTION 2: Create admin using service role (requires service_role key)
-- You need to run this through Supabase Admin API or Dashboard SQL Editor

DO $$
DECLARE
  admin_email TEXT := 'admin@ssu.edu.ph';
  admin_password TEXT := 'admin123';
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '⚠️  MANUAL ADMIN CREATION REQUIRED';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Unfortunately, we cannot create auth users directly from SQL.';
  RAISE NOTICE 'Please follow these steps:';
  RAISE NOTICE '';
  RAISE NOTICE '1️⃣  Go to Supabase Dashboard:';
  RAISE NOTICE '    Authentication → Users';
  RAISE NOTICE '';
  RAISE NOTICE '2️⃣  Click "Add User" button';
  RAISE NOTICE '';
  RAISE NOTICE '3️⃣  Fill in the form:';
  RAISE NOTICE '    Email: %', admin_email;
  RAISE NOTICE '    Password: %', admin_password;
  RAISE NOTICE '    ✅ Check "Auto Confirm User"';
  RAISE NOTICE '';
  RAISE NOTICE '4️⃣  Click "Create User"';
  RAISE NOTICE '';
  RAISE NOTICE '5️⃣  Copy the UUID that appears';
  RAISE NOTICE '';
  RAISE NOTICE '6️⃣  Run this command (replace YOUR_UUID):';
  RAISE NOTICE '';
  RAISE NOTICE '    INSERT INTO public.users (id, email, name, role, is_active)';
  RAISE NOTICE '    VALUES (';
  RAISE NOTICE '      ''YOUR_UUID''::uuid,';
  RAISE NOTICE '      ''%'',', admin_email;
  RAISE NOTICE '      ''System Administrator'',';
  RAISE NOTICE '      ''admin'',';
  RAISE NOTICE '      true';
  RAISE NOTICE '    );';
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'OR use FIX_ADMIN_ACCOUNT.sql after step 4';
  RAISE NOTICE '==============================================';
END $$;

