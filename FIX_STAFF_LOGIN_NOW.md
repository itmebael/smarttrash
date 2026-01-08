# 🔧 FIX: Staff Supabase Login - Action Steps

## Problem
Staff login showing "Invalid email or password"

## Root Cause
Staff user not created in Supabase Auth

## Solution: 3 Simple Steps

---

## Step 1: Open Supabase Console
```
Go to: https://app.supabase.com/project/ssztyskjcoilweqmheef
```

---

## Step 2: Create Staff User

### Method A: GUI (Easiest)
```
1. Click: Authentication → Users
2. Click: Add user
3. Enter:
   Email: staff@ssu.edu.ph
   Password: staff123
4. Click: Create user
5. Verify: Email shows in users list
```

### Method B: SQL (Fastest)
```
1. Go to: SQL Editor
2. Paste this and run:

INSERT INTO public.users (
  email, name, phone_number, role, 
  department, position, is_active
) VALUES (
  'staff@ssu.edu.ph', 'Staff Member', 
  '+639123456789', 'staff',
  'Sanitation Department', 'Collection Staff', true
) ON CONFLICT (email) DO NOTHING;
```

---

## Step 3: Test Login
```
In your app:
  Email: staff@ssu.edu.ph
  Password: staff123
  
Result: ✅ Staff Dashboard opens
```

---

## That's It! 🎉

The login will now work with Supabase authentication.

---

## If Still Not Working

### Quick Debug
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for error messages
4. Try logging in again
5. Report any red errors

### Common Fixes
```
❌ "Invalid email or password"
   → User not in Supabase Auth yet
   → Run Step 2 above

❌ "Database connection not available"
   → Supabase not initialized
   → Check internet connection
   → Try hard refresh (Ctrl+Shift+R)

❌ "User found but data load failed"
   → User in Auth but not in public.users
   → Run the INSERT SQL from Step 2
```

---

## Full Setup (If Starting Fresh)

### Complete SQL to Run
```sql
-- 1. Create table (if not exists)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  phone_number text,
  role text CHECK (role IN ('admin', 'staff')),
  department text,
  position text,
  is_active boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- 2. Add staff
INSERT INTO public.users (email, name, role, department, position, is_active)
VALUES ('staff@ssu.edu.ph', 'Staff Member', 'staff', 'Sanitation Department', 'Collection Staff', true)
ON CONFLICT DO NOTHING;

-- 3. Verify
SELECT * FROM public.users WHERE email = 'staff@ssu.edu.ph';
```

---

## Verify It Works

### Check 1: User in Auth
```
Go to: Authentication → Users
Look for: staff@ssu.edu.ph
Status should be: Confirmed
```

### Check 2: User in Database
```
Go to: SQL Editor
Run: SELECT * FROM public.users WHERE email = 'staff@ssu.edu.ph';
Should return 1 row
```

### Check 3: Login Works
```
Try login with:
  staff@ssu.edu.ph
  staff123
  
Should see: Staff Dashboard ✅
```

---

## Done! 🚀

Staff authentication is now set up and working!

**Next time:**
```
Email: staff@ssu.edu.ph
Password: staff123
→ Opens Staff Dashboard automatically
```

