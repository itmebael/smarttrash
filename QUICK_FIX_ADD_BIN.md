# ⚡ QUICK FIX: Add Bin Not Working

## 🎯 Problem
Add bin feature in admin dashboard is not saving bins to database.

## ✅ Fix (2 minutes)

### Step 1: Disable RLS
Go to Supabase SQL Editor and run:

```sql
ALTER TABLE public.trashcans DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
```

### Step 2: Test
1. Hot reload app: **Ctrl+Shift+R**
2. Go to **Map** page
3. Click **"Add Bin"** button
4. Fill the form and click **"Save Trashcan to Database"**

### Expected Result
```
✅ "Trashcan saved!"
✅ New bin appears on map
```

---

## 🔍 Debug Output (in Console)
Should see:
```
🗑️ Attempting to add trashcan: [name] at (lat, lng)
🔄 Calling add_trashcan RPC function...
✅ RPC response: [uuid]
💾 Trashcan saved with ID: [uuid]
```

---

**That's it! Run the SQL and test!** 🚀

