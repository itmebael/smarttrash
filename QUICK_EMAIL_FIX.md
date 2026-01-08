# Quick Fix: Deploy Edge Function for Email Sending

## Current Error
```
FunctionException(status: 404, message: Requested function was not found)
```

## Quick Solution (5 minutes)

### Step 1: Go to Supabase Dashboard
1. Open https://supabase.com/dashboard
2. Select your project: `ssztyskjcoilweqmheef`

### Step 2: Create Edge Function
1. Click **Edge Functions** in left sidebar
2. Click **Create a new function** button
3. Function name: `send-task-email` (exactly this name)
4. Click **Create function**

### Step 3: Add Code
1. Delete any default code in the editor
2. Copy ALL code from: `supabase/functions/send-task-email/index.ts`
3. Paste into the editor
4. Click **Deploy** button

### Step 4: Verify
1. Function should appear in the list
2. Status should be "Active"
3. Try creating a task - email should send!

## Alternative: Use Supabase CLI

If you have Supabase CLI installed:

```bash
# Login
supabase login

# Link to project
supabase link --project-ref ssztyskjcoilweqmheef

# Deploy function
supabase functions deploy send-task-email
```

## What This Does

The Edge Function:
- Runs in a browser-like environment (Deno)
- Calls EmailJS API (EmailJS accepts it)
- Sends emails via your Gmail service
- Returns success/error to Flutter app

## After Deployment

✅ Emails will automatically send when tasks are assigned
✅ No code changes needed
✅ Works with your existing EmailJS template

## Troubleshooting

**Function still not found?**
- Check function name is exactly: `send-task-email`
- Make sure it's deployed (status: Active)
- Wait 1-2 minutes after deployment

**401 Unauthorized?**
- Make sure user is logged in
- Check Supabase authentication

**Email not received?**
- Check EmailJS dashboard → Email Logs
- Verify Gmail service is connected
- Check spam folder


