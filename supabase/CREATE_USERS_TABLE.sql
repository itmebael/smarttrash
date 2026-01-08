-- =====================================================
-- CREATE USERS TABLE FOR ECOWASTE MANAGEMENT SYSTEM
-- =====================================================

-- This table stores all user information (admin and staff)
-- Run this SQL in Supabase SQL Editor:
-- https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  email text NOT NULL,
  name text NOT NULL,
  phone_number text NULL,
  role text NOT NULL,
  profile_image_url text NULL,
  fcm_token text NULL,
  
  -- Additional user details
  age integer NULL,
  address text NULL,
  city text NULL,
  state text NULL,
  zip_code text NULL,
  department text NULL,
  position text NULL,
  date_of_birth date NULL,
  emergency_contact text NULL,
  emergency_phone text NULL,
  
  -- Status tracking
  is_active boolean NULL DEFAULT true,
  
  -- Timestamps
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  last_login_at timestamp with time zone NULL,
  
  -- Constraints
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_email_key UNIQUE (email),
  CONSTRAINT email_format CHECK (
    (
      email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text
    )
  ),
  CONSTRAINT users_role_check CHECK (
    (role = ANY (ARRAY['admin'::text, 'staff'::text]))
  )
) TABLESPACE pg_default;

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Index for email lookups (authentication)
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users USING btree (email) TABLESPACE pg_default;

-- Index for role filtering (staff vs admin)
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users USING btree (role) TABLESPACE pg_default;

-- Index for active status filtering
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users USING btree (is_active) TABLESPACE pg_default;

-- =====================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can insert users
CREATE POLICY "Admins can insert users"
  ON public.users FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update users
CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Admins can delete users
CREATE POLICY "Admins can delete users"
  ON public.users FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Users table created successfully!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Table: public.users';
  RAISE NOTICE 'Columns: id, email, name, phone_number, role, ...';
  RAISE NOTICE 'Indexes: idx_users_email, idx_users_role, idx_users_is_active';
  RAISE NOTICE 'RLS: Enabled with 6 policies';
  RAISE NOTICE '==============================================';
END $$;


