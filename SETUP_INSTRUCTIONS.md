# 🚀 Quick Setup Instructions - Get Your App Working Online

## ⚡ Fast Track Setup (5 Minutes)

### Step 1: Set Up Database (2 minutes)

1. **Open Supabase SQL Editor**
   - Go to: https://app.supabase.com/project/ssztyskjcoilweqmheef/sql
   - Click **"New Query"**

2. **Run the Setup Script**
   - Open the file: `supabase/QUICK_SETUP.sql`
   - Copy **ALL** the contents (Ctrl+A, Ctrl+C)
   - Paste into the SQL Editor
   - Click **RUN** (or press Ctrl+Enter)
   - Wait for "Success" message

3. **Verify Tables Created**
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' ORDER BY table_name;
   ```
   You should see: `activity_logs`, `notifications`, `system_settings`, `tasks`, `trashcans`, `users`

---

### Step 2: Create Admin Account (2 minutes)

1. **Create Auth User**
   - Go to: https://app.supabase.com/project/ssztyskjcoilweqmheef/auth/users
   - Click **"Add User"** (top right)
   - Fill in:
     - **Email**: `admin@ssu.edu.ph`
     - **Password**: `admin123`
     - ✅ **Check**: "Auto Confirm User"
   - Click **"Create User"**
   - **COPY the User UUID** (the long ID shown)

2. **Insert User Record**
   - Go back to SQL Editor
   - Run this (replace `YOUR_UUID_HERE` with the UUID you copied):
   ```sql
   INSERT INTO users (id, email, name, role, is_active)
   VALUES (
     'YOUR_UUID_HERE',  -- Paste your UUID here
     'admin@ssu.edu.ph',
     'Admin User',
     'admin',
     true
   );
   ```

3. **Verify Admin Created**
   ```sql
   SELECT email, name, role FROM users WHERE email = 'admin@ssu.edu.ph';
   ```
   Should show: `admin@ssu.edu.ph | Admin User | admin`

---

### Step 3: Run Your App (1 minute)

1. **Start the app**
   ```bash
   flutter run
   ```

2. **Check the console** - You should see:
   ```
   ✅ Supabase initialized successfully!
   ✅ Database connection verified - Online mode active
   ✅ Ready to save and fetch data
   ```

3. **Login to the app**
   - **Email**: `admin@ssu.edu.ph`
   - **Password**: `admin123`

---

## ✅ Verification Checklist

- [ ] Database tables created (Step 1)
- [ ] Admin user created in Authentication (Step 2.1)
- [ ] Admin record inserted in users table (Step 2.2)
- [ ] App shows "Database connection verified" (Step 3)
- [ ] Can login with admin credentials

---

## 🎯 What You Can Do Now

### ✅ **Save Data Online**
- Create staff accounts
- Add trashcans
- Assign tasks
- Send notifications
- All data is saved to Supabase automatically

### ✅ **Fetch Data Online**
- View staff list
- See trashcan locations on map
- Check task status
- View notifications
- Real-time updates

---

## 🔍 Troubleshooting

### ❌ "FormatException: Unexpected character"
**Solution**: Run Step 1 - Database tables not created yet

### ❌ "relation users does not exist"
**Solution**: Run the QUICK_SETUP.sql file completely

### ❌ "Login failed: Invalid login credentials"
**Solution**: 
1. Verify admin user exists in Authentication → Users
2. Check user record exists in users table
3. UUIDs must match between auth.users and public.users

### ❌ "Database connection issue"
**Solution**: 
1. Check internet connection
2. Verify Supabase project is active (not paused)
3. Try refreshing the Supabase dashboard

---

## 📊 Test Data Operations

### Test Saving Data
```sql
-- Add a test trashcan
INSERT INTO trashcans (name, location, latitude, longitude, status)
VALUES ('Test Bin', 'SSU Campus', 11.7711, 124.8866, 'empty');
```

### Test Fetching Data
```sql
-- View all trashcans
SELECT * FROM trashcans;

-- View all users
SELECT email, name, role FROM users;
```

---

## 🎉 Success!

Your app is now:
- ✅ Connected to Supabase
- ✅ Can save data online
- ✅ Can fetch data from database
- ✅ Ready for production use

**Default Login:**
- Email: `admin@ssu.edu.ph`
- Password: `admin123`

⚠️ **Remember to change the password after first login!**

---

## 📚 Next Steps

1. Create staff accounts through the app
2. Add trashcan locations
3. Assign collection tasks
4. Monitor the dashboard
5. Check analytics

For detailed documentation, see:
- `supabase/CREATE_ADMIN_ACCOUNT.md`
- `SUPABASE_SETUP_GUIDE.md`







