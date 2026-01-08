-- =====================================================
-- VERIFY ADMIN ACCOUNT - Diagnostic Script
-- Run this to check if your admin user exists
-- =====================================================

-- Check 1: Does the auth user exist?
DO $$
DECLARE
  auth_user_count INTEGER;
  auth_user_record RECORD;
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '🔍 CHECKING AUTH.USERS TABLE...';
  RAISE NOTICE '==============================================';
  
  SELECT COUNT(*) INTO auth_user_count
  FROM auth.users
  WHERE email = 'admin@ssu.edu.ph';
  
  IF auth_user_count = 0 THEN
    RAISE NOTICE '❌ AUTH USER NOT FOUND!';
    RAISE NOTICE '';
    RAISE NOTICE '👉 ACTION REQUIRED:';
    RAISE NOTICE '1. Go to Supabase Dashboard';
    RAISE NOTICE '2. Authentication → Users';
    RAISE NOTICE '3. Click "Add User"';
    RAISE NOTICE '4. Email: admin@ssu.edu.ph';
    RAISE NOTICE '5. Password: admin123';
    RAISE NOTICE '6. Enable "Auto Confirm User"';
    RAISE NOTICE '7. Click "Create User"';
  ELSE
    SELECT id, email, email_confirmed_at, created_at
    INTO auth_user_record
    FROM auth.users
    WHERE email = 'admin@ssu.edu.ph';
    
    RAISE NOTICE '✅ AUTH USER EXISTS!';
    RAISE NOTICE 'ID: %', auth_user_record.id;
    RAISE NOTICE 'Email: %', auth_user_record.email;
    RAISE NOTICE 'Email Confirmed: %', 
      CASE 
        WHEN auth_user_record.email_confirmed_at IS NOT NULL THEN 'YES'
        ELSE '❌ NO - You must enable Auto Confirm!'
      END;
    RAISE NOTICE 'Created At: %', auth_user_record.created_at;
  END IF;
  RAISE NOTICE '==============================================';
END $$;

-- Check 2: Does the database user exist?
DO $$
DECLARE
  db_user_count INTEGER;
  db_user_record RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🔍 CHECKING PUBLIC.USERS TABLE...';
  RAISE NOTICE '==============================================';
  
  SELECT COUNT(*) INTO db_user_count
  FROM public.users
  WHERE email = 'admin@ssu.edu.ph';
  
  IF db_user_count = 0 THEN
    RAISE NOTICE '❌ DATABASE USER NOT FOUND!';
    RAISE NOTICE '';
    RAISE NOTICE '👉 ACTION REQUIRED:';
    RAISE NOTICE 'Run this SQL to link the auth user:';
    RAISE NOTICE '';
    RAISE NOTICE 'INSERT INTO public.users (id, email, name, phone_number, role, is_active)';
    RAISE NOTICE 'SELECT id, email, ''System Administrator'', ''+639123456789'', ''admin'', true';
    RAISE NOTICE 'FROM auth.users WHERE email = ''admin@ssu.edu.ph'';';
  ELSE
    SELECT id, email, name, role, is_active
    INTO db_user_record
    FROM public.users
    WHERE email = 'admin@ssu.edu.ph';
    
    RAISE NOTICE '✅ DATABASE USER EXISTS!';
    RAISE NOTICE 'ID: %', db_user_record.id;
    RAISE NOTICE 'Email: %', db_user_record.email;
    RAISE NOTICE 'Name: %', db_user_record.name;
    RAISE NOTICE 'Role: %', db_user_record.role;
    RAISE NOTICE 'Active: %', db_user_record.is_active;
  END IF;
  RAISE NOTICE '==============================================';
END $$;

-- Check 3: Are they linked correctly?
DO $$
DECLARE
  linked_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🔍 CHECKING IF AUTH AND DATABASE ARE LINKED...';
  RAISE NOTICE '==============================================';
  
  SELECT COUNT(*) INTO linked_count
  FROM auth.users au
  INNER JOIN public.users pu ON au.id = pu.id
  WHERE au.email = 'admin@ssu.edu.ph';
  
  IF linked_count = 0 THEN
    RAISE NOTICE '❌ NOT LINKED!';
    RAISE NOTICE 'Auth user and database user have different IDs.';
  ELSE
    RAISE NOTICE '✅ PROPERLY LINKED!';
    RAISE NOTICE 'Auth user and database user share the same ID.';
  END IF;
  RAISE NOTICE '==============================================';
END $$;

-- Summary
DO $$
DECLARE
  auth_exists BOOLEAN;
  db_exists BOOLEAN;
  linked BOOLEAN;
  email_confirmed BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📋 SUMMARY';
  RAISE NOTICE '==============================================';
  
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'admin@ssu.edu.ph') INTO auth_exists;
  SELECT EXISTS(SELECT 1 FROM public.users WHERE email = 'admin@ssu.edu.ph') INTO db_exists;
  SELECT EXISTS(
    SELECT 1 FROM auth.users au
    INNER JOIN public.users pu ON au.id = pu.id
    WHERE au.email = 'admin@ssu.edu.ph'
  ) INTO linked;
  SELECT EXISTS(
    SELECT 1 FROM auth.users 
    WHERE email = 'admin@ssu.edu.ph' AND email_confirmed_at IS NOT NULL
  ) INTO email_confirmed;
  
  IF auth_exists AND db_exists AND linked AND email_confirmed THEN
    RAISE NOTICE '🎉 EVERYTHING IS READY!';
    RAISE NOTICE '';
    RAISE NOTICE 'You can log in with:';
    RAISE NOTICE '  Email: admin@ssu.edu.ph';
    RAISE NOTICE '  Password: admin123';
    RAISE NOTICE '';
    RAISE NOTICE 'If login still fails, the password might be wrong.';
    RAISE NOTICE 'Reset it in: Dashboard → Authentication → Users → Click user → Reset Password';
  ELSE
    RAISE NOTICE '⚠️  SETUP INCOMPLETE';
    RAISE NOTICE '';
    RAISE NOTICE 'Status:';
    RAISE NOTICE '  Auth User Exists: %', CASE WHEN auth_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE '  Email Confirmed: %', CASE WHEN email_confirmed THEN '✅' ELSE '❌' END;
    RAISE NOTICE '  Database User Exists: %', CASE WHEN db_exists THEN '✅' ELSE '❌' END;
    RAISE NOTICE '  Properly Linked: %', CASE WHEN linked THEN '✅' ELSE '❌' END;
  END IF;
  RAISE NOTICE '==============================================';
END $$;

