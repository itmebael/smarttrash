# ⚡ JULLS FIX - Quick Action

## 🎯 Do This Right Now (2 minutes)

### 1️⃣ Go to SQL Editor
https://app.supabase.com/project/ssztyskjcoilweqmheef/editor

### 2️⃣ Paste This
```sql
INSERT INTO public.users (id, email, name, phone_number, role, profile_image_url, fcm_token, age, address, city, state, zip_code, department, position, date_of_birth, emergency_contact, emergency_phone, is_active, created_at, updated_at, last_login_at) VALUES (gen_random_uuid(), 'julls@gmail.com', 'Julls User', '+639123456789', 'staff', NULL, NULL, 28, '123 Staff Street', 'Mindanao', 'Zamboanga del Sur', '6400', 'Sanitation Department', 'Collection Staff', '1996-05-15'::date, 'Emergency Contact Name', '+639987654321', true, now(), now(), NULL) ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name, role = EXCLUDED.role, is_active = true, updated_at = now();
```

### 3️⃣ Click Run

### 4️⃣ Test Login
```
Email: julls@gmail.com
Password: julls@gmail.com
→ Staff Dashboard Opens ✅
```

---

## ✅ Done!

That's it! julls can now login.

**File reference:** `supabase/ADD_JULLS_USER.sql`

