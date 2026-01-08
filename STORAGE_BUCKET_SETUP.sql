-- =====================================================
-- SUPABASE STORAGE BUCKET SETUP
-- =====================================================
-- Configuration for storing task completion photos
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. CREATE STORAGE BUCKET
-- =====================================================

-- Note: Storage buckets are created via Supabase Dashboard or Storage API
-- This SQL file provides the configuration and policies

-- Bucket name: task-completion-photos
-- Public: false (private bucket, requires authentication)
-- File size limit: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- =====================================================
-- 2. STORAGE POLICIES (RLS for Storage)
-- =====================================================

-- Policy: Staff can upload photos for their own task completions
-- This is set up via Supabase Dashboard → Storage → Policies

-- Example policy (set up in Dashboard):
-- Policy Name: "Staff can upload task completion photos"
-- Policy Type: INSERT
-- Policy Definition:
--   (bucket_id = 'task-completion-photos'::text) 
--   AND (auth.uid()::text = (storage.foldername(name))[1])
--   AND (storage.extension(name) = ANY (ARRAY['jpg'::text, 'jpeg'::text, 'png'::text, 'webp'::text]))
--   AND (( SELECT count(*) FROM tasks WHERE id = (storage.foldername(name))[2]::uuid AND assigned_staff_id = auth.uid()) > 0)

-- Policy: Staff can view their own uploaded photos
-- Policy Name: "Staff can view own task completion photos"
-- Policy Type: SELECT
-- Policy Definition:
--   (bucket_id = 'task-completion-photos'::text) 
--   AND (auth.uid()::text = (storage.foldername(name))[1])

-- Policy: Admins can view all photos
-- Policy Name: "Admins can view all task completion photos"
-- Policy Type: SELECT
-- Policy Definition:
--   (bucket_id = 'task-completion-photos'::text) 
--   AND (EXISTS ( SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'::text))

-- Policy: Admins can delete photos
-- Policy Name: "Admins can delete task completion photos"
-- Policy Type: DELETE
-- Policy Definition:
--   (bucket_id = 'task-completion-photos'::text) 
--   AND (EXISTS ( SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'::text))

-- =====================================================
-- 3. HELPER FUNCTION to Generate Photo Path
-- =====================================================

CREATE OR REPLACE FUNCTION generate_task_photo_path(
  p_staff_id UUID,
  p_task_id UUID,
  p_file_extension TEXT DEFAULT 'jpg'
)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- Path format: {staff_id}/{task_id}/{timestamp}.{ext}
  RETURN p_staff_id::text || '/' || 
         p_task_id::text || '/' || 
         extract(epoch from now())::bigint::text || '.' || 
         LOWER(REPLACE(p_file_extension, '.', ''));
END;
$$;

-- =====================================================
-- 4. FUNCTION to Get Photo URL
-- =====================================================

CREATE OR REPLACE FUNCTION get_task_photo_url(p_photo_path TEXT)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_supabase_url TEXT;
BEGIN
  -- Get Supabase URL from settings or use default
  -- In production, this should come from environment or settings table
  v_supabase_url := 'https://ssztyskjcoilweqmheef.supabase.co';
  
  RETURN v_supabase_url || '/storage/v1/object/public/task-completion-photos/' || p_photo_path;
END;
$$;

-- =====================================================
-- 5. STORAGE BUCKET CONFIGURATION (Manual Setup Required)
-- =====================================================

/*
TO CREATE THE BUCKET MANUALLY:

1. Go to Supabase Dashboard → Storage
2. Click "New bucket"
3. Configure:
   - Name: task-completion-photos
   - Public: false (private)
   - File size limit: 10485760 (10MB)
   - Allowed MIME types: image/jpeg, image/png, image/webp

4. Set up policies (see section 2 above)

OR use Supabase Management API:

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-completion-photos',
  'task-completion-photos',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);
*/

-- =====================================================
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Check if bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'task-completion-photos';

-- Check storage policies
-- SELECT * FROM storage.policies WHERE bucket_id = 'task-completion-photos';

-- Get storage usage
-- SELECT 
--   bucket_id,
--   COUNT(*) as file_count,
--   SUM(metadata->>'size')::bigint as total_size_bytes
-- FROM storage.objects
-- WHERE bucket_id = 'task-completion-photos'
-- GROUP BY bucket_id;






