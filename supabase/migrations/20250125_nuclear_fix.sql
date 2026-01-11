-- NUCLEAR FIX: Drop ALL policies on public.users dynamically
-- This guarantees we remove the recursive ones, no matter what they are named.

DO $$ 
DECLARE 
    pol record; 
BEGIN 
    -- Loop through all policies on the 'users' table
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'users' AND schemaname = 'public' 
    LOOP 
        -- Drop the policy
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', pol.policyname); 
    END LOOP; 
END $$;

-- Enable RLS (just in case)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create SAFE, NON-RECURSIVE policies

-- 1. View: Users see own, Admins see all (via JWT metadata)
-- We check the 'role' inside the JWT token, avoiding a query to the 'users' table
CREATE POLICY "safe_view_profiles" 
ON public.users FOR SELECT 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- 2. Insert: Users can insert their own
CREATE POLICY "safe_insert_own" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- 3. Update: Users update own, Admins update any
CREATE POLICY "safe_update_profiles" 
ON public.users FOR UPDATE 
USING (
  auth.uid() = id 
  OR 
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);

-- 4. Delete: Admins only
CREATE POLICY "safe_delete_users" 
ON public.users FOR DELETE 
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
);
