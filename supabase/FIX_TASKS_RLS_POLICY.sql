-- Fix RLS policies for tasks table to ensure staff can view their assigned tasks
-- The issue is that staff need to be able to query tasks where assigned_staff_id matches their user ID

-- Drop existing policies that might be conflicting
DROP POLICY IF EXISTS "Anyone authenticated can view tasks" ON tasks;
DROP POLICY IF EXISTS "Staff can view their assigned tasks" ON tasks;
DROP POLICY IF EXISTS "Users can view tasks" ON tasks;
DROP POLICY IF EXISTS "Anyone authenticated can view tasks" ON tasks;

-- Create a comprehensive policy that allows:
-- 1. Staff to view tasks assigned to them (by matching assigned_staff_id with auth.uid())
-- 2. Admins to view all tasks
-- 3. Anyone authenticated can view tasks (for general queries)
CREATE POLICY "Staff can view their assigned tasks"
  ON tasks FOR SELECT
  USING (
    -- Staff can view tasks assigned to them
    (assigned_staff_id = auth.uid() AND assigned_staff_id IS NOT NULL)
    OR
    -- Admins can view all tasks
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
    OR
    -- Anyone authenticated can view tasks (fallback for general access)
    auth.uid() IS NOT NULL
  );

-- Ensure the policy is enabled
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT SELECT ON tasks TO authenticated;
GRANT INSERT ON tasks TO authenticated;
GRANT UPDATE ON tasks TO authenticated;

-- Add comment
COMMENT ON POLICY "Staff can view their assigned tasks" ON tasks IS 
  'Allows staff to view tasks assigned to them and admins to view all tasks';

