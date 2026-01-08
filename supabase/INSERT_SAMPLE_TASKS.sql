-- =====================================================
-- INSERT SAMPLE TASKS FOR STAFF
-- =====================================================

-- First, get the staff user ID (julls@gmail.com)
-- Then get some trashcan IDs from the database
-- Then insert tasks assigned to that staff

-- IMPORTANT: Run this AFTER:
-- 1. Tasks table is created
-- 2. Trashcans table is created
-- 3. Users table has the staff member (julls@gmail.com)
-- 4. Trashcans table has some data

-- =====================================================
-- INSERT SAMPLE TASKS (adjust IDs as needed)
-- =====================================================

INSERT INTO public.tasks (
  title,
  description,
  trashcan_id,
  assigned_staff_id,
  created_by_admin_id,
  status,
  priority,
  due_date,
  estimated_duration
) VALUES
-- Task 1: Pending task in Main Building
(
  'Empty trash bin in Main Building',
  'The trash bin in the main hallway needs to be emptied. It is currently at 80% capacity.',
  (SELECT id FROM public.trashcans WHERE name = 'Main Building Bin' LIMIT 1),
  (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'pending',
  'high',
  NOW() + INTERVAL '1 day',
  30
),

-- Task 2: In-progress task in Cafeteria
(
  'Replace bag in Cafeteria',
  'Replace the plastic bag in the cafeteria trash bin.',
  (SELECT id FROM public.trashcans WHERE name = 'Cafeteria Bin' LIMIT 1),
  (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'in_progress',
  'medium',
  NOW() + INTERVAL '2 days',
  20
),

-- Task 3: Completed task at Gate
(
  'Check bin at North Gate',
  'Inspect and report the condition of the bin at the north gate.',
  (SELECT id FROM public.trashcans WHERE name = 'North Gate Bin' LIMIT 1),
  (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'completed',
  'low',
  NOW() - INTERVAL '1 day',
  15
),

-- Task 4: Pending task at Parking
(
  'Empty bin at Parking Area',
  'Empty the trash bin located in the parking area near Building B.',
  (SELECT id FROM public.trashcans WHERE name = 'Parking Bin' LIMIT 1),
  (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'pending',
  'medium',
  NOW() + INTERVAL '3 hours',
  25
),

-- Task 5: Completed task at Library
(
  'Maintenance check at Library',
  'Perform maintenance check on the trash bin outside the library.',
  (SELECT id FROM public.trashcans WHERE name = 'Library Bin' LIMIT 1),
  (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'admin' LIMIT 1),
  'completed',
  'low',
  NOW() - INTERVAL '2 days',
  20
)
ON CONFLICT DO NOTHING;

-- =====================================================
-- UPDATE TIMESTAMPS FOR REALISTIC DATA
-- =====================================================

-- Set completed_at for completed tasks
UPDATE public.tasks
SET completed_at = updated_at - INTERVAL '2 hours'
WHERE status = 'completed' AND completed_at IS NULL;

-- Set started_at for in-progress tasks
UPDATE public.tasks
SET started_at = updated_at - INTERVAL '1 hour'
WHERE status = 'in_progress' AND started_at IS NULL;

-- =====================================================
-- VERIFY INSERTION
-- =====================================================

-- Check how many tasks were inserted
SELECT COUNT(*) as "Total Tasks", 
       SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as "Pending",
       SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as "In Progress",
       SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as "Completed"
FROM public.tasks
WHERE assigned_staff_id = (SELECT id FROM public.users WHERE email = 'julls@gmail.com' LIMIT 1);

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

-- Sample tasks inserted successfully!
-- ✅ 5 sample tasks created
-- ✅ Assigned to: julls@gmail.com (staff)
-- ✅ Task statuses: pending (2), in_progress (1), completed (2)
-- ✅ Tasks linked to trashcans and users
-- ✅ Timestamps set automatically

