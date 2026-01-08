# 🚀 Quick Start - Fixed Version

## What Was the Error?

The error **"42P10: there is no unique or exclusion constraint matching the ON CONFLICT specification"** happened because the migration was trying to insert directly into Supabase's internal `auth.users` table, which is not allowed.

## ✅ Fixed!

The migration file has been updated to remove the problematic code. Now you need to create the admin account manually.

---

## 📝 Updated Setup Steps

### 1. Run the Database Migration

In Supabase SQL Editor, run:

**File**: `supabase/migrations/20250122_complete_schema.sql`

This will create all tables, functions, and security policies. ✅ **This should now work without errors!**

### 2. Run Helper Functions

**File**: `supabase/migrations/20250122_helper_functions.sql`

This adds helper functions for common operations.

### 3. Create Admin Account Manually

**You MUST do this manually - it cannot be automated!**

#### Option A: Supabase Dashboard (Easiest)

1. Go to **Authentication** → **Users**
2. Click **Add User**
3. Enter:
   - Email: `admin@ssu.edu.ph`
   - Password: `admin123`
   - ✅ Check "Auto Confirm User"
4. Click **Create User**
5. **Copy the User UUID** (shown after creation)

6. Go to **SQL Editor** and run (replace UUID):

```sql
INSERT INTO users (
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active
)
VALUES (
  'PASTE_UUID_HERE'::uuid,  -- Paste the UUID from step 5
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  'Administration',
  'System Administrator',
  true
);
```

#### Option B: Using Flutter Code (Alternative)

See full instructions in: **`supabase/CREATE_ADMIN_ACCOUNT.md`**

---

## 🧪 Verify Everything Works

Run this in SQL Editor:

```sql
-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Should show: activity_logs, notifications, system_settings, tasks, trashcans, users

-- Check admin account
SELECT 
  au.email as auth_email,
  u.email as user_email,
  u.name,
  u.role,
  u.is_active
FROM auth.users au
LEFT JOIN users u ON au.id = u.id
WHERE au.email = 'admin@ssu.edu.ph';

-- Should return one row with both emails matching
```

---

## 🎯 Test Login in Flutter

```dart
final response = await supabase.auth.signInWithPassword(
  email: 'admin@ssu.edu.ph',
  password: 'admin123',
);

if (response.user != null) {
  print('✅ Login successful!');
  print('User: ${response.user!.email}');
  
  // Get user details
  final userData = await supabase
    .from('users')
    .select()
    .eq('id', response.user!.id)
    .single();
    
  print('Role: ${userData['role']}');
  print('Name: ${userData['name']}');
} else {
  print('❌ Login failed');
}
```

---

## 📚 Full Documentation

- **Complete Setup Guide**: `SUPABASE_SETUP_GUIDE.md`
- **Create Admin Account**: `supabase/CREATE_ADMIN_ACCOUNT.md`
- **API Reference**: `supabase/API_REFERENCE.md`
- **Migration Details**: `supabase/migrations/README.md`

---

## ⚠️ Important Security Notes

1. **Change the default password** immediately after first login
2. The default password `admin123` is only for initial setup
3. Use a strong password (12+ characters, mix of letters, numbers, symbols)
4. Never commit credentials to Git
5. Use environment variables for sensitive data

---

## ✅ Checklist

- [ ] Run `20250122_complete_schema.sql` migration ✅ No errors!
- [ ] Run `20250122_helper_functions.sql` migration
- [ ] Create admin user in Authentication → Users
- [ ] Insert admin record in users table
- [ ] Verify both records exist and match
- [ ] Test login from Flutter app
- [ ] Change admin password from default

---

## 🆘 Need Help?

### Common Issues:

**Q: Still getting errors when running migration?**  
A: Make sure you're using the UPDATED `20250122_complete_schema.sql` file (the one without the `auth.users` insert).

**Q: Can't login after creating account?**  
A: Check that BOTH the auth user and user record exist with the SAME UUID.

**Q: Permission denied errors?**  
A: RLS policies are working correctly. Make sure you're logged in as admin.

**Q: How do I add staff members?**  
A: After logging in as admin, use the `create_staff_account` function or the UI.

---

## 🎉 You're Ready!

Once you complete the checklist above, your database is fully set up and ready to use with:

- ✅ User management (create/edit/delete staff)
- ✅ Trashcan tracking (add/edit/delete bins)
- ✅ Task assignments
- ✅ Real-time notifications
- ✅ Activity logging
- ✅ Secure authentication

Start building your app! 🚀

---

**Last Updated**: January 22, 2025  
**Status**: ✅ Error Fixed - Ready to Use

