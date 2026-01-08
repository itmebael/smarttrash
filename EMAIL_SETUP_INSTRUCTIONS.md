# Email Setup Instructions

## Problem
EmailJS returns **403 error**: "API calls are disabled for non-browser applications" when called directly from Flutter.

## Solution
Use a **Supabase Edge Function** to proxy the EmailJS call. Edge Functions run in a browser-like environment, so EmailJS will accept them.

## Quick Setup

### Option 1: Deploy Edge Function (Recommended)

1. **Install Supabase CLI** (if needed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link to your project**:
   ```bash
   supabase link --project-ref ssztyskjcoilweqmheef
   ```

4. **Deploy the function**:
   ```bash
   supabase functions deploy send-task-email
   ```

### Option 2: Deploy via Supabase Dashboard

1. Go to your Supabase Dashboard
2. Navigate to **Edge Functions** (left sidebar)
3. Click **Create a new function**
4. Name: `send-task-email`
5. Copy code from: `supabase/functions/send-task-email/index.ts`
6. Click **Deploy**

## How It Works

```
Flutter App → Supabase Edge Function → EmailJS API → Gmail
```

1. Your Flutter app calls the Edge Function
2. Edge Function runs in Deno (browser-like)
3. Edge Function calls EmailJS (EmailJS accepts it)
4. EmailJS sends email via your Gmail service
5. Success response returns to Flutter

## Testing

After deployment, create a task and check the console logs:
- ✅ `📧 Sending email via Supabase Edge Function...`
- ✅ `✅ Email sent successfully via Edge Function!`

## Troubleshooting

### Edge Function Not Found
- Verify function is deployed: Check **Edge Functions** in Supabase Dashboard
- Function name must be exactly: `send-task-email`

### 401 Unauthorized
- Make sure user is logged in to Supabase
- Edge Functions require authentication

### EmailJS Still Returns 403
- Check Edge Function logs in Supabase Dashboard
- Verify Edge Function is actually calling EmailJS

### Emails Not Received
- Check EmailJS dashboard → **Email Logs**
- Verify Gmail service is connected in EmailJS
- Check recipient's spam folder

## Current Status

✅ Edge Function code created: `supabase/functions/send-task-email/index.ts`
✅ Flutter code updated to use Edge Function
⏳ **Next Step**: Deploy the Edge Function using one of the options above

## After Deployment

Once deployed, emails will automatically send when tasks are assigned. No code changes needed - just deploy the function!


