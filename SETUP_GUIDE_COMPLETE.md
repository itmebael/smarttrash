# 📋 Complete Database Setup Guide

## 🎯 Overview

This guide will help you set up all the required tables and data in Supabase for the EcoWaste Manager app to work fully.

---

## 📊 Tables to Create

1. **users** - User accounts (admin, staff)
2. **trashcans** - Smart bins/trash containers
3. **tasks** - Tasks assigned to staff

---

## 🚀 Step-by-Step Setup

### Step 1: Create Users Table

**File:** `supabase/CREATE_USERS_TABLE.sql`

```sql
-- Already exists! Check if it's created in your Supabase
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_name = 'users' AND table_schema = 'public';
```

**Expected Result:** 1 (means table exists)

---

### Step 2: Create Trashcans Table

**File:** `supabase/CREATE_TRASHCANS_TABLE.sql`

**Steps:**
1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `CREATE_TRASHCANS_TABLE.sql`
4. Paste it in the SQL Editor
5. Click **Run**
6. Wait for success message

**Expected Output:**
```
✅ Trashcans table created successfully!
✅ 4 indexes created
✅ RLS policies enabled
```

---

### Step 3: Create Tasks Table

**File:** `supabase/CREATE_TASKS_TABLE.sql`

**Steps:**
1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `CREATE_TASKS_TABLE.sql`
4. Paste it in the SQL Editor
5. Click **Run**
6. Wait for success message

**Expected Output:**
```
✅ Tasks table created successfully!
✅ 6 indexes created
✅ Foreign keys linked to users and trashcans
✅ RLS policies enabled
```

---

### Step 4: Insert Sample Trashcans

**File:** `supabase/INSERT_SAMPLE_TRASHCANS.sql`

**Steps:**
1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `INSERT_SAMPLE_TRASHCANS.sql`
4. Paste it in the SQL Editor
5. Click **Run**

**Expected Output:**
```
✅ 10 sample trashcans inserted
✅ Distributed across SSU Campus
✅ With coordinates and sensor data
✅ Ready for use
```

---

### Step 5: Insert Staff User

**File:** `supabase/ADD_JULLS_USER.sql`

**Steps:**
1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `ADD_JULLS_USER.sql`
4. Paste it in the SQL Editor
5. Click **Run**

**Expected Output:**
```
✅ Staff user (julls@gmail.com) added to database
✅ Role: staff
✅ Ready for authentication
```

---

### Step 6: Insert Sample Tasks

**File:** `supabase/INSERT_SAMPLE_TASKS.sql`

**Steps:**
1. Go to: **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `INSERT_SAMPLE_TASKS.sql`
4. Paste it in the SQL Editor
5. Click **Run**

**Expected Output:**
```
✅ 5 sample tasks inserted
✅ Assigned to: julls@gmail.com
✅ Task statuses: pending (2), in_progress (1), completed (2)
✅ Linked to trashcans
```

---

## 📋 Database Schema After Setup

### Users Table
```
├─ id (UUID)
├─ email (TEXT, unique)
├─ name (TEXT)
├─ role (TEXT: 'admin' or 'staff')
├─ phone_number (TEXT)
├─ department, position, etc.
└─ is_active (BOOLEAN)
```

### Trashcans Table
```
├─ id (UUID)
├─ name (TEXT)
├─ location (TEXT)
├─ latitude, longitude (NUMERIC)
├─ status (TEXT: empty, half, full, maintenance)
├─ fill_level (0.0 - 1.0)
├─ device_id, sensor_type (TEXT)
├─ battery_level (0-100)
└─ is_active (BOOLEAN)
```

### Tasks Table
```
├─ id (UUID)
├─ title (TEXT)
├─ description (TEXT)
├─ status (TEXT: pending, in_progress, completed, cancelled)
├─ priority (TEXT: low, medium, high, urgent)
├─ assigned_staff_id (FK → users)
├─ trashcan_id (FK → trashcans)
├─ created_by_admin_id (FK → users)
├─ created_at, updated_at, due_date, completed_at
└─ completion_notes (TEXT)
```

---

## ✅ Verification Checklist

After completing all steps, verify in Supabase:

### Check Tables Exist
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Should show:
```
✅ users
✅ trashcans
✅ tasks
```

### Check Sample Data
```sql
-- Check trashcans count
SELECT COUNT(*) as trashcans_count FROM public.trashcans;
-- Expected: 10

-- Check staff user
SELECT email, role FROM public.users WHERE email = 'julls@gmail.com';
-- Expected: julls@gmail.com | staff

-- Check tasks count
SELECT COUNT(*) as tasks_count FROM public.tasks;
-- Expected: 5

-- Check task statistics
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
  SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed
FROM public.tasks;
-- Expected: total: 5, pending: 2, in_progress: 1, completed: 2
```

---

## 🧪 Test the Setup

### Test 1: Login as Staff
```
Email: julls@gmail.com
Password: julls@gmail.com
```

Expected: ✅ Login successful → Redirected to staff dashboard

### Test 2: View Dashboard
After login, dashboard should show:
```
✅ My Work Overview
   - Tasks Pending: 2
   - Completed Today: 2
   - In Progress: 1
   - Total Assigned: 5

✅ My Tasks section
   - Lists the 5 sample tasks

✅ Recent Activity section
   - Shows recent task updates
```

### Test 3: View Map
Navigate to Map tab:
```
✅ Should see 10 trashcan markers on map
✅ Each marker shows bin name and location
✅ Can click on markers to see details
```

---

## 🚨 Troubleshooting

### Issue: Tables Already Exist
**Solution:** Drop and recreate
```sql
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.trashcans CASCADE;
-- Then re-run CREATE scripts
```

### Issue: Foreign Key Constraint Error
**Solution:** Ensure users table exists first
```sql
SELECT COUNT(*) FROM public.users;
-- If 0, create users table first
```

### Issue: RLS Policy Error
**Solution:** Disable RLS for testing
```sql
ALTER TABLE public.trashcans DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
```

### Issue: Tasks Don't Show in Dashboard
**Solution:** Verify data
```sql
SELECT * FROM public.tasks 
WHERE assigned_staff_id = (SELECT id FROM public.users WHERE email = 'julls@gmail.com');
```

---

## 📁 Files Created

```
supabase/
├─ CREATE_USERS_TABLE.sql              (Already exists)
├─ CREATE_TRASHCANS_TABLE.sql          (NEW)
├─ CREATE_TASKS_TABLE.sql              (NEW)
├─ INSERT_SAMPLE_TRASHCANS.sql         (NEW)
├─ INSERT_SAMPLE_TASKS.sql             (NEW)
└─ ADD_JULLS_USER.sql                  (Already exists)
```

---

## 🎯 Summary

| Step | File | Action | Status |
|------|------|--------|--------|
| 1 | CREATE_TRASHCANS_TABLE.sql | Create table | 🔴 TODO |
| 2 | CREATE_TASKS_TABLE.sql | Create table | 🔴 TODO |
| 3 | INSERT_SAMPLE_TRASHCANS.sql | Add 10 bins | 🔴 TODO |
| 4 | ADD_JULLS_USER.sql | Add staff user | 🔴 TODO |
| 5 | INSERT_SAMPLE_TASKS.sql | Add 5 tasks | 🔴 TODO |
| 6 | Test Dashboard | Login & verify | 🔴 TODO |

---

## 🚀 Quick Setup (Copy-Paste Order)

1. **First:** `CREATE_TRASHCANS_TABLE.sql`
2. **Second:** `CREATE_TASKS_TABLE.sql`
3. **Third:** `INSERT_SAMPLE_TRASHCANS.sql`
4. **Fourth:** `ADD_JULLS_USER.sql` (if not already done)
5. **Fifth:** `INSERT_SAMPLE_TASKS.sql`

**Total Time:** ~5 minutes

---

## ✨ After Setup

Your app will have:
✅ 10 sample trashcans on the map
✅ 1 staff user (julls@gmail.com)
✅ 5 sample tasks assigned to staff
✅ Dashboard showing real database data
✅ Fully functional staff management system

**Ready to test!** 🎉

