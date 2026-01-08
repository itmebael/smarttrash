-- =====================================================
-- ADD RATING COLUMN TO USERS TABLE
-- =====================================================
-- This adds a rating column so admins can rate staff
-- Run this in Supabase SQL Editor

-- Add rating column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5);

-- Add comment
COMMENT ON COLUMN users.rating IS 'Staff rating from 0.0 to 5.0, set by admin';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_rating ON users(rating);

-- Update existing users to have default rating of 0.0 if null
UPDATE users SET rating = 0.0 WHERE rating IS NULL;






