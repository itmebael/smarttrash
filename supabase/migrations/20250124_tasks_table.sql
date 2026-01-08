-- Create tasks table for task management
-- This migration creates the tasks table with all necessary fields and constraints

-- Drop the table if it exists (for clean reinstall)
DROP TABLE IF EXISTS public.tasks CASCADE;

-- Create tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  title text NOT NULL,
  description text NULL,
  trashcan_id uuid NULL,
  assigned_staff_id uuid NULL,
  created_by_admin_id uuid NULL,
  status text NOT NULL DEFAULT 'pending'::text,
  priority text NOT NULL DEFAULT 'medium'::text,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  due_date timestamp with time zone NULL,
  started_at timestamp with time zone NULL,
  completed_at timestamp with time zone NULL,
  completion_notes text NULL,
  estimated_duration integer NULL,
  CONSTRAINT tasks_pkey PRIMARY KEY (id),
  CONSTRAINT tasks_priority_check CHECK (
    (
      priority = ANY (
        ARRAY[
          'low'::text,
          'medium'::text,
          'high'::text,
          'urgent'::text
        ]
      )
    )
  ),
  CONSTRAINT tasks_status_check CHECK (
    (
      status = ANY (
        ARRAY[
          'pending'::text,
          'in_progress'::text,
          'completed'::text,
          'cancelled'::text
        ]
      )
    )
  ),
  CONSTRAINT tasks_assigned_staff_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.users(id) ON DELETE SET NULL,
  CONSTRAINT tasks_created_by_admin_fkey FOREIGN KEY (created_by_admin_id) REFERENCES public.users(id) ON DELETE SET NULL,
  CONSTRAINT tasks_trashcan_fkey FOREIGN KEY (trashcan_id) REFERENCES public.trashcans(id) ON DELETE SET NULL
) TABLESPACE pg_default;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks USING btree (status) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks USING btree (priority) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_staff ON public.tasks USING btree (assigned_staff_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_tasks_trashcan ON public.tasks USING btree (trashcan_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks USING btree (due_date) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks USING btree (created_at) TABLESPACE pg_default;

-- Create trigger to automatically update updated_at timestamp
CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON public.tasks 
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tasks table

-- Policy: Admins can see all tasks
CREATE POLICY "Admins can view all tasks" ON public.tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy: Staff can see their own assigned tasks
CREATE POLICY "Staff can view their own tasks" ON public.tasks
  FOR SELECT
  USING (
    assigned_staff_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy: Admins can create tasks
CREATE POLICY "Admins can create tasks" ON public.tasks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy: Admins can update any task
CREATE POLICY "Admins can update any task" ON public.tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy: Staff can update status of their own tasks
CREATE POLICY "Staff can update their own task status" ON public.tasks
  FOR UPDATE
  USING (
    assigned_staff_id = auth.uid()
  )
  WITH CHECK (
    assigned_staff_id = auth.uid()
  );

-- Policy: Admins can delete tasks
CREATE POLICY "Admins can delete tasks" ON public.tasks
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Create a function to get task statistics
CREATE OR REPLACE FUNCTION get_task_statistics(staff_id_param uuid DEFAULT NULL)
RETURNS TABLE (
  total_tasks bigint,
  pending_tasks bigint,
  in_progress_tasks bigint,
  completed_tasks bigint,
  cancelled_tasks bigint,
  overdue_tasks bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::bigint as total_tasks,
    COUNT(*) FILTER (WHERE status = 'pending')::bigint as pending_tasks,
    COUNT(*) FILTER (WHERE status = 'in_progress')::bigint as in_progress_tasks,
    COUNT(*) FILTER (WHERE status = 'completed')::bigint as completed_tasks,
    COUNT(*) FILTER (WHERE status = 'cancelled')::bigint as cancelled_tasks,
    COUNT(*) FILTER (WHERE status != 'completed' AND due_date < NOW())::bigint as overdue_tasks
  FROM public.tasks
  WHERE (staff_id_param IS NULL OR assigned_staff_id = staff_id_param);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON public.tasks TO authenticated;
GRANT EXECUTE ON FUNCTION get_task_statistics TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE public.tasks IS 'Stores task assignments for waste management staff';
COMMENT ON COLUMN public.tasks.id IS 'Unique identifier for the task';
COMMENT ON COLUMN public.tasks.title IS 'Short title of the task';
COMMENT ON COLUMN public.tasks.description IS 'Detailed description of the task';
COMMENT ON COLUMN public.tasks.trashcan_id IS 'Reference to the trashcan associated with this task (optional)';
COMMENT ON COLUMN public.tasks.assigned_staff_id IS 'Reference to the staff member assigned to this task';
COMMENT ON COLUMN public.tasks.created_by_admin_id IS 'Reference to the admin who created this task';
COMMENT ON COLUMN public.tasks.status IS 'Current status: pending, in_progress, completed, or cancelled';
COMMENT ON COLUMN public.tasks.priority IS 'Priority level: low, medium, high, or urgent';
COMMENT ON COLUMN public.tasks.due_date IS 'Deadline for task completion';
COMMENT ON COLUMN public.tasks.started_at IS 'Timestamp when the task was started';
COMMENT ON COLUMN public.tasks.completed_at IS 'Timestamp when the task was completed';
COMMENT ON COLUMN public.tasks.completion_notes IS 'Notes added upon task completion';
COMMENT ON COLUMN public.tasks.estimated_duration IS 'Estimated time to complete the task (in minutes)';

-- Insert some sample tasks for testing (optional - comment out for production)
-- Note: Replace the UUIDs with actual user and trashcan IDs from your database

/*
-- Example: Create a sample task
INSERT INTO public.tasks (
  title,
  description,
  assigned_staff_id,
  created_by_admin_id,
  priority,
  status,
  due_date,
  estimated_duration
) VALUES (
  'Empty Trashcan at Main Gate',
  'The trashcan at the main gate is full and needs to be emptied urgently.',
  (SELECT id FROM public.users WHERE role = 'staff' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'high',
  'pending',
  NOW() + INTERVAL '2 hours',
  30
);
*/

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Tasks table created successfully!';
  RAISE NOTICE '✅ Indexes created for optimal performance';
  RAISE NOTICE '✅ Row Level Security enabled';
  RAISE NOTICE '✅ RLS Policies configured';
  RAISE NOTICE '✅ Helper functions created';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Verify the table was created: SELECT * FROM public.tasks;';
  RAISE NOTICE '2. Test task creation from your Flutter app';
  RAISE NOTICE '3. Verify RLS policies work correctly';
END $$;

