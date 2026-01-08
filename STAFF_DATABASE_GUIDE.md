# Staff Account Database Guide

## 📊 Fetch Staff Accounts from Database

### Quick SQL Queries

#### 1. **Get All Staff**
```sql
SELECT * FROM public.users WHERE role = 'staff';
```

#### 2. **Get Active Staff Only**
```sql
SELECT * FROM public.users 
WHERE role = 'staff' AND is_active = true;
```

#### 3. **Count Staff**
```sql
SELECT COUNT(*) FROM public.users WHERE role = 'staff';
```

#### 4. **Verify Staff Can Login**
```sql
SELECT 
  u.email,
  u.name,
  u.role,
  u.is_active,
  CASE WHEN au.id IS NOT NULL THEN '✅ Can Login' ELSE '❌ Cannot Login' END
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'staff@ssu.edu.ph';
```

---

## 🚀 Using the Staff Fetch Service (Flutter)

### 1. **Import the Service**
```dart
import 'package:ecowaste_manager_app/core/services/staff_fetch_service.dart';
```

### 2. **Fetch All Staff**
```dart
final staffService = StaffFetchService();
final allStaff = await staffService.getAllStaff();

print('Total staff: ${allStaff.length}');
for (var staff in allStaff) {
  print('${staff.name} - ${staff.email}');
}
```

### 3. **Fetch Active Staff Only**
```dart
final activeStaff = await staffService.getActiveStaff();
print('Active staff: ${activeStaff.length}');
```

### 4. **Get Staff by Email**
```dart
final staff = await staffService.getStaffByEmail('staff@ssu.edu.ph');
if (staff != null) {
  print('Found: ${staff.name}');
  print('Role: ${staff.role}');
  print('Department: ${staff.department}');
}
```

### 5. **Search Staff**
```dart
final results = await staffService.searchStaff('John');
print('Found ${results.length} staff matching "John"');
```

### 6. **Get Staff Summary**
```dart
final summary = await staffService.getStaffSummary();
print('Total: ${summary['total']}');
print('Active: ${summary['active']}');
print('Inactive: ${summary['inactive']}');
```

### 7. **Real-Time Updates**
```dart
staffService.watchStaff().listen((staffList) {
  print('Staff updated! Total: ${staffList.length}');
});
```

---

## 📁 Files Created

1. **`supabase/FETCH_STAFF_ACCOUNTS.sql`**
   - SQL queries to fetch staff from database
   - Verification queries
   - Staff summary functions

2. **`lib/core/services/staff_fetch_service.dart`**
   - Flutter service to fetch staff
   - Real-time updates
   - Search and filter functions

---

## 🔍 Verification Steps

### Step 1: Check if Staff Exists
Run in Supabase:
```sql
SELECT * FROM public.users WHERE email = 'staff@ssu.edu.ph';
```

**Expected Result:**
| email | name | role | is_active |
|-------|------|------|-----------|
| staff@ssu.edu.ph | Staff Member | staff | true |

### Step 2: Verify Authentication
```sql
SELECT 
  au.email,
  au.email_confirmed_at,
  u.role,
  u.is_active
FROM auth.users au
JOIN public.users u ON au.id = u.id
WHERE au.email = 'staff@ssu.edu.ph';
```

### Step 3: Test Login
```
Email: staff@ssu.edu.ph
Password: staff123
Expected: → Staff Dashboard
```

---

## 📊 Example Queries from `FETCH_STAFF_ACCOUNTS.sql`

### Get All Staff with Details
```sql
SELECT 
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active,
  created_at
FROM public.users
WHERE role = 'staff'
ORDER BY created_at DESC;
```

### Get Staff by Department
```sql
SELECT 
  department,
  COUNT(*) as staff_count,
  array_agg(name) as staff_names
FROM public.users
WHERE role = 'staff' AND is_active = true
GROUP BY department;
```

### Check Login Status
```sql
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'staff@ssu.edu.ph')
    AND EXISTS (SELECT 1 FROM public.users WHERE email = 'staff@ssu.edu.ph' AND role = 'staff')
    THEN '✅ Staff account exists and ready to login'
    ELSE '❌ Staff account not found'
  END as status;
```

---

## 🎯 Quick Test

### 1. Run SQL to Check
```sql
-- File: supabase/FETCH_STAFF_ACCOUNTS.sql
-- Run query #1 to see all staff
```

### 2. Use in Flutter
```dart
final staffService = StaffFetchService();
final staff = await staffService.getAllStaff();
print('Found ${staff.length} staff members');
```

### 3. Login Test
```
Email: staff@ssu.edu.ph
Password: staff123
→ Should go to Staff Dashboard
```

---

## 🔧 Integration Example

### Display Staff List in Admin Dashboard
```dart
class StaffListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffService = StaffFetchService();
    
    return FutureBuilder<List<UserModel>>(
      future: staffService.getAllStaff(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final staff = snapshot.data!;
          return ListView.builder(
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return ListTile(
                title: Text(member.name),
                subtitle: Text('${member.email} - ${member.department}'),
                trailing: Icon(
                  member.isActive ? Icons.check_circle : Icons.cancel,
                  color: member.isActive ? Colors.green : Colors.grey,
                ),
              );
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

---

## ✅ Summary

**Database Query:**
```sql
SELECT * FROM public.users WHERE role = 'staff';
```

**Flutter Service:**
```dart
final staffService = StaffFetchService();
final allStaff = await staffService.getAllStaff();
```

**Login Flow:**
```
1. Staff enters: staff@ssu.edu.ph / staff123
2. App queries: SELECT * FROM users WHERE email = 'staff@ssu.edu.ph'
3. Reads role: 'staff'
4. Routes to: /staff-dashboard
```

**Everything is ready!** ✅

---

**Files:**
- `supabase/FETCH_STAFF_ACCOUNTS.sql` - All SQL queries
- `lib/core/services/staff_fetch_service.dart` - Flutter service
- `supabase/SIMPLE_CREATE_STAFF.sql` - Create staff account

**Next:** Run the SQL queries to see your staff accounts! 🚀









