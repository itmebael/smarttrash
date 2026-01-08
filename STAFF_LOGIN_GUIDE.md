# Staff Login Guide

## 🎯 Create Staff Account

### Step 1: Run SQL in Supabase

1. Open Supabase SQL Editor
2. Paste and run: `supabase/CREATE_STAFF_ACCOUNT.sql`
3. You should see: ✅ "Staff account created successfully!"

### Step 2: Test Staff Login

**Staff Credentials:**
- Email: `staff@ssu.edu.ph`
- Password: `staff123`

## 🚀 Login Flow

### For Staff Users:
1. Open the app
2. Enter staff credentials
3. Click Login
4. → **Staff Dashboard** should appear
5. Navigate to **Map** tab
6. See smart bins (same as admin)

### For Admin Users:
1. Email: `admin@ssu.edu.ph`
2. Password: `admin123`
3. → **Admin Dashboard** should appear

## 📊 Differences Between Dashboards

### Admin Dashboard
- ✅ Full system access
- ✅ Create/manage staff
- ✅ Assign tasks
- ✅ View analytics
- ✅ Generate reports
- ✅ View smart bins on map

### Staff Dashboard
- ✅ View assigned tasks
- ✅ View smart bins on map
- ✅ Update task status
- ✅ View profile
- ❌ Cannot create staff
- ❌ Cannot assign tasks
- ❌ Limited analytics

## 🔍 Troubleshooting

### Issue: Staff account doesn't exist

**Run this query in Supabase:**
```sql
SELECT * FROM public.users WHERE email = 'staff@ssu.edu.ph';
```

If empty, run the `CREATE_STAFF_ACCOUNT.sql` script.

### Issue: Login shows error

**Check the role:**
```sql
SELECT id, email, name, role FROM public.users WHERE email = 'staff@ssu.edu.ph';
```

The `role` column should be `'staff'`, not `'admin'`.

### Issue: Redirected to admin dashboard

**Update the role:**
```sql
UPDATE public.users 
SET role = 'staff' 
WHERE email = 'staff@ssu.edu.ph';
```

### Issue: Login stuck in loading

**Check console for errors:**
- Look for: `✅ User logged in:...`
- Should say: `(UserRole.staff)`
- Not: `(UserRole.admin)`

## 📝 Console Output (Expected)

### Successful Staff Login:
```
=== LOGIN START ===
Email: staff@ssu.edu.ph
✅ User logged in: Test Staff Member (UserRole.staff)
🚀 Navigating to dashboard...
📍 Target route: /staff-dashboard
```

### Successful Admin Login:
```
=== LOGIN START ===
Email: admin@ssu.edu.ph
✅ User logged in: System Administrator (UserRole.admin)
🚀 Navigating to dashboard...
📍 Target route: /dashboard
```

## ✅ Verification Checklist

- [ ] Staff account created in database
- [ ] Role is set to 'staff' (not 'admin')
- [ ] Can login with staff@ssu.edu.ph / staff123
- [ ] Redirects to /staff-dashboard (not /dashboard)
- [ ] Can see Map tab with smart bins
- [ ] Can see Tasks tab
- [ ] Can see Profile tab

## 🎨 Staff Dashboard Features

### Available Tabs:
1. **Dashboard** - Work overview, stats
2. **Tasks** - View assigned tasks
3. **Map** - View smart bins with real-time status
4. **Profile** - View/edit profile

### Smart Bin Features:
- ✅ View all bins on map
- ✅ Color-coded by status
- ✅ Tap to see details
- ✅ Real-time updates
- ✅ See fill percentage
- ✅ See last updated time

## 🔧 Quick Fix Commands

### Reset Staff Password:
```sql
UPDATE auth.users 
SET encrypted_password = crypt('staff123', gen_salt('bf'))
WHERE email = 'staff@ssu.edu.ph';
```

### Make User Staff:
```sql
UPDATE public.users 
SET role = 'staff' 
WHERE email = 'staff@ssu.edu.ph';
```

### Delete and Recreate Staff Account:
```sql
-- Delete from public.users
DELETE FROM public.users WHERE email = 'staff@ssu.edu.ph';

-- Delete from auth.users
DELETE FROM auth.users WHERE email = 'staff@ssu.edu.ph';

-- Then run CREATE_STAFF_ACCOUNT.sql again
```

## 📞 Support

If login still doesn't work:

1. **Check console logs** for navigation route
2. **Verify role** in database is `'staff'`
3. **Clear app data** and try again
4. **Hot restart** the Flutter app

---

**Created:** October 24, 2025  
**Staff Credentials:** staff@ssu.edu.ph / staff123  
**Admin Credentials:** admin@ssu.edu.ph / admin123









