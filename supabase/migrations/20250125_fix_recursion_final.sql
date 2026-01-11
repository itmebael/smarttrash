-- FIX INFINITE RECURSION BY USING JWT METADATA
-- This approach avoids querying the 'users' table entirely for permission checks,
-- which guarantees that no recursion can occur.

-- 1. Drop ALL existing policies on the 'users' table to start clean
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.users;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.users;

-- 2. Create optimized, recursion-free policies

-- VIEW: Users see their own; Admins see all.
-- Admin check uses JWT metadata, avoiding table recursion.
CREATE POLICY "View profiles" 
ON public.users FOR SELECT 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- INSERT: Users can insert their own profile (for signup)
CREATE POLICY "Insert own profile" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- UPDATE: Users update own; Admins update any.
CREATE POLICY "Update profiles" 
ON public.users FOR UPDATE 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- DELETE: Only Admins can delete.
CREATE POLICY "Delete users" 
ON public.users FOR DELETE 
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
