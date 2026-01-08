# 📋 Task Management System Setup Guide

## Overview

The task management system allows administrators to assign tasks to staff members and track their completion. Staff members can view their assigned tasks, update their status, and complete them.

## 🚀 Quick Setup

### Step 1: Run the Database Migration

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file `supabase/migrations/20250124_tasks_table.sql`
4. Copy all the SQL content
5. Paste into the SQL editor
6. Click **Run** or press `Ctrl+Enter`
7. Wait for completion (you should see success messages)

### Step 2: Verify the Setup

Run this query to verify the table was created:

```sql
-- Check if tasks table exists
SELECT * FROM public.tasks;

-- Check indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'tasks';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'tasks';
```

### Step 3: Test the System

1. **Launch the app**
2. **Login as Admin** (admin@ssu.edu.ph)
3. **Create a task:**
   - Click "Assign Task" in the admin dashboard
   - Fill in task details
   - Select a staff member
   - Optionally select a trashcan
   - Choose priority level
   - Set due date
   - Click "Assign Task"
4. **Login as Staff** to see assigned tasks
5. **Update task status** by clicking "Start" or "Complete"

## 📊 Database Schema

### Tasks Table

```sql
CREATE TABLE public.tasks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  trashcan_id uuid REFERENCES trashcans(id),
  assigned_staff_id uuid REFERENCES users(id),
  created_by_admin_id uuid REFERENCES users(id),
  status text DEFAULT 'pending',
  priority text DEFAULT 'medium',
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  due_date timestamp,
  started_at timestamp,
  completed_at timestamp,
  completion_notes text,
  estimated_duration integer
);
```

### Status Values

- `pending` - Task has been created but not started
- `in_progress` - Staff member has started working on the task
- `completed` - Task has been completed
- `cancelled` - Task has been cancelled

### Priority Values

- `low` - Low priority task
- `medium` - Medium priority task (default)
- `high` - High priority task
- `urgent` - Urgent task requiring immediate attention

## 🔐 Security (Row Level Security)

The system uses Supabase Row Level Security (RLS) to ensure data privacy:

### Admin Permissions
- ✅ View all tasks
- ✅ Create tasks
- ✅ Update any task
- ✅ Delete tasks

### Staff Permissions
- ✅ View their own assigned tasks
- ✅ Update status of their own tasks
- ❌ Cannot view other staff tasks
- ❌ Cannot create tasks
- ❌ Cannot delete tasks

## 📱 Features

### For Administrators

1. **Assign Tasks**
   - Create new tasks
   - Assign to specific staff members
   - Link to specific trashcans
   - Set priority levels
   - Set due dates
   - Estimate task duration

2. **View All Tasks**
   - See all tasks in the system
   - Filter by status (All, Pending, In Progress, Completed)
   - See who each task is assigned to
   - Track task completion

3. **Task Management**
   - Update task details
   - Reassign tasks
   - Cancel tasks
   - View task history

### For Staff Members

1. **View Assigned Tasks**
   - See only their assigned tasks
   - Filter by status
   - View task details
   - See due dates and priorities

2. **Update Task Status**
   - Start tasks (Pending → In Progress)
   - Complete tasks (In Progress → Completed)
   - Add completion notes

3. **Task Information**
   - View task description
   - See associated trashcan
   - Check due dates
   - View estimated duration

## 🎨 UI Components

### Admin Dashboard
- Quick access "Assign Task" button in header
- Task statistics
- Recent tasks widget

### Task Assignment Page
Located at: `lib/features/tasks/presentation/pages/task_assignment_page.dart`

Features:
- Task details form
- Staff member dropdown (loads from database)
- Trashcan dropdown (loads from database)
- Priority selector
- Date and time picker
- Duration estimator

### Tasks Page
Located at: `lib/features/tasks/presentation/pages/tasks_page.dart`

Features:
- Filter tabs (All, Pending, In Progress, Completed)
- Task cards with status chips
- Priority indicators
- Due date countdown
- Action buttons (Start/Complete)
- Pull to refresh

## 🛠️ Technical Implementation

### Service Layer
**File:** `lib/core/services/task_service.dart`

Key methods:
- `getAllTasks()` - Get all tasks (admin)
- `getTasksByStaffId(staffId)` - Get tasks for specific staff
- `createTask()` - Create new task
- `updateTaskStatus()` - Update task status
- `updateTask()` - Update task details
- `deleteTask()` - Delete task
- `getAllStaff()` - Get all staff members
- `getAllTrashcans()` - Get all trashcans
- `getTaskStatistics()` - Get task stats

### Model Layer
**File:** `lib/core/models/task_model.dart`

Key features:
- Aligned with database schema
- Supabase join support
- Status and priority enums
- Helper methods (isOverdue, duration, etc.)
- Legacy compatibility

## 🔄 Real-time Updates

The system supports real-time updates using Supabase's streaming feature:

```dart
// Example: Stream tasks for a staff member
final taskStream = taskService.streamTasks(staffId: userId);
```

This allows the UI to automatically update when:
- New tasks are assigned
- Task status changes
- Tasks are completed
- Tasks are cancelled

## 📈 Statistics and Reporting

The system includes a helper function to get task statistics:

```sql
SELECT * FROM get_task_statistics();
-- Returns: total, pending, in_progress, completed, cancelled, overdue

-- For specific staff:
SELECT * FROM get_task_statistics('staff-user-id');
```

## 🧪 Testing

### Test Cases

1. **Admin Creates Task**
   - Login as admin
   - Navigate to task assignment
   - Fill form and submit
   - Verify task appears in database

2. **Staff Views Tasks**
   - Login as staff
   - Navigate to tasks page
   - Verify only assigned tasks are visible

3. **Staff Updates Task Status**
   - Click "Start" on pending task
   - Verify status changes to "In Progress"
   - Click "Complete"
   - Verify status changes to "Completed"

4. **RLS Security**
   - Staff should not see other staff's tasks
   - Staff should not be able to create tasks
   - Admin should see all tasks

## 🐛 Troubleshooting

### Problem: Tasks not showing up

**Solution:**
1. Check if tasks table exists: `SELECT * FROM public.tasks;`
2. Verify RLS policies are enabled
3. Check user authentication
4. Verify staff_id matches auth.uid()

### Problem: Cannot create tasks

**Solution:**
1. Verify user is admin: `SELECT role FROM users WHERE id = auth.uid();`
2. Check RLS policy for INSERT
3. Verify foreign key constraints (staff and trashcan IDs exist)

### Problem: Staff cannot update task status

**Solution:**
1. Verify task is assigned to the staff member
2. Check RLS policy for UPDATE
3. Ensure staff is authenticated

### Problem: Dropdown lists are empty

**Solution:**
1. Verify staff members exist in database
2. Verify trashcans exist in database
3. Check API service connection
4. Look for errors in console

## 📚 API Reference

### Task Service Methods

```dart
// Get all tasks (admin only)
List<TaskModel> tasks = await taskService.getAllTasks();

// Get tasks for specific staff
List<TaskModel> myTasks = await taskService.getTasksByStaffId(staffId);

// Create new task
TaskModel task = await taskService.createTask(
  title: 'Empty Trashcan',
  description: 'Empty the trashcan at main gate',
  assignedStaffId: staffId,
  createdByAdminId: adminId,
  priority: 'high',
  dueDate: DateTime.now().add(Duration(hours: 2)),
);

// Update task status
TaskModel updatedTask = await taskService.updateTaskStatus(
  taskId: taskId,
  status: 'in_progress',
);

// Get statistics
Map<String, int> stats = await taskService.getTaskStatistics();
print('Total tasks: ${stats['total']}');
```

## 🎯 Best Practices

1. **Always set realistic due dates** - Give staff enough time to complete tasks
2. **Use priority levels appropriately** - Reserve "urgent" for true emergencies
3. **Add completion notes** - Document what was done for future reference
4. **Estimate duration accurately** - Helps with resource planning
5. **Link tasks to trashcans when relevant** - Provides location context

## 🔮 Future Enhancements

Potential features to add:
- [ ] Task recurring schedules
- [ ] Task templates
- [ ] Photo attachments for completion proof
- [ ] Task comments/discussion
- [ ] Task history/audit log
- [ ] Push notifications for new tasks
- [ ] Task analytics dashboard
- [ ] Performance metrics
- [ ] Task dependencies
- [ ] Batch task assignment

## 📞 Support

If you encounter any issues:
1. Check this guide first
2. Review the troubleshooting section
3. Check Supabase dashboard for errors
4. Review console logs in the app
5. Verify database migrations ran successfully

## ✅ Checklist

Before using the task system:
- [ ] Database migration completed
- [ ] Table created successfully
- [ ] Indexes created
- [ ] RLS policies enabled
- [ ] Test admin account works
- [ ] Test staff account works
- [ ] Can create tasks
- [ ] Can view tasks
- [ ] Can update tasks
- [ ] Staff and trashcan dropdowns populate

---

**Last Updated:** January 24, 2025
**Version:** 1.0.0
















