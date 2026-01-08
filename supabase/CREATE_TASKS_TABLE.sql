-- =====================================================
-- CREATE TASKS TABLE
-- =====================================================

CREATE TABLE public.tasks (
  id uuid not null default extensions.uuid_generate_v4 (),
  title text not null,
  description text null,
  trashcan_id uuid null,
  assigned_staff_id uuid null,
  created_by_admin_id uuid null,
  status text not null default 'pending'::text,
  priority text not null default 'medium'::text,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  due_date timestamp with time zone null,
  started_at timestamp with time zone null,
  completed_at timestamp with time zone null,
  completion_notes text null,
  estimated_duration integer null,
  
  constraint tasks_pkey primary key (id),
  constraint tasks_assigned_staff_fkey foreign key (assigned_staff_id) references users (id) on delete set null,
  constraint tasks_created_by_admin_fkey foreign key (created_by_admin_id) references users (id) on delete set null,
  constraint tasks_trashcan_fkey foreign key (trashcan_id) references trashcans (id) on delete set null,
  
  constraint tasks_priority_check check (
    (priority = any (array['low'::text, 'medium'::text, 'high'::text, 'urgent'::text]))
  ),
  constraint tasks_status_check check (
    (status = any (array['pending'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text]))
  )
) TABLESPACE pg_default;

-- =====================================================
-- CREATE INDEXES ON TASKS TABLE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_tasks_status 
  ON public.tasks USING btree (status) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tasks_priority 
  ON public.tasks USING btree (priority) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_staff 
  ON public.tasks USING btree (assigned_staff_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tasks_trashcan 
  ON public.tasks USING btree (trashcan_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tasks_due_date 
  ON public.tasks USING btree (due_date) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tasks_created_at 
  ON public.tasks USING btree (created_at) TABLESPACE pg_default;

-- =====================================================
-- CREATE TRIGGER FOR AUTO-UPDATE TIMESTAMP
-- =====================================================

CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON tasks 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ENABLE RLS
-- =====================================================

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CREATE RLS POLICIES
-- =====================================================

-- Allow admin to see all tasks
CREATE POLICY "admin_view_all_tasks" ON public.tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow staff to see their assigned tasks
CREATE POLICY "staff_view_own_tasks" ON public.tasks
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

-- Allow admin to insert tasks
CREATE POLICY "admin_insert_tasks" ON public.tasks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Allow staff to update their tasks
CREATE POLICY "staff_update_own_tasks" ON public.tasks
  FOR UPDATE
  USING (
    assigned_staff_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

-- Tasks table created successfully!
-- ✅ Table: public.tasks
-- ✅ Columns: id, title, description, trashcan_id, assigned_staff_id, created_by_admin_id, status, priority, created_at, updated_at, due_date, started_at, completed_at, completion_notes, estimated_duration
-- ✅ Indexes: status, priority, assigned_staff, trashcan, due_date, created_at
-- ✅ Foreign Keys: users (assigned_staff_id, created_by_admin_id), trashcans (trashcan_id)
-- ✅ RLS Policies: Enabled with admin and staff policies

