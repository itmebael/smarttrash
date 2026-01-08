# 🚀 Supabase Setup Guide for EcoWaste Management System

## Overview

This guide will help you set up the complete Supabase database for the EcoWaste Management System with all necessary tables, functions, and security policies.

## 📋 What's Included

### Database Tables
- ✅ **users** - Admin and staff accounts
- ✅ **trashcans** - Smart trashcan devices  
- ✅ **tasks** - Work assignments
- ✅ **notifications** - System alerts
- ✅ **activity_logs** - Audit trail
- ✅ **system_settings** - Configuration

### Features Implemented
- ✅ User management (create, edit, delete staff)
- ✅ Trashcan management (add, edit, delete bins)
- ✅ Task assignment and tracking
- ✅ Automated notifications
- ✅ Real-time updates
- ✅ Row Level Security (RLS)
- ✅ Activity logging
- ✅ Performance reports

## 🛠️ Setup Instructions

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click "New Project"
4. Fill in:
   - **Name**: EcoWaste Manager
   - **Database Password**: (save this securely!)
   - **Region**: Choose closest to your location
5. Wait for project to be created (~2 minutes)

### Step 2: Run Database Migrations

1. Open your Supabase project dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the contents of `supabase/migrations/20250122_complete_schema.sql`
5. Paste into the SQL editor
6. Click **Run** or press `Ctrl+Enter`
7. Wait for completion (should see success message)
8. Repeat for `supabase/migrations/20250122_helper_functions.sql`

### Step 3: Create Admin Account

The admin account must be created manually through the Supabase Dashboard.

**Follow the detailed guide**: `supabase/CREATE_ADMIN_ACCOUNT.md`

**Quick Steps**:
1. Go to **Authentication** → **Users** → **Add User**
2. Email: `admin@ssu.edu.ph`, Password: `admin123`
3. Check "Auto Confirm User"
4. Copy the User UUID
5. Run SQL to insert user record (see guide)

### Step 4: Verify Setup

Run this query to verify:

```sql
-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Should see: activity_logs, notifications, system_settings, tasks, trashcans, users
```

Verify admin account was created:

```sql
-- Check auth user
SELECT email FROM auth.users WHERE email = 'admin@ssu.edu.ph';

-- Check user record
SELECT email, name, role FROM users WHERE email = 'admin@ssu.edu.ph';

-- Both should return results with matching email
```

### Step 5: Configure Flutter App

1. Get your Supabase credentials:
   - Go to **Project Settings** → **API**
   - Copy **Project URL**
   - Copy **anon public key**

2. Update `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const ProviderScope(child: EcoWasteManagerApp()));
}
```

3. Create `.env` file (add to `.gitignore`):

```env
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
```

## 🔐 Admin Account

You need to create the admin account manually. See detailed instructions in:
**`supabase/CREATE_ADMIN_ACCOUNT.md`**

**Default Credentials** (after creation):
- **Email**: `admin@ssu.edu.ph`  
- **Password**: `admin123`

⚠️ **CRITICAL**: Change this password immediately after first login!

### How to Change Admin Password

**Option 1: Through App**
1. Login as admin
2. Go to Settings
3. Click "Change Password"
4. Enter new password

**Option 2: Through Supabase Dashboard**
1. Go to **Authentication** → **Users**
2. Find `admin@ssu.edu.ph`
3. Click the three dots → **Reset Password**
4. Send reset email or set new password directly

**Option 3: Using Supabase Auth API**
```dart
await supabase.auth.updateUser(
  UserAttributes(password: 'your-new-strong-password'),
);
```

## 📱 Testing the Setup

### Test 1: Login
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'admin@ssu.edu.ph',
  password: 'admin123',
);
print('Login successful: ${response.user?.email}');
```

### Test 2: Get Dashboard Stats
```dart
final stats = await supabase.rpc('get_admin_dashboard_stats');
print('Dashboard stats: $stats');
```

### Test 3: Create Staff Account
```dart
final staffId = await supabase.rpc('create_staff_account', params: {
  'p_email': 'test.staff@ssu.edu.ph',
  'p_name': 'Test Staff',
  'p_phone': '+639123456789',
  'p_department': 'Maintenance',
  'p_position': 'Utility Staff',
});
print('Created staff: $staffId');
```

### Test 4: Add Trashcan
```dart
final trashcanId = await supabase.rpc('add_trashcan', params: {
  'p_name': 'Test Trashcan',
  'p_location': 'Test Location',
  'p_latitude': 11.2431,
  'p_longitude': 124.9908,
});
print('Created trashcan: $trashcanId');
```

## 🎯 Common Operations

### Create Staff Account (Admin)
```dart
await supabase.rpc('create_staff_account', params: {
  'p_email': 'staff@ssu.edu.ph',
  'p_name': 'Staff Name',
  'p_phone': '+639123456789',
  'p_department': 'Maintenance',
  'p_position': 'Utility Staff',
});
```

### Edit Staff Account (Admin)
```dart
await supabase.rpc('update_user_profile', params: {
  'p_user_id': staffId,
  'p_name': 'Updated Name',
  'p_phone': '+639987654321',
  'p_department': 'New Department',
});
```

### Delete Staff Account (Admin)
```dart
await supabase.rpc('soft_delete_user', params: {
  'p_user_id': staffId,
});
```

### Add Trashcan (Admin)
```dart
await supabase.rpc('add_trashcan', params: {
  'p_name': 'SSU Main Building',
  'p_location': 'Main Campus',
  'p_latitude': 11.2431,
  'p_longitude': 124.9908,
  'p_device_id': 'TC-001',
});
```

### Delete Trashcan (Admin)
```dart
await supabase.rpc('delete_trashcan', params: {
  'p_trashcan_id': trashcanId,
});
```

### Logout
```dart
await supabase.auth.signOut();
```

## 📚 Documentation Files

1. **`supabase/migrations/20250122_complete_schema.sql`**
   - Main database schema
   - All tables, triggers, and RLS policies
   - Default admin account creation

2. **`supabase/migrations/20250122_helper_functions.sql`**
   - Helper functions for common operations
   - User management functions
   - Trashcan management functions
   - Task management functions

3. **`supabase/migrations/README.md`**
   - Detailed migration documentation
   - SQL query examples
   - Troubleshooting guide

4. **`supabase/API_REFERENCE.md`**
   - Complete Flutter integration guide
   - Code examples for all operations
   - Real-time subscription examples

## 🔒 Security Features

### Row Level Security (RLS)
- ✅ Users can only see their own data
- ✅ Admins have full access
- ✅ Staff can only update their tasks
- ✅ All tables protected by RLS policies

### Authentication
- ✅ Email/password authentication
- ✅ Secure password hashing
- ✅ Session management
- ✅ JWT tokens

### Activity Logging
- ✅ All user actions logged
- ✅ IP address tracking
- ✅ User agent recording
- ✅ Audit trail for compliance

## 🐛 Troubleshooting

### Issue: Error "42P10: there is no unique or exclusion constraint matching the ON CONFLICT specification"
**Solution**: This error occurred in the old migration file that tried to insert directly into `auth.users`. The new migration file has been fixed. Simply run the updated migration file without the auth.users insert. Create the admin account manually through the Supabase Dashboard instead (see `supabase/CREATE_ADMIN_ACCOUNT.md`).

### Issue: Cannot login with admin account
**Solution**: 
```sql
-- Check if auth user exists
SELECT * FROM auth.users WHERE email = 'admin@ssu.edu.ph';

-- Check if user record exists
SELECT * FROM users WHERE email = 'admin@ssu.edu.ph';

-- If only auth user exists, insert user record
INSERT INTO users (id, email, name, role, is_active)
VALUES (
  'AUTH_USER_UUID_HERE',
  'admin@ssu.edu.ph',
  'System Administrator',
  'admin',
  true
);
```

### Issue: Permission denied errors
**Solution**: Make sure RLS policies are enabled and user is authenticated

```sql
-- Check RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Should all show 't' for rowsecurity
```

### Issue: Functions not found
**Solution**: Run the helper functions migration

```sql
-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;
```

## 📊 Monitoring

### Check Database Size
```sql
SELECT 
  pg_size_pretty(pg_database_size(current_database())) as size;
```

### Check Table Sizes
```sql
SELECT 
  table_name,
  pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
```

### Check Active Users
```sql
SELECT COUNT(*) as active_users 
FROM users 
WHERE is_active = true;
```

## 🔄 Maintenance

### Regular Cleanup (Run weekly)
```sql
SELECT schedule_maintenance();
```

### Manual Cleanup
```sql
-- Clean old notifications
SELECT cleanup_old_notifications(30);

-- Clean old activity logs
DELETE FROM activity_logs 
WHERE created_at < NOW() - INTERVAL '90 days';
```

### Backup Database
```bash
# Using Supabase CLI
supabase db dump -f backup_$(date +%Y%m%d).sql
```

## 📞 Support

- **Documentation**: Check `supabase/migrations/README.md`
- **API Reference**: See `supabase/API_REFERENCE.md`
- **Supabase Docs**: https://supabase.com/docs
- **Community**: https://github.com/supabase/supabase/discussions

## ✅ Setup Checklist

- [ ] Supabase project created
- [ ] Schema migration run successfully
- [ ] Helper functions migration run successfully
- [ ] Admin account created (see `supabase/CREATE_ADMIN_ACCOUNT.md`)
- [ ] Admin account verified (can see in both auth.users and users table)
- [ ] Admin password changed from default
- [ ] Flutter app configured with Supabase credentials
- [ ] Test login successful
- [ ] Test creating staff account
- [ ] Test adding trashcan
- [ ] Real-time subscriptions working

## 🎉 You're All Set!

Your EcoWaste Management System database is now fully configured with:
- ✅ User management
- ✅ Trashcan tracking
- ✅ Task assignment
- ✅ Notifications
- ✅ Real-time updates
- ✅ Security policies
- ✅ Activity logging

Start building your Flutter app using the API examples in `supabase/API_REFERENCE.md`!

---

**Last Updated**: January 22, 2025  
**Version**: 1.0.0

