# Supabase Database Migrations

## Quick Start

### 1. Run the Migration

Execute the migration in your Supabase SQL Editor:

```sql
-- Copy and paste the contents of 20250122_complete_schema.sql
```

Or use the Supabase CLI:

```bash
supabase db reset
```

### 2. Default Admin Account

After running the migration, you can log in with:

- **Email**: `admin@ssu.edu.ph`
- **Password**: `admin123`

⚠️ **IMPORTANT**: Change this password immediately after first login!

## Database Schema Overview

### Tables

1. **users** - User accounts (Admin and Staff)
2. **trashcans** - Smart trashcan devices
3. **tasks** - Work assignments
4. **notifications** - System notifications
5. **activity_logs** - Audit trail
6. **system_settings** - App configuration

### Features Implemented

#### User Management (Admin Only)
- ✅ Create staff accounts
- ✅ Edit user details
- ✅ Delete users
- ✅ View all users
- ✅ Activate/deactivate users

#### Trashcan Management (Admin)
- ✅ Add new trashcans
- ✅ Edit trashcan details
- ✅ Delete trashcans
- ✅ View all trashcans
- ✅ Monitor fill levels
- ✅ Track maintenance status

#### Task Management
- ✅ Create tasks (Admin)
- ✅ Assign tasks to staff
- ✅ Update task status (Staff & Admin)
- ✅ Complete tasks
- ✅ Cancel tasks

#### Notifications
- ✅ Auto-notification when trashcan is full
- ✅ Task assignment notifications
- ✅ Mark as read/unread
- ✅ Priority levels

#### Security
- ✅ Row Level Security (RLS) enabled
- ✅ Role-based access control
- ✅ Activity logging
- ✅ Secure authentication

## Row Level Security (RLS) Policies

### Users Table
- Users can view their own profile
- Admins can view, create, update, and delete all users
- Users can update their own profile

### Trashcans Table
- All authenticated users can view trashcans
- Only admins can create, update, and delete trashcans
- Staff can update trashcan status

### Tasks Table
- All authenticated users can view tasks
- Staff can only view their assigned tasks
- Admins can create, update, and delete all tasks
- Staff can update their assigned tasks

### Notifications Table
- Users can view and update their own notifications
- System can create notifications for any user

## Useful SQL Queries

### Create a New Staff Account

```sql
-- First, create the auth user (do this in Supabase Auth or use the API)
-- Then insert the user record:

INSERT INTO users (
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position
)
VALUES (
  'user-uuid-from-auth',
  'staff@ssu.edu.ph',
  'Staff Name',
  '+639123456789',
  'staff',
  'Maintenance',
  'Utility Staff'
);
```

### Add a New Trashcan

```sql
INSERT INTO trashcans (
  name,
  location,
  latitude,
  longitude,
  device_id,
  sensor_type
)
VALUES (
  'SSU Main Building',
  'Main Campus',
  11.2431,
  124.9908,
  'TC-001',
  'Ultrasonic'
);
```

### Create a Task

```sql
INSERT INTO tasks (
  title,
  description,
  trashcan_id,
  assigned_staff_id,
  created_by_admin_id,
  priority,
  due_date
)
VALUES (
  'Empty Trashcan #1',
  'Main building trashcan is full',
  'trashcan-uuid',
  'staff-uuid',
  'admin-uuid',
  'urgent',
  NOW() + INTERVAL '4 hours'
);
```

### Get Dashboard Statistics

```sql
SELECT get_admin_dashboard_stats();
```

### Get User Statistics

```sql
SELECT get_user_stats('user-uuid');
```

### Mark All Notifications as Read

```sql
UPDATE notifications
SET is_read = true, read_at = NOW()
WHERE user_id = 'user-uuid' AND is_read = false;
```

### Get Full Trashcans

```sql
SELECT * FROM trashcans
WHERE status = 'full'
ORDER BY last_updated_at DESC;
```

### Get Pending Tasks for a Staff Member

```sql
SELECT 
  t.*,
  tc.name as trashcan_name,
  tc.location as trashcan_location
FROM tasks t
LEFT JOIN trashcans tc ON t.trashcan_id = tc.id
WHERE t.assigned_staff_id = 'staff-uuid'
  AND t.status = 'pending'
ORDER BY t.priority DESC, t.due_date ASC;
```

### Get Recent Activity

```sql
SELECT 
  al.*,
  u.name as user_name,
  u.email as user_email
FROM activity_logs al
LEFT JOIN users u ON al.user_id = u.id
ORDER BY al.created_at DESC
LIMIT 50;
```

## Triggers and Automation

### Auto-Update Trashcan Status
When fill_level is updated, the status automatically changes:
- `fill_level >= 0.8` → status = 'full'
- `fill_level >= 0.4` → status = 'half'
- `fill_level < 0.4` → status = 'empty'

### Auto-Create Notifications
When a trashcan becomes full, a notification is automatically created.

### Activity Logging
All user actions can be logged automatically (implement as needed).

## API Usage Examples

### Using Supabase Client in Flutter

```dart
// Get all trashcans
final response = await supabase.from('trashcans').select();

// Create a new staff account
await supabase.from('users').insert({
  'email': 'staff@ssu.edu.ph',
  'name': 'New Staff',
  'role': 'staff',
  'is_active': true,
});

// Update trashcan status
await supabase.from('trashcans')
  .update({'fill_level': 0.85})
  .eq('id', trashcanId);

// Get user's tasks
final tasks = await supabase
  .from('tasks')
  .select('*, trashcans(*)')
  .eq('assigned_staff_id', userId)
  .order('due_date');

// Mark notification as read
await supabase.from('notifications')
  .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
  .eq('id', notificationId);
```

## Troubleshooting

### Issue: Cannot insert/update/delete data
**Solution**: Make sure Row Level Security policies are properly set up and you're authenticated as the correct user type.

### Issue: Admin account not working
**Solution**: 
1. Check if the user exists in `auth.users` table
2. Verify the user record exists in `users` table with `role = 'admin'`
3. Reset password if needed

### Issue: Triggers not firing
**Solution**: Check trigger configuration and function definitions.

## Security Best Practices

1. **Change Default Password**: Change the admin password immediately
2. **Use Environment Variables**: Store Supabase credentials securely
3. **Enable 2FA**: Enable two-factor authentication for admin accounts
4. **Regular Backups**: Set up automated database backups
5. **Monitor Logs**: Regularly check activity logs for suspicious activity
6. **Update RLS Policies**: Review and update RLS policies as needed

## Maintenance

### Backup Database
```bash
supabase db dump -f backup.sql
```

### Reset Database
```bash
supabase db reset
```

### Check Database Status
```sql
SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
```

## Support

For issues or questions:
1. Check the Supabase documentation
2. Review the SQL migration file
3. Check application logs
4. Contact system administrator

---

Last Updated: January 22, 2025

