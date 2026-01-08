# Notification System Guide

## Overview
This guide explains the JavaScript-based notification system with popup functionality for the Smart Trashcan web application.

## Files Created

1. **`web/notifications.js`** - Main notification manager JavaScript file
2. **`web/index.html`** - Updated to include the notification system
3. **`NOTIFICATIONS_SQL_TABLE.sql`** - Complete SQL schema for notifications table

## Features

### ✅ Popup Notifications
- Beautiful animated popup notifications that slide in from the right
- Auto-dismiss after 5 seconds (10 seconds for urgent notifications)
- Click to mark as read
- Close button for manual dismissal
- Hover effects for better UX

### ✅ Real-time Updates
- Listens to Supabase real-time changes
- Automatically shows new notifications as popups
- Updates notification badge count
- Plays notification sound

### ✅ Visual Design
- Color-coded by notification type:
  - 🚨 Trashcan Full (Red)
  - 📋 Task Assigned (Blue)
  - ✅ Task Completed (Green)
  - ⏰ Task Reminder (Orange)
  - 🔧 Maintenance Required (Orange-Red)
  - ⚠️ System Alert (Purple)
- Priority indicators for urgent/high priority
- **Complete task information display:**
  - 📅 Assignment time (when task was assigned)
  - ✅ Completion time (when task was completed)
  - 👤 Staff name (who completed the task)
- Responsive design

## Setup Instructions

### 1. Database Setup

Run the SQL file in your Supabase SQL Editor:

```sql
-- Copy and paste the entire contents of NOTIFICATIONS_SQL_TABLE.sql
-- into the Supabase SQL Editor and execute
```

This will create:
- `notifications` table
- Indexes for performance
- Helper functions
- Triggers for automatic notifications
- RLS policies

### 2. Web Integration

The notification system is already integrated into `web/index.html`. It will:
- Load automatically when the page loads
- Connect to Supabase
- Listen for real-time notifications
- Display popups when new notifications arrive

### 3. Configuration

The notification manager uses these Supabase credentials (already configured):
- URL: `https://ssztyskjcoilweqmheef.supabase.co`
- Anon Key: (configured in `notifications.js`)

## Usage

### Automatic Notifications

The system automatically creates notifications when:
- Trashcan fill level reaches 90% (triggers `trashcan_full` notification)
- Task is assigned to a user (triggers `task_assigned` notification with assignment time)
- Task is completed (triggers `task_completed` notification with both assignment and completion times)

**Task notifications include:**
- **Assignment Time**: Shows when the task was assigned (from `tasks.created_at`)
- **Completion Time**: Shows when the task was completed (from `tasks.completed_at`)
- **Staff Name**: Shows who completed the task
- **Task Details**: Title, description, and related trashcan information

### Manual Notification Creation

You can create notifications manually using SQL:

```sql
-- Create a notification for a specific user
SELECT create_notification(
  'Notification Title',
  'Notification body text',
  'system_alert',  -- type
  'medium',        -- priority
  'user-uuid-here' -- user_id (or NULL for global)
);

-- Create a global notification (for all users)
SELECT create_notification(
  'System Maintenance',
  'The system will be under maintenance tonight',
  'system_alert',
  'high',
  NULL  -- NULL user_id = global notification
);
```

### JavaScript API

Access the notification manager in browser console:

```javascript
// Get all notifications
const notifications = await notificationManager.getAllNotifications();

// Get unread count
const unreadCount = notificationManager.getUnreadCount();

// Mark all as read
await notificationManager.markAllAsRead();

// Mark specific notification as read
await notificationManager.markAsRead('notification-id-here');
```

## Notification Types

| Type | Icon | Color | Description |
|------|------|-------|-------------|
| `trashcan_full` | 🚨 | Red | Trashcan is full |
| `task_assigned` | 📋 | Blue | New task assigned |
| `task_completed` | ✅ | Green | Task completed |
| `task_reminder` | ⏰ | Orange | Task reminder |
| `maintenance_required` | 🔧 | Orange-Red | Maintenance needed |
| `system_alert` | ⚠️ | Purple | System alert |

## Priority Levels

- **low** - Informational, no urgency
- **medium** - Normal priority (default)
- **high** - Important, needs attention
- **urgent** - Critical, immediate action required

## SQL Table Structure

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL,
  priority TEXT DEFAULT 'medium',
  user_id UUID REFERENCES users(id),
  trashcan_id UUID REFERENCES trashcans(id),
  task_id UUID REFERENCES tasks(id),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  data JSONB,
  image_url TEXT
);
```

## Testing

### Test Popup Display

1. Open the web app in a browser
2. Open browser console (F12)
3. Create a test notification:

```javascript
// This will trigger a popup
notificationManager.handleNewNotification({
  id: 'test-' + Date.now(),
  title: 'Test Notification',
  body: 'This is a test notification to verify popup functionality',
  type: 'system_alert',
  priority: 'medium',
  is_read: false,
  created_at: new Date().toISOString()
});
```

### Test Database Integration

1. Create a notification in Supabase:

```sql
INSERT INTO notifications (title, body, type, priority, user_id)
VALUES (
  'Test Notification',
  'Testing the notification system',
  'system_alert',
  'medium',
  'your-user-id-here'
);
```

2. The popup should appear automatically if you're logged in as that user.

## Troubleshooting

### Notifications not appearing?

1. **Check browser console** for errors
2. **Verify Supabase connection**:
   ```javascript
   console.log(notificationManager.supabase);
   ```
3. **Check user authentication**:
   ```javascript
   console.log(notificationManager.currentUserId);
   ```
4. **Verify real-time subscription**:
   - Check console for "✅ Started listening for notifications"
   - Check Supabase dashboard → Realtime → Channels

### Popups not showing?

1. **Check if container exists**:
   ```javascript
   document.getElementById('notification-container');
   ```
2. **Check CSS conflicts** - The notification container uses `z-index: 10000`
3. **Check browser compatibility** - Requires modern browser with ES6+ support

### Database errors?

1. **Verify table exists**:
   ```sql
   SELECT * FROM notifications LIMIT 1;
   ```
2. **Check RLS policies**:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'notifications';
   ```
3. **Verify functions exist**:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_name LIKE '%notification%';
   ```

## Customization

### Change Popup Position

Edit `notifications.js`, find `createNotificationContainer()`:

```javascript
container.style.cssText = `
  position: fixed;
  top: 20px;      // Change top position
  right: 20px;    // Change right position
  // ... rest of styles
`;
```

### Change Auto-dismiss Time

Edit `showPopup()` method:

```javascript
// Change from 5000ms (5 seconds) to your preferred time
const autoCloseTime = priority === 'urgent' ? 15000 : 8000;
```

### Customize Colors

Edit `getNotificationStyle()` method to change colors for each notification type.

### Disable Sound

Remove or comment out the `playNotificationSound()` call in `handleNewNotification()`.

## Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Opera (latest)

Requires:
- ES6+ JavaScript support
- Web Audio API (for sound)
- Supabase JS SDK

## Security

- RLS (Row Level Security) policies ensure users only see their own notifications
- Functions use `SECURITY DEFINER` for controlled access
- User authentication required for real-time subscriptions
- XSS protection via `escapeHtml()` function

## Performance

- Indexes on frequently queried columns
- Efficient real-time subscriptions
- Local caching of notifications
- Debounced badge updates

## Future Enhancements

Potential improvements:
- [ ] Notification preferences per user
- [ ] Email notifications integration
- [ ] Push notifications (PWA)
- [ ] Notification grouping
- [ ] Sound preferences
- [ ] Notification history pagination
- [ ] Mark as read/unread toggle
- [ ] Notification filters

