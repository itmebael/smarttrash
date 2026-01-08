# Staff Database Integration - Quick Start Guide

## What's New

✅ Staff data now stores in Supabase `users` table  
✅ Staff dashboard shows logged-in user's information  
✅ New Supabase staff service for database operations  
✅ New Riverpod providers for reactive data  

## Steps to Get Started

### 1. Verify Database Schema
Ensure the database migrations have been run. The `users` table should exist with all required fields:

```bash
# Check if migrations are applied
# Go to Supabase SQL Editor: https://app.supabase.com/project/ssztyskjcoilweqmheef/editor
# Run: SELECT * FROM users;
```

### 2. Test Staff Registration

**Hardcoded Test Account:**
```
Email: staff@ssu.edu.ph
Password: staff123
```

This account is configured to login without the database for testing purposes.

### 3. Create Staff Members

**Option A: Via Staff Register Page**
1. Click "Register as Staff"
2. Fill in email, password, name, phone
3. Staff data auto-saves to database

**Option B: Via Admin Dashboard (Create Staff Dialog)**
1. Login as admin
2. Go to Staff Management
3. Click "Add Staff"
4. Fill all information (including department, position, etc.)
5. Click "Create Staff"

**Option C: Programmatically**
```dart
bool success = await SupabaseStaffService.createStaff(
  email: 'john.doe@example.com',
  name: 'John Doe',
  phoneNumber: '+1234567890',
  department: 'Sanitation',
  position: 'Collection Staff',
  password: 'SecurePass123',
);

if (success) {
  print('Staff created successfully!');
}
```

### 4. View Staff in Dashboard

**For Staff Member:**
1. Login with staff credentials
2. Staff dashboard shows their name and department
3. Tasks assigned to them display automatically

**For Admin:**
1. Login as admin
2. Go to Staff Management page
3. See all staff members with their details
4. Can edit, deactivate, or delete staff

### 5. Query Staff Data

**Get All Staff:**
```dart
List<UserModel> staff = await SupabaseStaffService.getAllStaff();
staff.forEach((member) {
  print('${member.name} - ${member.department}');
});
```

**Get Active Staff Only:**
```dart
List<UserModel> active = await SupabaseStaffService.getActiveStaff();
```

**Search Staff:**
```dart
List<UserModel> results = await SupabaseStaffService.searchStaff('john');
```

**Get Staff Statistics:**
```dart
Map<String, int> stats = await SupabaseStaffService.getStaffStatistics();
print('Total: ${stats['total']}');
print('Active: ${stats['active']}');
print('Inactive: ${stats['inactive']}');
```

### 6. Use Riverpod Providers in UI

**Watch all staff (with reactive updates):**
```dart
class StaffListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(allStaffProvider);
    
    return staffAsync.when(
      data: (staff) => ListView.builder(
        itemCount: staff.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(staff[index].name),
          subtitle: Text(staff[index].department ?? 'N/A'),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
```

**Get staff statistics:**
```dart
final statsAsync = ref.watch(staffStatsProvider);

statsAsync.when(
  data: (stats) => Text('Total staff: ${stats['total']}'),
  loading: () => const CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

## File Structure

```
lib/
├── core/
│   ├── services/
│   │   └── supabase_staff_service.dart      (NEW)
│   └── providers/
│       └── staff_provider.dart              (NEW)
├── features/
│   └── dashboard/
│       └── presentation/
│           └── pages/
│               └── staff_dashboard_page.dart (UPDATED)
└── main.dart
```

## Key Features

### SupabaseStaffService Methods

| Method | Purpose |
|--------|---------|
| `getAllStaff()` | Get all staff members |
| `getActiveStaff()` | Get only active staff |
| `getStaffById(id)` | Get specific staff member |
| `getStaffByDepartment(dept)` | Get staff by department |
| `createStaff(...)` | Create new staff member |
| `updateStaff(...)` | Update staff details |
| `toggleStaffStatus(id)` | Activate/deactivate staff |
| `deleteStaff(id)` | Delete staff member |
| `getStaffStatistics()` | Get stats (total, active, inactive) |
| `searchStaff(query)` | Search staff by name/email/phone |
| `getStaffCount()` | Get total staff count |
| `getActiveStaffCount()` | Get active staff count |

## Database Fields Stored

Each staff member record includes:
- ✅ ID (UUID)
- ✅ Email
- ✅ Name
- ✅ Phone Number
- ✅ Role (staff)
- ✅ Age
- ✅ Address
- ✅ City, State, ZIP Code
- ✅ Department
- ✅ Position
- ✅ Date of Birth
- ✅ Emergency Contact
- ✅ Emergency Phone
- ✅ Active Status
- ✅ Profile Image URL
- ✅ FCM Token (for notifications)
- ✅ Created/Updated timestamps

## Testing Checklist

- [ ] Hardcoded staff account login works
- [ ] New staff registration saves to database
- [ ] Staff dashboard shows logged-in user's name
- [ ] Admin can view all staff members
- [ ] Admin can create new staff
- [ ] Admin can edit staff details
- [ ] Admin can deactivate/reactivate staff
- [ ] Search staff functionality works
- [ ] Statistics show correct counts
- [ ] Staff can view only their assigned tasks

## Troubleshooting

### Issue: Staff not showing in dashboard
**Solution:**
1. Verify user exists in database: `SELECT * FROM users WHERE email='staff@ssu.edu.ph';`
2. Check role is set to 'staff': `SELECT role FROM users WHERE id='...';`
3. Check auth state: Look for debug prints in console

### Issue: Creating staff returns error
**Solution:**
1. Verify email is unique (no duplicate)
2. Check database connection is active
3. Verify Supabase keys in main.dart

### Issue: Performance is slow
**Solution:**
1. Database indexes are auto-created on:
   - email
   - role
   - is_active
2. Consider pagination for large lists

## Next Steps

1. **Import test data** - Use SQL script to import existing staff
2. **Set up notifications** - Configure FCM tokens for staff alerts
3. **Create reports** - Use staff statistics for analytics
4. **Integrate with tasks** - Assign tasks to staff automatically

## Support

For detailed information, see:
- `STAFF_DATABASE_SYSTEM.md` - Complete documentation
- `supabase/migrations/20250122_complete_schema.sql` - Database schema

## Environment Check

Verify setup is correct:

```dart
// In main.dart, you should see:
✅ Supabase initialized successfully!
✅ Database connection verified - Online mode active
✅ User role from database: staff
```

---

**Version:** 1.0  
**Last Updated:** 2025-01-11  
**Status:** Production Ready ✅



