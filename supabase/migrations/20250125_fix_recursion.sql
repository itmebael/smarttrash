-- Fix Infinite Recursion in RLS Policies

-- 1. Create a secure function to check admin status
-- SECURITY DEFINER ensures this function runs with the privileges of the owner (superuser),
-- bypassing the RLS on the 'users' table that caused the infinite loop.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Drop the problematic policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;

-- 3. Re-create policies using the safe function

-- Allow admins to view all profiles
CREATE POLICY "Admins can view all profiles" 
ON public.users FOR SELECT 
USING (public.is_admin());

-- Allow admins to update any profile
CREATE POLICY "Admins can update any profile" 
ON public.users FOR UPDATE 
USING (public.is_admin());

-- Allow admins to delete users
CREATE POLICY "Admins can delete users" 
ON public.users FOR DELETE 
USING (public.is_admin());
