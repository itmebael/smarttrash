# Simple Role-Based Routing

## ✅ How It Works (Super Simple!)

```
Database Table: public.users
├── role = 'admin' → Admin Dashboard (/dashboard)
└── role = 'staff' → Staff Dashboard (/staff-dashboard)
```

---

## 🎯 The Logic (Already Implemented!)

### 1. User Login Flow
```
User enters email/password
       ↓
App checks auth.users (authentication)
       ↓
App reads public.users table
       ↓
Reads the 'role' column
       ↓
if role = 'admin' → context.pushReplacement('/dashboard')
if role = 'staff' → context.pushReplacement('/staff-dashboard')
```

### 2. Code Implementation
```dart
// In cool_login_page.dart (line 107-114)
if (user.isAdmin) {              // if role = 'admin'
  context.pushReplacement('/dashboard');
} else {                         // if role = 'staff'
  context.pushReplacement('/staff-dashboard');
}
```

---

## 🚀 Create Staff Account (2 Steps)

### Step 1: Run SQL
```sql
-- File: supabase/SIMPLE_CREATE_STAFF.sql
-- This creates: staff@ssu.edu.ph with role='staff'
```

In Supabase SQL Editor, run the entire file.

### Step 2: Login
```
Email: staff@ssu.edu.ph
Password: staff123
```

**Result:** Automatically goes to **Staff Dashboard** ✅

---

## 📊 Database Table Check

### Verify Role:
```sql
SELECT email, name, role FROM public.users;
```

**Expected:**
| email | name | role |
|-------|------|------|
| admin@ssu.edu.ph | System Administrator | admin |
| staff@ssu.edu.ph | Staff Member | staff |

---

## 🔄 Admin Creates Staff Account (Future Feature)

When admin creates a staff account through the app:

```dart
// In create staff function
await supabase.from('users').insert({
  'email': email,
  'name': name,
  'phone_number': phone,
  'role': 'staff',  // ← Set role to 'staff'
  'department': department,
  'position': position,
});
```

Then staff can login with their credentials and automatically go to staff dashboard!

---

## ✅ Role Constraint

Your table has this constraint:
```sql
constraint users_role_check check (
  (role = any (array['admin'::text, 'staff'::text]))
)
```

This ensures **only 'admin' or 'staff'** can be in the role column. ✅

---

## 🎨 Dashboard Differences

| Feature | Admin Dashboard | Staff Dashboard |
|---------|----------------|-----------------|
| Route | `/dashboard` | `/staff-dashboard` |
| Create Staff | ✅ Yes | ❌ No |
| Assign Tasks | ✅ Yes | ❌ No |
| View Smart Bins | ✅ Yes | ✅ Yes |
| View Tasks | ✅ Yes | ✅ Yes (only assigned) |
| Theme Color | Green | Blue |

Both see the same smart bin map with animated markers!

---

## 🐛 Quick Troubleshooting

### Problem: "Invalid email or password"
**Solution:** Staff account doesn't exist. Run `SIMPLE_CREATE_STAFF.sql`

### Problem: Goes to admin dashboard instead
**Solution:** Role is set to 'admin'. Fix it:
```sql
UPDATE public.users SET role = 'staff' WHERE email = 'staff@ssu.edu.ph';
```

### Problem: No navigation after login
**Solution:** Check console logs for the role detection

---

## 📝 Test Accounts

After running the SQL:

**Admin:**
- Email: `admin@ssu.edu.ph`
- Password: `admin123`
- Role: `admin`
- Route: `/dashboard`

**Staff:**
- Email: `staff@ssu.edu.ph`
- Password: `staff123`
- Role: `staff`
- Route: `/staff-dashboard`

---

## ✅ Summary

**The routing is automatic based on the `role` column!**

1. Create staff account with `role = 'staff'`
2. Staff logs in
3. App reads `role` from database
4. If `role = 'staff'` → Goes to Staff Dashboard
5. If `role = 'admin'` → Goes to Admin Dashboard

**That's it!** Simple and clean! 🎉

---

**File to run:** `supabase/SIMPLE_CREATE_STAFF.sql`  
**Login:** staff@ssu.edu.ph / staff123  
**Result:** Staff Dashboard with smart bin map! 🗺️









