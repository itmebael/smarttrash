# ✅ Setup Staff Supabase Login - Complete Guide

## Overview
The `public.users` table exists. Now we need to:
1. Insert staff data into the table
2. Create staff user in Supabase Auth
3. Test login

---

## Step 1: Insert Staff Data into Database

### Run SQL Script

**Go to:** https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

**Copy entire contents from:**
```
supabase/INSERT_STAFF_AUTH.sql
```

**Paste into SQL Editor and click "Run"**

This will:
- ✅ Insert staff user: `staff@ssu.edu.ph`
- ✅ Insert admin user: `admin@ssu.edu.ph`
- ✅ Insert 4 additional staff members
- ✅ Create indexes if needed
- ✅ Display verification results

---

## Step 2: Create Staff User in Supabase Auth

### Method A: GUI (Recommended)

**Location:** https://app.supabase.com/project/ssztyskjcoilweqmheef/auth/users

**Steps:**
1. Click: **"Add user"** button (top right)
2. Select: **"Email"**
3. Enter:
   ```
   Email: staff@ssu.edu.ph
   Password: staff123
   ```
4. Uncheck: "Auto send invite link" (optional)
5. Click: **"Create user"**
6. Verify: User appears in list with status "Confirmed"

**Result:** Staff user is now in Supabase Auth ✅

---

## Step 3: Test Login in App

**In your Flutter app:**

1. Go to Login page
2. Enter:
   ```
   Email: staff@ssu.edu.ph
   Password: staff123
   ```
3. Click **"Login"**

**Expected Result:** ✅ **Staff Dashboard Opens**

---

## Login Flow Explanation

```
1. User enters credentials
   Email: staff@ssu.edu.ph
   Password: staff123
   ↓
2. App sends to Supabase Auth
   ↓
3. Supabase Auth validates password
   ↓
4. Auth returns user ID (if valid)
   ↓
5. App loads user from public.users table
   ↓
6. Gets role: 'staff'
   ↓
7. ✅ Checks role and routes to /staff-dashboard
   ↓
8. Staff Dashboard opens automatically
```

---

## Complete Staff Data Being Inserted

### Primary Staff Account
```
Email: staff@ssu.edu.ph
Name: Staff Member
Role: staff
Department: Sanitation Department
Position: Collection Staff
Age: 28
Phone: +639123456789
Address: 123 Staff Street
City: Mindanao
State: Zamboanga del Sur
Zip: 6400
Emergency Contact: Emergency Contact Name
Emergency Phone: +639987654321
Date of Birth: 1996-05-15
Status: Active ✅
```

### Additional Staff Accounts (Bonus)
```
1. john.doe@ssu.edu.ph (Waste Collection Officer)
2. jane.smith@ssu.edu.ph (Maintenance Staff)
3. mike.johnson@ssu.edu.ph (Senior Collection Staff)
4. sarah.williams@ssu.edu.ph (Coordinator)
```

---

## Verify Setup

### Check 1: Data in Database

**Go to:** SQL Editor

**Run:**
```sql
SELECT email, name, role, department FROM public.users WHERE role = 'staff';
```

**Expected Output:**
```
staff@ssu.edu.ph          | Staff Member        | staff
john.doe@ssu.edu.ph       | John Doe            | staff
jane.smith@ssu.edu.ph     | Jane Smith          | staff
mike.johnson@ssu.edu.ph   | Mike Johnson        | staff
sarah.williams@ssu.edu.ph | Sarah Williams      | staff
```

### Check 2: User in Auth

**Go to:** Authentication → Users

**Look for:**
- ✅ `staff@ssu.edu.ph` with status "Confirmed"

### Check 3: Login Works

**In app:**
```
Email: staff@ssu.edu.ph
Password: staff123
→ Should open Staff Dashboard
```

---

## Troubleshooting

### Issue: "Invalid email or password"

**Cause:** Staff user not created in Supabase Auth

**Solution:**
1. Go to Authentication → Users
2. Click "Add user"
3. Enter: `staff@ssu.edu.ph` / `staff123`
4. Create user
5. Retry login

### Issue: Login works but wrong dashboard

**Cause:** Role is wrong in database

**Solution:**
1. Run verification SQL above
2. Verify role = 'staff'
3. If wrong, update:
   ```sql
   UPDATE public.users SET role = 'staff' WHERE email = 'staff@ssu.edu.ph';
   ```

### Issue: "Database connection not available"

**Cause:** Supabase not initialized

**Solution:**
1. Check internet connection
2. Hard refresh app (Ctrl+Shift+R)
3. Check console for errors
4. Restart app

---

## Admin Account (Bonus)

Also created for testing admin features:

```
Email: admin@ssu.edu.ph
Password: admin123
Role: admin
Dashboard: Admin Dashboard (/dashboard)
```

**To test admin:**
1. Login with admin credentials
2. Should see Admin Dashboard
3. Can create staff, view analytics, etc.

---

## Files Involved

### SQL Files
- `supabase/CREATE_USERS_TABLE.sql` - Table schema (already exists)
- `supabase/INSERT_STAFF_AUTH.sql` - Insert staff data (run this now)

### App Files
- `lib/core/providers/auth_provider.dart` - Login logic
- `lib/features/auth/presentation/pages/cool_login_page.dart` - Login UI
- `lib/features/dashboard/presentation/pages/staff_dashboard_page.dart` - Staff dashboard

---

## Summary of What's Happening

| Step | Action | Location | Status |
|------|--------|----------|--------|
| 1 | Table exists | `public.users` | ✅ Done |
| 2 | Insert data | SQL Editor | ⏳ Run now |
| 3 | Create Auth | Authentication → Users | ⏳ Do after SQL |
| 4 | Test login | App | ⏳ After Auth |
| 5 | See dashboard | App | ⏳ Result |

---

## Next: What To Do

### Immediate (Right Now)
1. **Copy SQL** from `supabase/INSERT_STAFF_AUTH.sql`
2. **Go to** SQL Editor
3. **Paste and Run** the SQL
4. **Wait for** success message

### Then (After SQL Succeeds)
1. **Go to** Authentication → Users
2. **Create user**: `staff@ssu.edu.ph` / `staff123`
3. **Wait for** creation to complete

### Finally (Test Login)
1. **Open app**
2. **Enter credentials**:
   - Email: `staff@ssu.edu.ph`
   - Password: `staff123`
3. **Click Login**
4. **✅ See Staff Dashboard!**

---

## Success Indicators

When everything is working:

✅ SQL insert completes with success message  
✅ Staff user appears in Authentication → Users  
✅ Login doesn't show error  
✅ App redirects to Staff Dashboard  
✅ Staff name appears in dashboard  
✅ Can see tasks and statistics  

---

## Ready!

Everything is set up. Just follow the steps above and staff login will work! 🚀

**File to use:** `supabase/INSERT_STAFF_AUTH.sql`

