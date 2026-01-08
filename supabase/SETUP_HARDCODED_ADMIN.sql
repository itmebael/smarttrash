-- =====================================================
-- SETUP HARDCODED ADMIN - Run this ONCE
-- This creates the admin record in database for hardcoded login
-- =====================================================

-- Insert the hardcoded admin into public.users
-- This matches the hardcoded admin in your Flutter app
INSERT INTO public.users (
  id,
  email,
  name,
  phone_number,
  role,
  is_active,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000001'::UUID,
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) 
DO UPDATE SET 
  role = 'admin',
  is_active = true,
  email = 'admin@ssu.edu.ph',
  name = 'System Administrator',
  phone_number = '+639123456789',
  updated_at = NOW();

-- Verify the admin was created
DO $$
DECLARE
  admin_record RECORD;
BEGIN
  SELECT id, email, name, role, is_active
  INTO admin_record
  FROM public.users
  WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;

  IF admin_record IS NOT NULL THEN
    RAISE NOTICE '==============================================';
    RAISE NOTICE '✅ HARDCODED ADMIN CREATED IN DATABASE!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ID: %', admin_record.id;
    RAISE NOTICE 'Email: %', admin_record.email;
    RAISE NOTICE 'Name: %', admin_record.name;
    RAISE NOTICE 'Role: %', admin_record.role;
    RAISE NOTICE 'Active: %', admin_record.is_active;
    RAISE NOTICE '==============================================';
    RAISE NOTICE '🎉 You can now:';
    RAISE NOTICE '1. Log in with: admin@ssu.edu.ph / admin123';
    RAISE NOTICE '2. Create staff accounts that save online';
    RAISE NOTICE '3. All data persists in Supabase';
    RAISE NOTICE '==============================================';
  ELSE
    RAISE EXCEPTION '❌ Failed to create hardcoded admin';
  END IF;
END $$;


















