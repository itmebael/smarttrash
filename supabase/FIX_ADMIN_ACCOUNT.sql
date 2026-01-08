-- =====================================================
-- FIX ADMIN ACCOUNT - Ensure admin exists in public.users
-- =====================================================
-- This script fixes the "No admin user found" error when creating staff

-- Step 1: Check if admin exists in auth.users
DO $$
DECLARE
  admin_auth_id UUID;
  admin_exists_in_public BOOLEAN;
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '🔍 Checking admin account...';
  RAISE NOTICE '==============================================';
  
  -- Find the admin user in auth.users by email
  SELECT id INTO admin_auth_id
  FROM auth.users
  WHERE email = 'admin@ssu.edu.ph'
  LIMIT 1;
  
  IF admin_auth_id IS NULL THEN
    RAISE NOTICE '❌ ERROR: No admin found in auth.users with email: admin@ssu.edu.ph';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  ACTION REQUIRED:';
    RAISE NOTICE '1. Go to Authentication → Users in Supabase Dashboard';
    RAISE NOTICE '2. Click "Add User"';
    RAISE NOTICE '3. Email: admin@ssu.edu.ph';
    RAISE NOTICE '4. Password: admin123';
    RAISE NOTICE '5. Check "Auto Confirm User"';
    RAISE NOTICE '6. After creating, run this script again';
    RAISE NOTICE '==============================================';
    RETURN;
  END IF;
  
  RAISE NOTICE '✅ Admin found in auth.users';
  RAISE NOTICE '   UUID: %', admin_auth_id;
  RAISE NOTICE '';
  
  -- Check if admin exists in public.users
  SELECT EXISTS(
    SELECT 1 FROM public.users 
    WHERE id = admin_auth_id
  ) INTO admin_exists_in_public;
  
  IF NOT admin_exists_in_public THEN
    RAISE NOTICE '⚠️  Admin NOT found in public.users - Adding now...';
    
    -- Insert admin into public.users
    INSERT INTO public.users (
      id,
      email,
      name,
      phone_number,
      role,
      department,
      position,
      is_active,
      created_at,
      updated_at
    )
    VALUES (
      admin_auth_id,
      'admin@ssu.edu.ph',
      'System Administrator',
      '+639123456789',
      'admin',
      'Administration',
      'System Administrator',
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'admin',
      is_active = true,
      updated_at = NOW();
    
    RAISE NOTICE '✅ Admin added to public.users successfully!';
  ELSE
    RAISE NOTICE '✅ Admin already exists in public.users';
    
    -- Update to ensure admin role is set correctly
    UPDATE public.users
    SET 
      role = 'admin',
      is_active = true,
      updated_at = NOW()
    WHERE id = admin_auth_id;
    
    RAISE NOTICE '✅ Admin role verified and updated';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ SUCCESS! Admin account is ready';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Admin Details:';
  RAISE NOTICE '  UUID: %', admin_auth_id;
  RAISE NOTICE '  Email: admin@ssu.edu.ph';
  RAISE NOTICE '  Password: admin123';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now create staff accounts!';
  RAISE NOTICE '==============================================';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
    RAISE NOTICE 'Please contact support if this error persists';
END $$;

-- Step 2: Verify the fix by showing admin details
SELECT 
  u.id,
  u.email,
  u.name,
  u.role,
  u.is_active,
  u.created_at,
  CASE 
    WHEN au.id IS NOT NULL THEN '✅ Yes'
    ELSE '❌ No'
  END as "Auth User Exists"
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'admin@ssu.edu.ph';

