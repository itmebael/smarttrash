-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow users to view their own profile
CREATE POLICY "Users can view own profile" 
ON public.users FOR SELECT 
USING (auth.uid() = id);

-- Policy: Allow admins to view all profiles
-- Assuming 'role' is a column in public.users and we trust it. 
-- Note: Using a recursive check on the same table can be tricky/expensive. 
-- A simpler approach for client-side is often just allowing read if you are authenticated, 
-- but strictly, we want admins.
-- For now, let's allow authenticated users to view all (staff need to see other staff maybe?)
-- Or better:
CREATE POLICY "Admins can view all profiles" 
ON public.users FOR SELECT 
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- Policy: Allow users to insert their OWN profile (Critical for signup)
CREATE POLICY "Users can insert own profile" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Policy: Allow users to update their OWN profile
CREATE POLICY "Users can update own profile" 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

-- Policy: Allow admins to update ANY profile
CREATE POLICY "Admins can update any profile" 
ON public.users FOR UPDATE 
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- Policy: Allow admins to insert ANY profile (For creating staff accounts)
-- Note: This only works if the Admin client is performing the insert.
-- However, standard client SDK inserts act as the logged-in user.
-- If Admin is creating a user, they usually use a Function (Service Role).
-- If doing it client-side (as we are falling back to), the Admin cannot insert for another UUID 
-- unless RLS is disabled or a very permissive policy exists.
-- Since our AuthProvider fallback tries to use `tempClient` (New User), 
-- the "Users can insert own profile" policy above is the key one.

-- Policy: Allow admins to delete users
CREATE POLICY "Admins can delete users" 
ON public.users FOR DELETE 
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);
