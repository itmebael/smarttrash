-- =====================================================
-- FIX STORAGE PERMISSIONS FOR TASK COMPLETION PHOTOS
-- =====================================================
-- This fixes the 403 error when uploading images
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. CREATE BUCKET IF IT DOESN'T EXIST
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-completion-photos',
  'task-completion-photos',
  false,  -- Private bucket
  10485760,  -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. DROP EXISTING POLICIES (if any)
-- =====================================================

DROP POLICY IF EXISTS "Staff can upload task completion photos" ON storage.objects;
DROP POLICY IF EXISTS "Staff can view own task completion photos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all task completion photos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete task completion photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view photos" ON storage.objects;

-- =====================================================
-- 3. CREATE UPLOAD POLICY (INSERT)
-- =====================================================
-- Allow authenticated users to upload photos to their own folder

CREATE POLICY "Authenticated users can upload photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'task-completion-photos'::text
  AND auth.uid()::text = (storage.foldername(name))[1]
  AND (storage.extension(name) = ANY (ARRAY['jpg'::text, 'jpeg'::text, 'png'::text, 'webp'::text]))
);

-- Alternative simpler policy (if folder structure check fails):
-- CREATE POLICY "Authenticated users can upload photos"
-- ON storage.objects
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   bucket_id = 'task-completion-photos'::text
--   AND (storage.extension(name) = ANY (ARRAY['jpg'::text, 'jpeg'::text, 'png'::text, 'webp'::text]))
-- );

-- =====================================================
-- 4. CREATE VIEW POLICY (SELECT)
-- =====================================================
-- Allow users to view their own photos and admins to view all

CREATE POLICY "Users can view own photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'task-completion-photos'::text
  AND (
    -- Users can view their own photos (folder structure: {user_id}/{task_id}/...)
    auth.uid()::text = (storage.foldername(name))[1]
    OR
    -- Admins can view all photos
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
);

-- =====================================================
-- 5. CREATE DELETE POLICY
-- =====================================================
-- Only admins can delete photos

CREATE POLICY "Admins can delete photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'task-completion-photos'::text
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- =====================================================
-- 6. VERIFY POLICIES
-- =====================================================

-- Check bucket exists
SELECT * FROM storage.buckets WHERE id = 'task-completion-photos';

-- Check policies
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%task-completion%' OR policyname LIKE '%photo%';

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. The bucket must be created first (step 1)
-- 2. If you get errors about folder structure, use the simpler upload policy
-- 3. Make sure the user is authenticated (logged in) when uploading
-- 4. File path format should be: {user_id}/{task_id}/{timestamp}.jpg
-- 5. If issues persist, check that RLS is enabled on storage.objects:
--    ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;






