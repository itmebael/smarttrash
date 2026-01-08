# API Reference - Flutter Integration

## Authentication

### Login
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'admin@ssu.edu.ph',
  password: 'admin123',
);

// Get user data
if (response.user != null) {
  final userData = await supabase
    .from('users')
    .select()
    .eq('id', response.user!.id)
    .single();
}
```

### Logout
```dart
await supabase.auth.signOut();
```

### Change Password
```dart
await supabase.auth.updateUser(
  UserAttributes(password: 'newPassword123'),
);
```

## User Management (Admin Only)

### Get All Users
```dart
final users = await supabase
  .from('users')
  .select()
  .order('created_at', ascending: false);
```

### Get All Staff Members
```dart
final staff = await supabase
  .from('users')
  .select()
  .eq('role', 'staff')
  .eq('is_active', true);
```

### Create Staff Account
```dart
// Method 1: Using the helper function
final staffId = await supabase.rpc('create_staff_account', params: {
  'p_email': 'staff@ssu.edu.ph',
  'p_name': 'Staff Name',
  'p_phone': '+639123456789',
  'p_department': 'Maintenance',
  'p_position': 'Utility Staff',
});

// Method 2: Direct insert (requires auth user creation first)
await supabase.from('users').insert({
  'email': 'staff@ssu.edu.ph',
  'name': 'Staff Name',
  'phone_number': '+639123456789',
  'role': 'staff',
  'department': 'Maintenance',
  'position': 'Utility Staff',
  'is_active': true,
});
```

### Update User Profile
```dart
await supabase.rpc('update_user_profile', params: {
  'p_user_id': userId,
  'p_name': 'New Name',
  'p_phone': '+639987654321',
  'p_department': 'New Department',
});
```

### Deactivate/Activate User
```dart
await supabase.rpc('toggle_user_status', params: {
  'p_user_id': userId,
  'p_is_active': false, // or true to activate
});
```

### Delete User (Soft Delete)
```dart
await supabase.rpc('soft_delete_user', params: {
  'p_user_id': userId,
});
```

### Get User Statistics
```dart
final stats = await supabase.rpc('get_user_stats', params: {
  'user_uuid': userId,
});
```

## Trashcan Management

### Get All Trashcans
```dart
final trashcans = await supabase
  .from('trashcans')
  .select()
  .eq('is_active', true)
  .order('name');
```

### Get Full Trashcans
```dart
final fullTrashcans = await supabase
  .from('trashcans')
  .select()
  .eq('status', 'full')
  .order('last_updated_at', ascending: false);
```

### Get Trashcans by Location
```dart
// Get trashcans near a coordinate (requires PostGIS)
final nearbyTrashcans = await supabase
  .from('trashcans')
  .select()
  .eq('is_active', true);
  // Note: Implement distance calculation in Dart or use a custom function
```

### Add New Trashcan
```dart
final trashcanId = await supabase.rpc('add_trashcan', params: {
  'p_name': 'SSU Main Building',
  'p_location': 'Main Campus',
  'p_latitude': 11.2431,
  'p_longitude': 124.9908,
  'p_device_id': 'TC-001',
  'p_sensor_type': 'Ultrasonic',
});
```

### Update Trashcan Location
```dart
await supabase.rpc('update_trashcan_location', params: {
  'p_trashcan_id': trashcanId,
  'p_name': 'New Name',
  'p_location': 'New Location',
  'p_latitude': 11.2432,
  'p_longitude': 124.9909,
});
```

### Update Fill Level
```dart
await supabase.rpc('update_trashcan_fill_level', params: {
  'p_trashcan_id': trashcanId,
  'p_fill_level': 0.75, // 75%
});

// Or direct update
await supabase
  .from('trashcans')
  .update({'fill_level': 0.75})
  .eq('id', trashcanId);
```

### Mark Trashcan as Emptied
```dart
await supabase.rpc('mark_trashcan_emptied', params: {
  'p_trashcan_id': trashcanId,
});
```

### Delete Trashcan
```dart
await supabase.rpc('delete_trashcan', params: {
  'p_trashcan_id': trashcanId,
});
```

### Get Trashcan Statistics
```dart
final stats = await supabase.rpc('get_trashcan_stats');
// Returns: {total: 10, empty: 3, half: 4, full: 2, maintenance: 1}
```

## Task Management

### Get All Tasks
```dart
final tasks = await supabase
  .from('tasks')
  .select('*, trashcans(*), users!tasks_assigned_staff_id_fkey(*)')
  .order('created_at', ascending: false);
```

### Get Staff's Tasks
```dart
final myTasks = await supabase
  .from('tasks')
  .select('*, trashcans(*)')
  .eq('assigned_staff_id', staffId)
  .order('due_date');
```

### Get Pending Tasks
```dart
final pendingTasks = await supabase
  .from('tasks')
  .select('*, trashcans(*), users!tasks_assigned_staff_id_fkey(*)')
  .eq('status', 'pending')
  .order('priority', ascending: false);
```

### Create Task
```dart
final taskId = await supabase.rpc('create_task', params: {
  'p_title': 'Empty Trashcan #1',
  'p_description': 'Trashcan is full and needs attention',
  'p_trashcan_id': trashcanId,
  'p_assigned_staff_id': staffId,
  'p_created_by_admin_id': adminId,
  'p_priority': 'urgent', // low, medium, high, urgent
  'p_due_date': DateTime.now().add(Duration(hours: 4)).toIso8601String(),
});
```

### Update Task Status
```dart
// Start task
await supabase.rpc('update_task_status', params: {
  'p_task_id': taskId,
  'p_status': 'in_progress',
});

// Complete task
await supabase.rpc('update_task_status', params: {
  'p_task_id': taskId,
  'p_status': 'completed',
  'p_completion_notes': 'Task completed successfully',
});

// Cancel task
await supabase.rpc('update_task_status', params: {
  'p_task_id': taskId,
  'p_status': 'cancelled',
});
```

### Reassign Task
```dart
await supabase.rpc('reassign_task', params: {
  'p_task_id': taskId,
  'p_new_staff_id': newStaffId,
});
```

### Delete Task
```dart
await supabase
  .from('tasks')
  .delete()
  .eq('id', taskId);
```

## Notifications

### Get User's Notifications
```dart
final notifications = await supabase
  .from('notifications')
  .select()
  .or('user_id.eq.$userId,user_id.is.null')
  .order('created_at', ascending: false)
  .limit(50);
```

### Get Unread Notifications
```dart
final unread = await supabase
  .from('notifications')
  .select()
  .eq('user_id', userId)
  .eq('is_read', false)
  .order('created_at', ascending: false);
```

### Mark Notification as Read
```dart
await supabase.rpc('mark_notification_read', params: {
  'p_notification_id': notificationId,
});
```

### Mark All as Read
```dart
final count = await supabase.rpc('mark_all_notifications_read', params: {
  'p_user_id': userId,
});
```

### Get Notification Count
```dart
final count = await supabase
  .from('notifications')
  .select('id', const FetchOptions(count: CountOption.exact))
  .eq('user_id', userId)
  .eq('is_read', false);

print('Unread: ${count.count}');
```

## Dashboard Statistics

### Get Admin Dashboard Stats
```dart
final stats = await supabase.rpc('get_admin_dashboard_stats');
print(stats);
// Returns comprehensive statistics for the dashboard
```

### Get Staff Performance
```dart
final performance = await supabase.rpc('get_staff_performance', params: {
  'p_staff_id': staffId,
  'p_start_date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
  'p_end_date': DateTime.now().toIso8601String(),
});
```

### Get Trashcan Report
```dart
final report = await supabase.rpc('get_trashcan_report', params: {
  'p_trashcan_id': trashcanId, // or null for all
  'p_start_date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
  'p_end_date': DateTime.now().toIso8601String(),
});
```

## Real-time Subscriptions

### Listen to Trashcan Changes
```dart
final subscription = supabase
  .from('trashcans')
  .stream(primaryKey: ['id'])
  .listen((List<Map<String, dynamic>> data) {
    // Update UI with new data
    print('Trashcans updated: $data');
  });

// Don't forget to cancel when done
subscription.cancel();
```

### Listen to New Tasks
```dart
final taskSubscription = supabase
  .from('tasks')
  .stream(primaryKey: ['id'])
  .eq('assigned_staff_id', staffId)
  .listen((data) {
    print('Tasks updated: $data');
  });
```

### Listen to Notifications
```dart
final notificationSubscription = supabase
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) {
    // Show notification in UI
    print('New notification: $data');
  });
```

## Activity Logging

### Get Activity Logs (Admin)
```dart
final logs = await supabase
  .from('activity_logs')
  .select('*, users(*)')
  .order('created_at', ascending: false)
  .limit(100);
```

### Get User Activity
```dart
final userActivity = await supabase
  .from('activity_logs')
  .select()
  .eq('user_id', userId)
  .order('created_at', ascending: false)
  .limit(50);
```

## System Settings

### Get Settings
```dart
final settings = await supabase
  .from('system_settings')
  .select();
```

### Get Specific Setting
```dart
final threshold = await supabase
  .from('system_settings')
  .select('value')
  .eq('key', 'alert_threshold')
  .single();
```

### Update Setting (Admin)
```dart
await supabase
  .from('system_settings')
  .update({
    'value': '85',
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': adminId,
  })
  .eq('key', 'alert_threshold');
```

## Error Handling

```dart
try {
  final data = await supabase
    .from('users')
    .select()
    .eq('id', userId);
  
  // Handle success
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
  // Handle database errors
} on AuthException catch (error) {
  print('Auth error: ${error.message}');
  // Handle authentication errors
} catch (error) {
  print('Unexpected error: $error');
  // Handle other errors
}
```

## Best Practices

1. **Use RPC Functions**: For complex operations, use the RPC functions instead of raw queries
2. **Handle Errors**: Always wrap database calls in try-catch blocks
3. **Use Streams**: For real-time data, use Supabase streams/subscriptions
4. **Cancel Subscriptions**: Always cancel subscriptions when widgets are disposed
5. **Batch Operations**: For multiple operations, consider using transactions
6. **Optimize Queries**: Only select the fields you need
7. **Use Indexes**: The schema has indexes on common query fields
8. **Security**: Never expose service keys in client code

## Example: Complete Flow

### Creating and Assigning a Task

```dart
Future<void> createAndAssignTask({
  required String title,
  required String description,
  required String trashcanId,
  required String staffId,
  required String adminId,
}) async {
  try {
    // Create task (automatically creates notification)
    final taskId = await supabase.rpc('create_task', params: {
      'p_title': title,
      'p_description': description,
      'p_trashcan_id': trashcanId,
      'p_assigned_staff_id': staffId,
      'p_created_by_admin_id': adminId,
      'p_priority': 'high',
      'p_due_date': DateTime.now().add(Duration(hours: 4)).toIso8601String(),
    });
    
    print('Task created: $taskId');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task assigned successfully')),
    );
  } catch (error) {
    print('Error creating task: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to create task')),
    );
  }
}
```

---

For more information, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

