# ✅ Supabase Staff Authentication Setup

## Problem
Staff login with database credentials not working. Need to set up Supabase Auth properly.

## Solution
Create staff users in Supabase Auth + database

---

## Step 1: Create Users Table

Run in Supabase SQL Editor:
```sql
-- File: supabase/CREATE_USERS_TABLE.sql
```

Or manually run:
```sql
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  name text NOT NULL,
  phone_number text,
  role text NOT NULL CHECK (role IN ('admin', 'staff')),
  department text,
  position text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
```

---

## Step 2: Create Staff User in Supabase Auth

### Option A: Using Supabase Dashboard

1. **Go to Supabase Console**
   - URL: https://app.supabase.com/project/ssztyskjcoilweqmheef

2. **Go to Authentication → Users**
   - Click "Add user"

3. **Create Staff User**
   ```
   Email: staff@ssu.edu.ph
   Password: staff123
   ```
   - Click "Create user"

4. **Verify**
   - User should appear in users list
   - Status should be "Confirmed"

### Option B: Using SQL (Faster)

Run this SQL in Supabase:

```sql
-- Create staff user in auth.users (Supabase handles this)
-- Then create corresponding record in public.users

INSERT INTO public.users (
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active
) VALUES (
  'staff@ssu.edu.ph',
  'Staff Member',
  '+639123456789',
  'staff',
  'Sanitation Department',
  'Collection Staff',
  true
);
```

---

## Step 3: Verify Setup

### Check Users Table
```sql
SELECT id, email, name, role FROM public.users;
```

Should show:
```
staff@ssu.edu.ph | Staff Member | staff
```

### Check Auth Users
```sql
SELECT email FROM auth.users;
```

Should show:
```
staff@ssu.edu.ph
```

---

## Step 4: Test Supabase Login

Try logging in with:
```
Email: staff@ssu.edu.ph
Password: staff123
```

### If Still Failing:

**Check Console for Errors:**
- Open browser DevTools (F12)
- Go to Console tab
- Look for error messages

**Common Issues:**

1. **User not in Supabase Auth**
   - Solution: Create user in Authentication → Users

2. **User not in public.users table**
   - Solution: Run INSERT SQL above

3. **Email doesn't match**
   - Solution: Make sure exact same email

4. **Password doesn't match**
   - Solution: Reset password or recreate user

---

## Complete Setup Script

Run all these SQL commands in order:

```sql
-- 1. Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  name text NOT NULL,
  phone_number text,
  role text NOT NULL CHECK (role IN ('admin', 'staff')),
  department text,
  position text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- 3. Insert staff user
INSERT INTO public.users (email, name, phone_number, role, department, position, is_active)
VALUES ('staff@ssu.edu.ph', 'Staff Member', '+639123456789', 'staff', 'Sanitation Department', 'Collection Staff', true)
ON CONFLICT (email) DO NOTHING;

-- 4. Verify
SELECT COUNT(*) as total_users FROM public.users;
SELECT * FROM public.users WHERE role = 'staff';
```

---

## Step 5: Update Auth Provider (Optional)

The auth provider already handles Supabase auth at line 153:

```dart
// Try Supabase authentication (database users)
print('🔍 Checking database for user...');

if (_supabase == null) {
  print('❌ Supabase not initialized');
  return false;
}

final response = await _supabase!.auth.signInWithPassword(
  email: email.trim(),
  password: password,
);

if (response.user != null) {
  print('✅ Database authentication success!');
  await _loadUserData(response.user!.id);
  return true;
}
```

This should work automatically once you set up the user in Supabase Auth.

---

## Login Flow with Supabase

```
1. User enters credentials
   Email: staff@ssu.edu.ph
   Password: staff123
   ↓
2. AuthProvider.login() called
   ↓
3. Check hardcoded accounts (fails)
   ↓
4. Try Supabase Auth
   ↓
5. Supabase validates credentials
   ↓
6. If valid, get user ID from Auth
   ↓
7. Load user data from public.users table
   ↓
8. ✅ Login succeeds
   ↓
9. Auth state updates
   ↓
10. Listener checks role
    - If staff → /staff-dashboard
    - If admin → /dashboard
```

---

## Troubleshooting Checklist

- [ ] Supabase project is active
- [ ] Users table created
- [ ] Staff user created in Supabase Auth
- [ ] Staff user record in public.users
- [ ] Email matches exactly
- [ ] Password is correct
- [ ] User is "Confirmed" status
- [ ] No typos in email
- [ ] Try hard refresh (Ctrl+Shift+R)
- [ ] Check browser console for errors

---

## Quick Fix If Still Not Working

### Option 1: Use Hardcoded Credentials
```
Email: staff@ssu.edu.ph
Password: staff123
```
(Already works without any setup)

### Option 2: Use Admin Credentials
```
Email: admin@ssu.edu.ph
Password: admin123
```

### Option 3: Debug Login

Add this to auth_provider.dart after line 162:

```dart
print('📧 Attempting Supabase auth with: $email');
print('🔐 Password: $password');
print('🌐 Supabase initialized: ${_supabase != null}');
```

Then try logging in and check console output.

---

## Success Indicators

If login works:
1. Console shows: `✅ Database authentication success!`
2. No error message on screen
3. ✅ Automatically redirected to **Staff Dashboard**
4. Staff name appears in dashboard

---

## Next Steps

1. **Create Users Table** (if not done)
   - Run: `supabase/CREATE_USERS_TABLE.sql`

2. **Create Staff in Supabase Auth**
   - Go to: Authentication → Users
   - Add: `staff@ssu.edu.ph` / `staff123`

3. **Add Staff to Database**
   - Run INSERT SQL above

4. **Test Login**
   - Email: `staff@ssu.edu.ph`
   - Password: `staff123`

5. **Verify Dashboard**
   - Should see Staff Dashboard
   - Shows staff name and info

---

**Status:** Ready for Supabase Auth Setup 🚀

