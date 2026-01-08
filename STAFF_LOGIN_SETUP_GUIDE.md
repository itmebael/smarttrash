# 📱 Staff Login Setup Guide

## Quick Login Credentials

### Staff Test Account (Works Immediately!)
```
Email: staff@ssu.edu.ph
Password: staff123
```

### Admin Test Account
```
Email: admin@ssu.edu.ph
Password: admin123
```

---

## ✅ How to Login as Staff

### Step 1: Go to Login Page
- Open the app
- You should see the login page

### Step 2: Enter Staff Credentials
```
Email: staff@ssu.edu.ph
Password: staff123
```

### Step 3: Click Login
- Click the login button

### Step 4: ✅ Staff Dashboard Opens!
- You will see the staff dashboard
- Shows your name, department, tasks
- Can manage your tasks
- Can view your statistics

---

## 🔑 Why These Credentials?

These are **hardcoded test accounts** in the auth provider for quick testing:

**Location:** `lib/core/providers/auth_provider.dart`

```dart
// Line 121-151: Hardcoded staff login
if (email == 'staff@ssu.edu.ph' && password == 'staff123') {
  // Creates staff user and logs in
  return true;
}
```

### Hardcoded Accounts Don't Require Database

- ✅ Work immediately
- ✅ No database setup needed
- ✅ Perfect for testing
- ✅ Always available

---

## 🗄️ Add More Staff to Database

To add real staff users to your database:

### Step 1: Create Users Table
```sql
-- File: supabase/CREATE_USERS_TABLE.sql
-- Copy and run in Supabase SQL Editor
```

### Step 2: Insert Staff Users
```sql
-- File: supabase/INSERT_STAFF_USERS.sql
-- Copy and run in Supabase SQL Editor
```

### Step 3: Test Database Login
Once database is set up, you can:
- Add new staff email/password via Supabase Auth
- Insert corresponding user record in users table
- Login with those credentials

---

## 📊 Available Test Accounts

### Pre-Built Accounts (No Database Needed)

| Email | Password | Role | Dashboard |
|-------|----------|------|-----------|
| `admin@ssu.edu.ph` | `admin123` | Admin | Admin Dashboard |
| `staff@ssu.edu.ph` | `staff123` | Staff | Staff Dashboard |

### Database Accounts (After Running SQL)

```
john.doe@ssu.edu.ph          (staff)
jane.smith@ssu.edu.edu.ph    (staff)
mike.johnson@ssu.edu.ph      (staff)
sarah.williams@ssu.edu.ph    (staff)
```

Note: These need Supabase Auth setup for login

---

## 🎯 Staff Dashboard Features

When logged in as staff, you can:

✅ **View Personal Info**
- Your name
- Your department
- Your position
- Your phone number

✅ **Manage Tasks**
- See assigned tasks
- Update task status
- View task details
- Mark as complete

✅ **View Statistics**
- Tasks pending
- Tasks completed
- Tasks in progress
- Performance metrics

✅ **Other Features**
- View notifications
- Update profile
- Check settings
- Logout

---

## 🔄 Login Flow for Staff

```
1. User opens app
   ↓
2. Sees login page
   ↓
3. Enters:
   Email: staff@ssu.edu.ph
   Password: staff123
   ↓
4. Clicks "Login"
   ↓
5. Auth provider checks credentials
   ↓
6. Matches hardcoded staff account
   ↓
7. Creates user with role='staff'
   ↓
8. ✅ AUTOMATICALLY NAVIGATES TO STAFF DASHBOARD
   ↓
9. Staff dashboard opens
   ↓
10. Staff sees personal dashboard
```

---

## 🧪 Test Different Scenarios

### Test 1: Staff Login
```
1. Email: staff@ssu.edu.ph
2. Password: staff123
3. Expected: Staff Dashboard ✅
```

### Test 2: Admin Login
```
1. Email: admin@ssu.edu.ph
2. Password: admin123
3. Expected: Admin Dashboard ✅
```

### Test 3: Invalid Credentials
```
1. Email: staff@ssu.edu.ph
2. Password: wrongpassword
3. Expected: Error message ✅
```

### Test 4: Unknown Email
```
1. Email: unknown@test.com
2. Password: any123
3. Expected: "Invalid email or password" ✅
```

### Test 5: Logout
```
1. Logged in as staff
2. Click logout button (header icon)
3. Expected: Back to login page ✅
4. Session cleared ✅
```

---

## 📁 Important Files

### Authentication
- `lib/core/providers/auth_provider.dart` - Login logic (line 121-151)
- `lib/features/auth/presentation/pages/cool_login_page.dart` - Login UI

### Staff Dashboard
- `lib/features/dashboard/presentation/pages/staff_dashboard_page.dart` - Staff view

### Database Setup (Optional)
- `supabase/CREATE_USERS_TABLE.sql` - Create table
- `supabase/INSERT_STAFF_USERS.sql` - Add staff data

---

## 🚀 Quick Start

### Immediate (No Setup Needed)
```
1. Open app
2. Login with:
   Email: staff@ssu.edu.ph
   Password: staff123
3. ✅ See staff dashboard!
```

### With Database (Optional)
```
1. Run: supabase/CREATE_USERS_TABLE.sql
2. Run: supabase/INSERT_STAFF_USERS.sql
3. Can now add more staff via Supabase
4. All new staff can login with their credentials
```

---

## ❓ Troubleshooting

### Issue: Login Shows "Invalid email or password"
**Solution:**
- Make sure you're using exact credentials:
  - `staff@ssu.edu.ph` (not staff@example.com)
  - `staff123` (not staff or 123)
- Check for extra spaces
- Try copying credentials from this guide

### Issue: Don't See Staff Dashboard
**Solution:**
- Make sure you're logged in as staff (not admin)
- Check browser console for errors
- Try logout and login again

### Issue: Want More Staff Accounts
**Solution:**
- Run `supabase/INSERT_STAFF_USERS.sql` to add database users
- This creates 5 pre-built staff accounts
- Can then add more via Supabase

### Issue: Want to Create Custom Staff
**Solution:**
1. Go to Supabase Console
2. Go to Authentication → Users
3. Add new user with email/password
4. Insert corresponding user record in users table
5. Staff can then login

---

## 🔐 Security Notes

### Test Accounts
- These are for **testing only**
- Should be removed before production
- Use strong passwords in production
- Set up proper authentication for real users

### Database Users
- Use Supabase Auth for creating users
- Enable email verification
- Set password requirements
- Implement 2FA if needed

---

## 📝 Staff Information Stored

When you login as staff, the system stores:

```
Name: Staff Member
Department: Sanitation Department
Position: Collection Staff
Phone: +639123456789
Email: staff@ssu.edu.ph
Role: staff
```

This information is displayed in the staff dashboard.

---

## ✨ Features After Staff Login

| Feature | Available |
|---------|-----------|
| Dashboard | ✅ Yes |
| Personal Info | ✅ Yes |
| Assigned Tasks | ✅ Yes |
| Task Management | ✅ Yes |
| Statistics | ✅ Yes |
| Notifications | ✅ Yes |
| Profile Edit | ✅ Yes |
| Settings | ✅ Yes |
| Logout | ✅ Yes |
| Staff Management | ❌ No (Admin only) |
| Analytics | ❌ No (Admin only) |
| System Settings | ❌ No (Admin only) |

---

## 🎯 Next Steps

1. **Test Staff Login Now**
   ```
   Email: staff@ssu.edu.ph
   Password: staff123
   ```

2. **Explore Staff Dashboard**
   - View your information
   - Check assigned tasks
   - See your statistics

3. **Optional: Add Database Users**
   - Run `supabase/CREATE_USERS_TABLE.sql`
   - Run `supabase/INSERT_STAFF_USERS.sql`
   - Create more staff via Supabase

4. **Test Logout**
   - Click logout button
   - Verify you return to login

---

## ✅ What You Can Do Now

- ✅ Login as staff with provided credentials
- ✅ See staff dashboard with personal info
- ✅ Manage tasks (if assigned)
- ✅ View personal statistics
- ✅ Logout and login again
- ✅ Test different credentials

---

**Status:** ✅ READY TO USE  
**Test Credentials:** Working  
**Staff Dashboard:** Ready  

Try logging in as staff now! 🎉

```
Email: staff@ssu.edu.ph
Password: staff123
```

