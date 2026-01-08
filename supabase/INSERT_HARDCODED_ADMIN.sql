-- =====================================================
-- INSERT HARDCODED ADMIN INTO DATABASE
-- This makes the hardcoded admin work with all features
-- =====================================================

-- Insert the hardcoded admin into public.users
-- This allows staff creation and other admin features to work
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
  '00000000-0000-0000-0000-000000000001'::uuid,
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

-- Verify the insert
SELECT 
  '==============================================\n' ||
  '✅ HARDCODED ADMIN INSERTED SUCCESSFULLY!\n' ||
  '==============================================\n' ||
  'Admin Details:\n' ||
  '  ID: ' || id || '\n' ||
  '  Email: ' || email || '\n' ||
  '  Name: ' || name || '\n' ||
  '  Role: ' || role || '\n' ||
  '\n' ||
  'You can now:\n' ||
  '  ✅ Create staff accounts\n' ||
  '  ✅ Use all admin features\n' ||
  '  ✅ System works fully online!\n' ||
  '==============================================' as result
FROM public.users
WHERE id = '00000000-0000-0000-0000-000000000001'::uuid;

