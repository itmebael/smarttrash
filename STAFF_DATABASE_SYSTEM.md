# Staff Database System Integration

## Overview
The staff management system now fully integrates with the Supabase `users` table to store and manage staff data. All staff members are stored in the database with their complete information.

## Database Schema (users table)

```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
  profile_image_url TEXT,
  fcm_token TEXT,
  
  -- Additional details
  age INTEGER,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  department TEXT,
  position TEXT,
  date_of_birth DATE,
  emergency_contact TEXT,
  emergency_phone TEXT,
  
  -- Status and tracking
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE
)
```

## File Structure

### New Services

#### 1. **SupabaseStaffService** (`lib/core/services/supabase_staff_service.dart`)
Main service for all staff-related database operations:

```dart
// Get all staff
List<UserModel> staff = await SupabaseStaffService.getAllStaff();

// Get active staff only
List<UserModel> activeStaff = await SupabaseStaffService.getActiveStaff();

// Get staff by ID
UserModel? staff = await SupabaseStaffService.getStaffById(id);

// Get staff by department
List<UserModel> deptStaff = await SupabaseStaffService.getStaffByDepartment('IT');

// Create new staff
bool success = await SupabaseStaffService.createStaff(
  email: 'john@example.com',
  name: 'John Doe',
  phoneNumber: '+1234567890',
  department: 'Sanitation',
  position: 'Collection Staff',
  password: 'securePassword123',
);

// Update staff
bool success = await SupabaseStaffService.updateStaff(
  id: staffId,
  name: 'New Name',
  department: 'New Department',
);

// Toggle staff status
bool success = await SupabaseStaffService.toggleStaffStatus(staffId);

// Delete staff
bool success = await SupabaseStaffService.deleteStaff(staffId);

// Get statistics
Map<String, int> stats = await SupabaseStaffService.getStaffStatistics();
// Returns: { 'total': 10, 'active': 8, 'inactive': 2 }

// Search staff
List<UserModel> results = await SupabaseStaffService.searchStaff('john');

// Count staff
int count = await SupabaseStaffService.getStaffCount();
```

### New Providers

#### 2. **Staff Provider** (`lib/core/providers/staff_provider.dart`)
Riverpod providers for reactive staff data:

```dart
// Watch all staff
final allStaffAsync = ref.watch(allStaffProvider);

// Watch active staff only
final activeStaffAsync = ref.watch(activeStaffProvider);

// Watch staff count
final countAsync = ref.watch(staffCountProvider);

// Watch active staff count
final activeCountAsync = ref.watch(activeStaffCountProvider);

// Watch staff statistics
final statsAsync = ref.watch(staffStatsProvider);

// Search staff (with query parameter)
final searchAsync = ref.watch(searchStaffProvider('john'));

// Get staff by department
final deptStaffAsync = ref.watch(staffByDepartmentProvider('IT'));

// Get staff by ID
final staffAsync = ref.watch(staffByIdProvider(staffId));
```

## Usage Examples

### In Staff Management Page

```dart
class StaffManagementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(allStaffProvider);
    
    return staffAsync.when(
      data: (staffList) {
        return ListView.builder(
          itemCount: staffList.length,
          itemBuilder: (context, index) {
            final staff = staffList[index];
            return StaffCard(staff: staff);
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
```

### In Staff Dashboard

The staff dashboard now shows the logged-in user's data:

```dart
final currentUserAsync = ref.watch(authProvider);

currentUserAsync.when(
  data: (user) {
    return Column(
      children: [
        Text('Welcome, ${user?.name}!'),
        Text('Department: ${user?.department}'),
        Text('Position: ${user?.position}'),
      ],
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (_, __) => const Text('Error loading user'),
)
```

### Adding Staff via Create Staff Dialog

The create staff dialog saves data to the database:

```dart
await SupabaseStaffService.createStaff(
  email: email,
  name: name,
  phoneNumber: phoneNumber,
  age: age,
  address: address,
  city: city,
  state: state,
  zipCode: zipCode,
  department: department,
  position: position,
  dateOfBirth: dateOfBirth,
  emergencyContact: emergencyContact,
  emergencyPhone: emergencyPhone,
);
```

## Staff Registration Flow

1. **Staff Registration Page** (`lib/features/auth/presentation/pages/staff_register_page.dart`)
   - User enters email, password, name, and phone
   - Calls `authProvider.register()` with UserRole.staff
   
2. **Auth Provider** (`lib/core/providers/auth_provider.dart`)
   - Signs up user with Supabase Auth
   - Inserts user record into users table
   - Sets role to 'staff'

3. **Database Storage**
   - User data is stored in the `users` table with role='staff'
   - All additional fields (department, position, etc.) are populated from the create staff dialog

## Login Flow

When a staff member logs in:

1. Auth provider authenticates with Supabase
2. Loads user data from `users` table where id matches and role='staff'
3. Stores user data in auth state
4. Staff dashboard shows user's name and department

## Dashboard Display

### Staff Dashboard Header
Shows the logged-in staff member's:
- Name
- Department (if available)
- Position (if available)

### Staff Dashboard Overview
Shows stats based on:
- Assigned tasks
- Completed tasks
- In-progress tasks

## Migration Steps

If migrating from local data to database:

1. Ensure database schema is created (20250122_complete_schema.sql)
2. All new staff registrations will use database
3. Existing staff can be imported via SQL:

```sql
INSERT INTO users (
  email, name, phone_number, role, 
  department, position, is_active, created_at
) VALUES (
  'staff@example.com', 'Staff Name', '+1234567890', 
  'staff', 'Department', 'Position', true, NOW()
);
```

## Security Considerations

- Row Level Security (RLS) policies ensure:
  - Users can only view their own profile
  - Admins can view/manage all staff
  - Staff cannot delete themselves
  
- Email validation enforced at database level
- Role validation ensures only 'admin' or 'staff' values

## Troubleshooting

### Staff not appearing in dashboard
1. Check if user is logged in via authProvider
2. Verify user record exists in users table with role='staff'
3. Check RLS policies are enabled and correct

### Creating staff fails
1. Ensure email is unique
2. Check database connection is active
3. Verify Supabase project URL and keys

### Performance issues
1. Indexes are created on commonly queried fields:
   - idx_users_email
   - idx_users_role
   - idx_users_is_active

## Environment Variables

Make sure Supabase is properly configured in `main.dart`:
```dart
const supabaseUrl = 'https://ssztyskjcoilweqmheef.supabase.co';
const supabaseAnonKey = 'your-anon-key-here';
```

## Future Enhancements

- [ ] Batch import staff from CSV
- [ ] Staff performance analytics
- [ ] Department-based filtering
- [ ] Staff availability calendar
- [ ] Advanced search with filters



