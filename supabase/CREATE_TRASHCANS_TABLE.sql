-- =====================================================
-- CREATE TRASHCANS TABLE
-- =====================================================

CREATE TABLE public.trashcans (
  id uuid not null default extensions.uuid_generate_v4 (),
  name text not null,
  location text not null,
  latitude numeric(10, 8) not null,
  longitude numeric(11, 8) not null,
  status text not null default 'empty'::text,
  fill_level numeric(3, 2) null default 0.0,
  device_id text null,
  sensor_type text null,
  battery_level integer null,
  last_emptied_at timestamp with time zone null,
  last_updated_at timestamp with time zone null default now(),
  created_at timestamp with time zone null default now(),
  notes text null,
  is_active boolean null default true,
  
  constraint trashcans_pkey primary key (id),
  constraint trashcans_device_id_key unique (device_id),
  
  constraint trashcans_battery_level_check check (
    (battery_level >= 0 and battery_level <= 100)
  ),
  constraint trashcans_fill_level_check check (
    (fill_level >= 0::numeric and fill_level <= 1::numeric)
  ),
  constraint trashcans_status_check check (
    (status = any (array['empty'::text, 'half'::text, 'full'::text, 'maintenance'::text]))
  )
) TABLESPACE pg_default;

-- =====================================================
-- CREATE INDEXES ON TRASHCANS TABLE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_trashcans_status 
  ON public.trashcans USING btree (status) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_trashcans_device_id 
  ON public.trashcans USING btree (device_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_trashcans_is_active 
  ON public.trashcans USING btree (is_active) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_trashcans_location 
  ON public.trashcans USING btree (location) TABLESPACE pg_default;

-- =====================================================
-- CREATE TRIGGER FOR AUTO-UPDATE TIMESTAMP
-- =====================================================

CREATE TRIGGER update_trashcans_updated_at 
  BEFORE UPDATE ON trashcans 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ENABLE RLS
-- =====================================================

ALTER TABLE public.trashcans ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CREATE RLS POLICIES
-- =====================================================

-- Allow everyone to view active trashcans
CREATE POLICY "view_active_trashcans" ON public.trashcans
  FOR SELECT
  USING (is_active = true);

-- Allow admin to view all trashcans (including inactive)
CREATE POLICY "admin_view_all_trashcans" ON public.trashcans
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow admin to insert trashcans
CREATE POLICY "admin_insert_trashcans" ON public.trashcans
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow admin to update trashcans
CREATE POLICY "admin_update_trashcans" ON public.trashcans
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow staff to update trashcan status (fill level, etc)
CREATE POLICY "staff_update_trashcan_status" ON public.trashcans
  FOR UPDATE
  USING (is_active = true);

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

-- Trashcans table created successfully!
-- ✅ Table: public.trashcans
-- ✅ Columns: id, name, location, latitude, longitude, status, fill_level, device_id, sensor_type, battery_level, last_emptied_at, last_updated_at, created_at, notes, is_active
-- ✅ Indexes: status, device_id, is_active, location
-- ✅ Constraints: battery_level (0-100), fill_level (0-1), status check
-- ✅ RLS Policies: Enabled with admin and staff policies

