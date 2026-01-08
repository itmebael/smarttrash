# 🎯 Create Admin Account - Visual Guide

SQL can't directly insert into `auth.users` - you need to use the Supabase Dashboard first, then run SQL to link it.

---

## 🔴 Why SQL Alone Doesn't Work

```sql
-- ❌ This doesn't work in SQL Editor:
INSERT INTO auth.users (email, password) VALUES (...);
-- Reason: auth.users requires special authentication permissions
```

**Solution**: Create user via Dashboard UI, then link with SQL ✅

---

## ✅ Correct Method (2 Steps)

### 📍 STEP 1: Create Auth User (Dashboard)

1. **Open your Supabase project**
   - URL: https://ssztyskjcoilweqmheef.supabase.co
   
2. **Navigate to Authentication**
   - Click **"Authentication"** in left sidebar
   - Click **"Users"** tab
   
3. **Add New User**
   - Click **"Add User"** button (green button, top right)
   
4. **Fill in the form:**
   ```
   Email: admin@ssu.edu.ph
   Password: admin123
   ```
   
5. **⚠️ IMPORTANT: Enable "Auto Confirm User"**
   - Look for checkbox: "Auto Confirm User"
   - ✅ Check this box!
   - This skips email verification
   
6. **Create**
   - Click **"Create User"** button
   - You should see the user appear in the list

---

### 📍 STEP 2: Link to Database (SQL)

1. **Go to SQL Editor**
   - Click **"SQL Editor"** in left sidebar
   - Click **"New Query"**

2. **Copy and paste this SQL:**

```sql
-- Check if auth user exists
DO $$
DECLARE
  auth_user_id UUID;
BEGIN
  SELECT id INTO auth_user_id
  FROM auth.users
  WHERE email = 'admin@ssu.edu.ph';

  IF auth_user_id IS NULL THEN
    RAISE EXCEPTION 'Auth user not found! Create it in Dashboard first.';
  ELSE
    RAISE NOTICE 'Auth user found: %', auth_user_id;
  END IF;
END $$;

-- Link to public.users table
INSERT INTO public.users (
  id, 
  email, 
  name, 
  phone_number,
  role, 
  is_active
)
SELECT 
  id,
  email,
  'System Administrator',
  '+639123456789',
  'admin',
  true
FROM auth.users 
WHERE email = 'admin@ssu.edu.ph'
ON CONFLICT (id) 
DO UPDATE SET 
  role = 'admin', 
  is_active = true;

-- Verify
SELECT id, email, name, role, is_active 
FROM public.users 
WHERE email = 'admin@ssu.edu.ph';
```

3. **Run the query**
   - Click **"Run"** or press `Ctrl+Enter`
   - You should see: ✅ Success message with user details

---

## 🧪 Test Login

1. **Restart your Flutter app**
2. **Try logging in:**
   - Email: `admin@ssu.edu.ph`
   - Password: `admin123`
3. **Expected result:** Successfully logs in and redirects to Admin Dashboard

---

## 🔧 Troubleshooting

### Error: "Auth user not found"
**Problem:** You didn't complete STEP 1
**Solution:** Go back and create the user in Dashboard > Authentication > Users

### Error: "Auto confirm failed" / Email not verified
**Problem:** You forgot to enable "Auto Confirm User"
**Solution:** 
1. Delete the user in Dashboard
2. Create again with "Auto Confirm User" enabled

### Error: "Role not found" / "Not authorized"
**Problem:** SQL in STEP 2 didn't run successfully
**Solution:** Run the SQL again

### Error: "Invalid login credentials"
**Problem:** Wrong password or user doesn't exist
**Solution:** Double-check:
- Email is exactly: `admin@ssu.edu.ph`
- Password is exactly: `admin123`
- User exists in Dashboard > Authentication > Users

---

## 📦 Alternative: Use Pre-Made SQL File

I've created a step-by-step SQL file for you:

**File:** `supabase/CREATE_ADMIN_STEP_BY_STEP.sql`

Just:
1. Do STEP 1 above (create user in Dashboard)
2. Copy the entire contents of `CREATE_ADMIN_STEP_BY_STEP.sql`
3. Paste in SQL Editor
4. Run it

---

## 🎉 Success Indicators

You'll know it worked when you see:

### In SQL Editor:
```
✅ Auth user found with ID: [some-uuid]
✅ ADMIN ACCOUNT CREATED SUCCESSFULLY!
Email: admin@ssu.edu.ph
Role: admin
```

### In Flutter App:
```
✅ Supabase auth successful!
✅ LOGIN SUCCESSFUL
User role: UserRole.admin
```

---

## 📝 Summary

**Why we need 2 steps:**
- `auth.users` = Supabase authentication (handled by Dashboard UI)
- `public.users` = Your app's user data (handled by SQL)

Both tables need to have the same `id` (UUID) for the admin user!

The Dashboard creates the auth user, then SQL links it to your database. 🔗

