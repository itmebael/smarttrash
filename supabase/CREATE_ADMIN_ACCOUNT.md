# Creating the Admin Account

Since we cannot directly insert into Supabase's `auth.users` table, follow these steps to create the admin account:

## Method 1: Using Supabase Dashboard (Recommended)

### Step 1: Create Auth User

1. Open your Supabase project dashboard
2. Go to **Authentication** → **Users** (left sidebar)
3. Click **Add User** button (top right)
4. Fill in the form:
   - **Email**: `admin@ssu.edu.ph`
   - **Password**: `admin123`
   - **Auto Confirm User**: ✅ (check this box)
5. Click **Create User**
6. **Copy the User UUID** that appears (you'll need this in Step 2)

### Step 2: Insert User Record

1. Go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Paste this SQL (replace `YOUR_USER_UUID` with the UUID from Step 1):

```sql
INSERT INTO users (
  id,
  email,
  name,
  phone_number,
  role,
  department,
  position,
  is_active,
  created_at
)
VALUES (
  'YOUR_USER_UUID'::uuid,  -- Replace with UUID from Step 1
  'admin@ssu.edu.ph',
  'System Administrator',
  '+639123456789',
  'admin',
  'Administration',
  'System Administrator',
  true,
  NOW()
);
```

4. Click **Run** or press `Ctrl+Enter`
5. You should see: "Success. No rows returned"

### Step 3: Verify

Run this query to verify the admin account:

```sql
SELECT 
  u.id,
  u.email,
  u.name,
  u.role,
  u.is_active
FROM users u
WHERE u.email = 'admin@ssu.edu.ph';
```

You should see your admin account details.

### Step 4: Test Login

In your Flutter app:

```dart
final response = await supabase.auth.signInWithPassword(
  email: 'admin@ssu.edu.ph',
  password: 'admin123',
);

if (response.user != null) {
  print('Login successful!');
  print('User ID: ${response.user!.id}');
}
```

---

## Method 2: Using Supabase API (Alternative)

If you prefer to use code, you can create the admin account using the Supabase Management API:

### Step 1: Get Service Role Key

1. Go to **Project Settings** → **API**
2. Copy the **service_role key** (⚠️ Keep this secret!)

### Step 2: Create User via API

Use this Dart code (run it once):

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> createAdminAccount() async {
  // Initialize with service_role key for admin operations
  final supabase = SupabaseClient(
    'YOUR_SUPABASE_URL',
    'YOUR_SERVICE_ROLE_KEY', // ⚠️ Use service_role key, not anon key
  );

  try {
    // Step 1: Create auth user
    final authResponse = await supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: 'admin@ssu.edu.ph',
        password: 'admin123',
        emailConfirm: true,
        userMetadata: {
          'name': 'System Administrator',
          'role': 'admin',
        },
      ),
    );

    if (authResponse.user == null) {
      print('Error: Could not create auth user');
      return;
    }

    final userId = authResponse.user!.id;
    print('Auth user created: $userId');

    // Step 2: Insert user record
    await supabase.from('users').insert({
      'id': userId,
      'email': 'admin@ssu.edu.ph',
      'name': 'System Administrator',
      'phone_number': '+639123456789',
      'role': 'admin',
      'department': 'Administration',
      'position': 'System Administrator',
      'is_active': true,
    });

    print('User record created successfully!');
    print('Admin account ready to use');
    print('Email: admin@ssu.edu.ph');
    print('Password: admin123');
    print('⚠️ Change this password immediately!');
    
  } catch (e) {
    print('Error creating admin account: $e');
  }
}
```

---

## Method 3: Using SQL Function (Advanced)

Create a helper function to add the admin:

```sql
-- Run this in SQL Editor
CREATE OR REPLACE FUNCTION create_admin_account(
  p_email TEXT,
  p_password TEXT,
  p_name TEXT
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- This requires service_role privileges
  -- Cannot be called from client side
  
  -- Insert into users table (auth user must exist first)
  v_user_id := uuid_generate_v4();
  
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
    v_user_id,
    p_email,
    p_name,
    '+639123456789',
    'admin',
    'Administration',
    'System Administrator',
    true
  );
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Troubleshooting

### Issue: "User already exists"
**Solution**: The auth user already exists. Just run Step 2 to insert the user record.

### Issue: "Foreign key violation"
**Solution**: Make sure the UUID in the `users` table matches the auth user UUID exactly.

### Issue: "Cannot login"
**Solution**: 
1. Check if auth user exists in **Authentication** → **Users**
2. Check if user record exists: `SELECT * FROM users WHERE email = 'admin@ssu.edu.ph'`
3. Make sure `is_active = true`
4. Try resetting password in Supabase Dashboard

### Issue: "Permission denied"
**Solution**: Make sure RLS policies are set up correctly:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

---

## Quick Check Command

Run this to see if everything is set up correctly:

```sql
-- Check auth user
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'admin@ssu.edu.ph';

-- Check user record
SELECT id, email, name, role, is_active
FROM users
WHERE email = 'admin@ssu.edu.ph';

-- Both should return one row with matching IDs
```

---

## Security Reminder

⚠️ **After creating the admin account:**

1. **Change the password immediately**
2. Use a strong password (12+ characters)
3. Enable two-factor authentication if available
4. Never share the admin credentials
5. Store credentials securely (use environment variables)

---

## Success Checklist

- [ ] Auth user created in Supabase Dashboard
- [ ] User record inserted in `users` table
- [ ] Both have matching UUIDs
- [ ] Can login successfully from Flutter app
- [ ] Password changed from default
- [ ] Verified admin role works correctly

---

**Last Updated**: January 22, 2025

