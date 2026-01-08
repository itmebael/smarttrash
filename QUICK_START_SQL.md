# 🚀 Quick Start - SQL Setup

Run these 3 SQL scripts in **Supabase SQL Editor** (in order):

---

## 📝 Step 1: Main Database Schema
**File:** `supabase/QUICK_SETUP.sql`

**What it does:**
- Creates all tables (users, trashcans, smart_bin, tasks, reports, etc.)
- Sets up Row Level Security policies
- Creates triggers and helper functions

**Run time:** ~5 seconds

---

## 📝 Step 2: Staff Creation Function
**File:** `supabase/CREATE_STAFF_FUNCTION.sql`

**What it does:**
- Creates the `create_staff_account` function
- Allows admin to create staff accounts via RPC
- Handles admin permission checks

**Run time:** ~1 second

---

## 📝 Step 3: Hardcoded Admin Setup
**File:** `supabase/SETUP_HARDCODED_ADMIN.sql`

**What it does:**
- Creates the hardcoded admin in database
- Links admin to fixed UUID: `00000000-0000-0000-0000-000000000001`
- Allows hardcoded login to work with online data

**Run time:** ~1 second

---

## ✅ How to Run

### Option A: Copy-Paste Each File
1. Open Supabase Dashboard → **SQL Editor**
2. Click **"New Query"**
3. Copy entire contents of `QUICK_SETUP.sql`
4. Paste and click **"Run"**
5. Wait for success message
6. Repeat for the other 2 files

### Option B: Run All at Once
1. Open Supabase Dashboard → **SQL Editor**
2. Click **"New Query"**
3. Paste this:

```sql
-- Run all 3 scripts in order
-- Copy the contents of each file below:

-- 1. QUICK_SETUP.sql
[paste contents here]

-- 2. CREATE_STAFF_FUNCTION.sql
[paste contents here]

-- 3. SETUP_HARDCODED_ADMIN.sql
[paste contents here]
```

4. Click **"Run"**

---

## 🎉 Success Messages

After running all scripts, you should see:

```
✅ Database setup complete!
✅ Staff creation function installed!
✅ HARDCODED ADMIN CREATED IN DATABASE!

You can now:
1. Log in with: admin@ssu.edu.ph / admin123
2. Create staff accounts that save online
3. All data persists in Supabase
```

---

## 🔧 If Something Goes Wrong

### Error: "relation already exists"
**Meaning:** Tables already exist
**Solution:** Either:
- Skip QUICK_SETUP.sql (already ran before)
- Or drop tables first with: `DROP TABLE IF EXISTS [table_name] CASCADE;`

### Error: "function already exists"
**Meaning:** Function already created
**Solution:** The scripts already handle this with `DROP FUNCTION IF EXISTS`

### Error: "duplicate key value violates unique constraint"
**Meaning:** Admin already exists in database
**Solution:** This is OK! The script uses `ON CONFLICT DO UPDATE`

---

## ⏱️ Total Time: ~10 seconds

Once done, you're ready to:
1. Start Flutter app
2. Log in with `admin@ssu.edu.ph` / `admin123`
3. Create staff accounts that save online!

---

## 📂 File Locations

All SQL files are in the `supabase/` folder:
- `supabase/QUICK_SETUP.sql`
- `supabase/CREATE_STAFF_FUNCTION.sql`
- `supabase/SETUP_HARDCODED_ADMIN.sql`


















