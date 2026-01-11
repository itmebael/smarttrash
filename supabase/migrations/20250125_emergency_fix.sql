-- EMERGENCY FIX FOR INFINITE RECURSION
-- Run this in Supabase SQL Editor

-- 1. Disable RLS immediately to stop the crash
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. Drop the problematic policies (and any others that might exist)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "View profiles" ON public.users;
DROP POLICY IF EXISTS "Insert own profile" ON public.users;
DROP POLICY IF EXISTS "Update profiles" ON public.users;
DROP POLICY IF EXISTS "Delete users" ON public.users;

-- 3. Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. Create SAFE policies that use JWT Metadata (No recursion)

-- View: Users see own, Admins see all
CREATE POLICY "View profiles" 
ON public.users FOR SELECT 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- Insert: Users can insert their own (for signup)
CREATE POLICY "Insert own profile" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Update: Users update own, Admins update any
CREATE POLICY "Update profiles" 
ON public.users FOR UPDATE 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- Delete: Only Admins
CREATE POLICY "Delete users" 
ON public.users FOR DELETE 
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
