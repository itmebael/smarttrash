# 🔐 Admin Account Setup Guide

Your app is now connected to Supabase online! Follow these steps to create the admin account.

## ✅ Current Status
- App successfully connects to Supabase
- Hardcoded offline login removed
- Ready to create admin account

## 📋 Steps to Create Admin Account

### Step 1: Create Auth User in Supabase Dashboard

1. Open your Supabase project: https://ssztyskjcoilweqmheef.supabase.co
2. Go to **Authentication** → **Users** (left sidebar)
3. Click **"Add User"** button (top right)
4. Fill in the form:
   - **Email**: `admin@ssu.edu.ph`
   - **Password**: `admin123` (or your preferred password)
   - **Auto Confirm User**: ✅ **YES** (very important!)
5. Click **"Create User"**

### Step 2: Link User to Database

1. In Supabase Dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Copy and paste the contents of `supabase/CREATE_ADMIN_ACCOUNT.sql`
4. Click **"Run"** (or press Ctrl+Enter)
5. You should see: ✅ **Admin account created successfully!**

### Step 3: Test Login

1. Restart your Flutter app
2. Use these credentials to log in:
   - **Email**: `admin@ssu.edu.ph`
   - **Password**: `admin123`
3. You should now be able to log in and create staff accounts!

## 🎉 What This Enables

Once the admin account is set up:
- ✅ Log in online (no more hardcoded data)
- ✅ Create staff accounts that save to database
- ✅ All data persists online in Supabase
- ✅ Multi-device support

## ⚠️ Troubleshooting

### "Invalid login credentials" error
- Make sure you created the auth user in Step 1
- Make sure you enabled "Auto Confirm User"
- Run the SQL script in Step 2

### "Database connection not available" error
- Check your internet connection
- Verify Supabase credentials in `lib/main.dart`

### "Only admins can create staff accounts" error
- Run the SQL script in Step 2 to link the user to database with admin role

## 📝 Notes

- The password `admin123` is just for initial setup
- You can change it later in Supabase Dashboard → Authentication → Users
- The admin role is set in the `public.users` table via the SQL script


















