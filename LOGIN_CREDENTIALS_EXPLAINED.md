# 📋 Login Credentials Explained

## 🎯 Current Login Flow

The app checks credentials in this order:

```
1. Hardcoded ADMIN account
2. Hardcoded STAFF account
3. Supabase database (if above don't match)
```

---

## ✅ Hardcoded Accounts (Always Work)

### Admin Account
```
Email: admin@ssu.edu.ph
Password: admin123
→ Opens Admin Dashboard
```

### Staff Account
```
Email: staff@ssu.edu.ph
Password: staff123
→ Opens Staff Dashboard
```

---

## 🔴 Why `julls@gmail.com` Failed

Your tried login:
```
Email: julls@gmail.com
Password: julls@gmail.com
```

**Result:** ❌ Not in hardcoded accounts → Tried Supabase → Not found → Login failed

---

## 📊 Login Order

```
┌─────────────────────────────────┐
│ User enters credentials         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ Is it admin@ssu.edu.ph / 123?   │ ← Line 88
└────────────┬────────────────────┘
             │ No
             ▼
┌─────────────────────────────────┐
│ Is it staff@ssu.edu.ph / 123?   │ ← Line 121
└────────────┬────────────────────┘
             │ No
             ▼
┌─────────────────────────────────┐
│ Try Supabase Auth               │ ← Line 162
└────────────┬────────────────────┘
             │
             ▼
    Success or Fail
```

---

## ✅ Test Now

### Test 1: Staff Login (Works Immediately)
```
Email: staff@ssu.edu.ph
Password: staff123

Expected: ✅ Staff Dashboard Opens
```

### Test 2: Admin Login (Works Immediately)
```
Email: admin@ssu.edu.ph
Password: admin123

Expected: ✅ Admin Dashboard Opens
```

---

## 🚀 To Use Supabase Accounts

If you want to login with custom Supabase users like `julls@gmail.com`:

1. **Create user in Supabase Auth:**
   - Go to: https://app.supabase.com/project/ssztyskjcoilweqmheef/auth/users
   - Click "Add user"
   - Email: `julls@gmail.com`
   - Password: `julls@gmail.com`
   - Create user

2. **Create user record in database:**
   ```sql
   INSERT INTO public.users (
     email,
     name,
     role,
     is_active,
     created_at,
     updated_at
   ) VALUES (
     'julls@gmail.com',
     'Julls User',
     'staff',
     true,
     now(),
     now()
   );
   ```

3. **Then login will work:**
   ```
   Email: julls@gmail.com
   Password: julls@gmail.com
   → Should open Staff Dashboard
   ```

---

## 🎯 You Have Two Login Options

### Option A: Use Hardcoded (Immediate)
```
✅ Works right now
✅ No Supabase setup needed
✅ admin@ssu.edu.ph / admin123
✅ staff@ssu.edu.ph / staff123
```

### Option B: Use Supabase (Custom Users)
```
⏳ Requires Supabase setup
⏳ Create auth user + DB record
✅ Use any email/password
✅ Customizable user data
```

---

## 📝 Current Code Logic

**File:** `lib/core/providers/auth_provider.dart`

```dart
Future<bool> login(String email, String password) async {
  // Check hardcoded ADMIN (Line 88)
  if (email == 'admin@ssu.edu.ph' && password == 'admin123') {
    return true; // ✅ Instant login
  }

  // Check hardcoded STAFF (Line 121)
  if (email == 'staff@ssu.edu.ph' && password == 'staff123') {
    return true; // ✅ Instant login
  }

  // Try Supabase (Line 162)
  final response = await _supabase!.auth.signInWithPassword(...);
  if (response.user != null) {
    return true; // ✅ Supabase login
  }

  return false; // ❌ Failed
}
```

---

## ✨ Recommendation

**For Testing & Development:**
1. Use hardcoded accounts first: `staff@ssu.edu.ph` / `staff123`
2. Verify Staff Dashboard works
3. Test features
4. Then set up Supabase custom users if needed

**For Production:**
1. Remove hardcoded accounts (optional)
2. Use only Supabase authentication
3. Implement proper user management

---

## 🚀 Right Now - Test With Hardcoded

Go back to login screen and use:

```
Email: staff@ssu.edu.ph
Password: staff123
```

**You should see Staff Dashboard immediately!** ✅

---

**Hardcoded accounts work now. No Supabase FormatException!** 🎉

