# Deploy Supabase Edge Function for Email Sending

## Problem
EmailJS blocks direct API calls from Flutter apps (403 error: "API calls are disabled for non-browser applications").

## Solution
Use a Supabase Edge Function that runs in a browser-like environment, which EmailJS will accept.

## Steps to Deploy

### 1. Install Supabase CLI (if not already installed)

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link to Your Project

```bash
supabase link --project-ref ssztyskjcoilweqmheef
```

### 4. Deploy the Edge Function

```bash
supabase functions deploy send-task-email
```

### 5. Verify Deployment

Check in Supabase Dashboard:
- Go to **Edge Functions** → **send-task-email**
- You should see the function listed

## Alternative: Deploy via Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Edge Functions** (left sidebar)
3. Click **Create a new function**
4. Name it: `send-task-email`
5. Copy the code from `supabase/functions/send-task-email/index.ts`
6. Click **Deploy**

## Testing

After deployment, test the function:

```dart
final supabase = Supabase.instance.client;
final response = await supabase.functions.invoke(
  'send-task-email',
  body: {
    'to_email': 'test@example.com',
    'staff_name': 'Test User',
    'task_title': 'Test Task',
    'task_description': 'This is a test',
    'trashcan_name': 'Test Bin',
    'location': 'Test Location',
    'priority': 'medium',
    'due_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
    'estimated_duration': '30',
    'assigned_date': DateTime.now().toIso8601String(),
  },
);

print('Response: ${response.data}');
```

## How It Works

1. Flutter app calls Supabase Edge Function
2. Edge Function runs in Deno (browser-like environment)
3. Edge Function calls EmailJS API (EmailJS accepts it because it's browser-like)
4. EmailJS sends email via Gmail
5. Response is returned to Flutter app

## Troubleshooting

### Function Not Found
- Make sure the function is deployed
- Check function name matches exactly: `send-task-email`

### 401 Unauthorized
- Check that your Supabase client is properly authenticated
- Edge Functions require authenticated requests by default

### EmailJS Still Returns 403
- Make sure the Edge Function is actually deployed and running
- Check Edge Function logs in Supabase Dashboard

### Email Not Received
- Check EmailJS dashboard for sent emails
- Verify Gmail service is connected in EmailJS
- Check spam folder


