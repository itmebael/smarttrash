-- =====================================================
-- DIAGNOSE ADMIN ISSUE
-- This will tell us exactly what's wrong
-- =====================================================

-- Step 1: Check if hardcoded admin exists in public.users
DO $$
DECLARE
  hardcoded_admin_exists BOOLEAN;
  real_admin_count INTEGER;
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '🔍 DIAGNOSTIC REPORT';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  
  -- Check for hardcoded admin
  SELECT EXISTS(
    SELECT 1 FROM public.users 
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
  ) INTO hardcoded_admin_exists;
  
  IF hardcoded_admin_exists THEN
    RAISE NOTICE '✅ Hardcoded admin EXISTS in public.users';
  ELSE
    RAISE NOTICE '❌ Hardcoded admin MISSING from public.users';
    RAISE NOTICE '   ACTION: Run INSERT_HARDCODED_ADMIN.sql';
  END IF;
  
  -- Check for real admins
  SELECT COUNT(*) INTO real_admin_count
  FROM public.users
  WHERE role = 'admin';
  
  RAISE NOTICE '';
  RAISE NOTICE '👥 Admin accounts found: %', real_admin_count;
  
  IF real_admin_count = 0 THEN
    RAISE NOTICE '❌ NO ADMIN ACCOUNTS FOUND!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
END $$;

-- Step 2: Show all admin accounts
SELECT 
  '=== ALL ADMIN ACCOUNTS ===' as section,
  id,
  email,
  name,
  role,
  is_active,
  created_at
FROM public.users
WHERE role = 'admin'
ORDER BY created_at;

-- Step 3: Check if function exists
SELECT 
  '=== STAFF CREATION FUNCTION ===' as section,
  routine_name as function_name,
  routine_type as type,
  'EXISTS' as status
FROM information_schema.routines
WHERE routine_name = 'create_staff_account'
  AND routine_schema = 'public';

-- Step 4: Test the function with hardcoded admin
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '🧪 TESTING STAFF CREATION';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  
  -- Test if hardcoded admin is accepted
  IF EXISTS(
    SELECT 1 FROM public.users 
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid 
    AND role = 'admin'
  ) THEN
    RAISE NOTICE '✅ Hardcoded admin can create staff accounts';
  ELSE
    RAISE NOTICE '❌ Hardcoded admin CANNOT create staff accounts';
    RAISE NOTICE '   Reason: Not found in public.users OR role != admin';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
END $$;

-- Step 5: Provide fix if needed
DO $$
DECLARE
  needs_fix BOOLEAN;
BEGIN
  SELECT NOT EXISTS(
    SELECT 1 FROM public.users 
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid 
    AND role = 'admin'
  ) INTO needs_fix;
  
  IF needs_fix THEN
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  FIX REQUIRED!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Copy and run this command:';
    RAISE NOTICE '';
    RAISE NOTICE 'INSERT INTO public.users (id, email, name, role, is_active)';
    RAISE NOTICE 'VALUES (';
    RAISE NOTICE '  ''00000000-0000-0000-0000-000000000001''::uuid,';
    RAISE NOTICE '  ''admin@ssu.edu.ph'',';
    RAISE NOTICE '  ''System Administrator'',';
    RAISE NOTICE '  ''admin'',';
    RAISE NOTICE '  true';
    RAISE NOTICE ');';
    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '✅ DATABASE IS READY!';
    RAISE NOTICE '';
    RAISE NOTICE 'If you''re still getting errors, the issue is in the app code.';
    RAISE NOTICE 'Check that currentUserProvider is returning the correct admin.';
  END IF;
END $$;

