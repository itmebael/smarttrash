-- Update trashcans table schema to match the provided structure
-- This ensures offline status is properly supported

-- First, ensure the uuid-ossp extension exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Update the status constraint to include 'offline' and 'alive' if not already present
DO $$
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'trashcans_status_check'
  ) THEN
    ALTER TABLE public.trashcans DROP CONSTRAINT trashcans_status_check;
  END IF;
  
  -- Add new constraint with all status values including 'offline' and 'alive'
  ALTER TABLE public.trashcans 
  ADD CONSTRAINT trashcans_status_check CHECK (
    status = ANY (
      ARRAY[
        'empty'::text,
        'half'::text,
        'full'::text,
        'maintenance'::text,
        'offline'::text,
        'alive'::text
      ]
    )
  );
END $$;

-- Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_trashcans_status 
  ON public.trashcans USING btree (status) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_trashcans_device_id 
  ON public.trashcans USING btree (device_id) TABLESPACE pg_default;

-- Ensure foreign key constraint exists for tasks.trashcan_id
DO $$
BEGIN
  -- Check if the foreign key constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'tasks_trashcan_id_fkey'
    AND conrelid = 'public.tasks'::regclass
  ) THEN
    -- Add the foreign key constraint if it doesn't exist
    ALTER TABLE public.tasks
    ADD CONSTRAINT tasks_trashcan_id_fkey 
    FOREIGN KEY (trashcan_id) 
    REFERENCES public.trashcans(id) 
    ON DELETE CASCADE;
    
    RAISE NOTICE 'Foreign key constraint tasks_trashcan_id_fkey created';
  ELSE
    RAISE NOTICE 'Foreign key constraint tasks_trashcan_id_fkey already exists';
  END IF;
END $$;

-- Verify the table structure matches the provided schema
-- Note: The full table creation is shown below for reference, but we only
-- modify the constraint since the table likely already exists

/*
Full table structure (for reference):
CREATE TABLE IF NOT EXISTS public.trashcans (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  name text NOT NULL,
  location text NOT NULL,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  status text NOT NULL DEFAULT 'empty'::text,
  fill_level numeric(3, 2) NULL DEFAULT 0.0,
  device_id text NULL,
  sensor_type text NULL,
  battery_level integer NULL,
  last_emptied_at timestamp with time zone NULL,
  last_updated_at timestamp with time zone NULL DEFAULT now(),
  created_at timestamp with time zone NULL DEFAULT now(),
  notes text NULL,
  is_active boolean NULL DEFAULT true,
  CONSTRAINT trashcans_pkey PRIMARY KEY (id),
  CONSTRAINT trashcans_device_id_key UNIQUE (device_id),
  CONSTRAINT trashcans_battery_level_check CHECK (
    (battery_level >= 0) AND (battery_level <= 100)
  ),
  CONSTRAINT trashcans_fill_level_check CHECK (
    (fill_level >= (0)::numeric) AND (fill_level <= (1)::numeric)
  ),
  CONSTRAINT trashcans_status_check CHECK (
    status = ANY (
      ARRAY[
        'empty'::text,
        'half'::text,
        'full'::text,
        'maintenance'::text,
        'offline'::text,
        'alive'::text
      ]
    )
  )
) TABLESPACE pg_default;
*/

