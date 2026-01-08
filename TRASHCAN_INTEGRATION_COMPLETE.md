# 🗑️ Trashcan Table Integration - Complete Guide

## 🎉 What Was Implemented

I've successfully integrated the `trashcans` table with your Admin Dashboard Bin Status feature. Now you have a complete trashcan management system!

## 📋 Features Added

### 1. Updated Trashcan Model
**File**: `lib/core/models/trashcan_model.dart`

Added new fields to match your database schema:
- `deviceId` - Unique device identifier (e.g., ESP32-001)
- `sensorType` - Type of sensor used (e.g., Ultrasonic)
- `batteryLevel` - Battery percentage (0-100)
- `isActive` - Whether the trashcan is active

Added helper methods:
- `batteryStatusText` - Returns "Good", "Fair", "Low", or "Critical"
- `needsBatteryReplace` - Boolean check for low battery (<20%)
- `sensorTypeDisplay` - Display sensor type or "Unknown"

### 2. New Trashcan Service
**File**: `lib/core/services/trashcan_service.dart`

Complete CRUD operations:
- ✅ `getAllTrashcans()` - Fetch all active trashcans
- ✅ `getTrashcanById(id)` - Get specific trashcan
- ✅ `getTrashcansByStatus(status)` - Filter by status
- ✅ `getTrashcansNeedingAttention()` - Get full/maintenance bins
- ✅ `getTrashcansWithLowBattery()` - Get bins with battery <20%
- ✅ `getTrashcanByDeviceId(deviceId)` - Find by device ID
- ✅ `updateTrashcanStatus(id, status, fillLevel)` - Update status
- ✅ `updateBatteryLevel(id, level)` - Update battery
- ✅ `markAsEmptied(id)` - Mark as emptied
- ✅ `watchTrashcans()` - Real-time stream
- ✅ `insertTrashcan()` - Add new trashcan
- ✅ `deactivateTrashcan(id)` - Soft delete
- ✅ `getTrashcanStatistics()` - Get stats by status

### 3. Trashcan Provider
**File**: `lib/core/providers/trashcan_provider.dart`

Riverpod state management:
- `trashcansProvider` - Main state provider
- `trashcansNeedingAttentionProvider` - Full/maintenance bins
- `trashcansLowBatteryProvider` - Low battery bins  
- `trashcansStreamProvider` - Real-time updates
- `trashcanStatisticsProvider` - Statistics
- `trashcanStatusCountsProvider` - Count by status

### 4. Updated Admin Dashboard
**File**: `lib/features/dashboard/presentation/pages/admin_dashboard_page.dart`

New UI Components:
- **Trashcan Status Section** - Displays all active trashcans
- **Trashcan Cards** - Beautiful cards showing:
  - Name and location
  - Status with emoji
  - Fill level progress bar
  - Battery level indicator
  - Color-coded by status

- **Trashcan Detail Modal** - Click any card to see:
  - Large fill level display
  - Location information
  - GPS coordinates
  - Device ID
  - Sensor type
  - Battery status
  - Last updated time
  - Notes (if any)
  - Action buttons

## 🎨 Status System

| Status | Color | Emoji | Fill Level | Use Case |
|--------|-------|-------|------------|----------|
| **Empty** | 🟢 Green | ✅ | 0-30% | Recently emptied |
| **Half** | 🟡 Orange | 🟡 | 30-70% | Needs monitoring |
| **Full** | 🔴 Red | 🔴 | 70-100% | Needs collection |
| **Maintenance** | 🔵 Blue | 🔧 | Any | Needs repair |

## 📊 Database Schema

Your `trashcans` table structure:

```sql
create table public.trashcans (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  location text NOT NULL,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  status text NOT NULL DEFAULT 'empty',
  fill_level numeric(3, 2) DEFAULT 0.0,
  device_id text UNIQUE,
  sensor_type text,
  battery_level integer CHECK (battery_level >= 0 AND battery_level <= 100),
  last_emptied_at timestamptz,
  last_updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  notes text,
  is_active boolean DEFAULT true
);
```

## 🚀 Quick Start

### Step 1: Insert Test Data

Run the SQL script in Supabase SQL Editor:
```bash
File: supabase/INSERT_TRASHCAN_TEST_DATA.sql
```

This creates 8 test trashcans with various statuses and battery levels.

### Step 2: Verify Data

```sql
SELECT * FROM public.trashcans WHERE is_active = true;
```

### Step 3: View in App

1. Open your app
2. Login as Admin
3. Click **Map** tab in bottom navigation
4. Scroll down to see **"Trashcan Status"** section
5. You'll see 8 trashcan cards
6. Click any card to view details

## 💡 Usage Examples

### Insert New Trashcan

```sql
INSERT INTO public.trashcans (
  name, location, latitude, longitude,
  status, fill_level, device_id, sensor_type,
  battery_level, notes
)
VALUES (
  'Science Building Bin',
  'Science Department',
  11.771098, 124.886578,
  'empty', 0.0,
  'ESP32-009', 'Ultrasonic',
  100,
  'Newly installed'
);
```

### Update Trashcan Status

```sql
UPDATE public.trashcans 
SET 
  status = 'full',
  fill_level = 0.90,
  last_updated_at = NOW()
WHERE device_id = 'ESP32-001';
```

### Mark as Emptied

```sql
UPDATE public.trashcans 
SET 
  status = 'empty',
  fill_level = 0.0,
  last_emptied_at = NOW(),
  last_updated_at = NOW()
WHERE id = 'your-id-here';
```

### Find Full Bins

```sql
SELECT name, location, fill_level
FROM public.trashcans
WHERE status = 'full' AND is_active = true
ORDER BY fill_level DESC;
```

### Find Low Battery Bins

```sql
SELECT name, location, battery_level
FROM public.trashcans
WHERE battery_level < 20 AND is_active = true
ORDER BY battery_level ASC;
```

## 🔧 Programmatic Usage (In App)

### Fetch All Trashcans

```dart
final trashcansAsync = ref.watch(trashcansProvider);

trashcansAsync.when(
  data: (trashcans) {
    // Display trashcans
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Get Bins Needing Attention

```dart
final urgentBins = await ref.read(trashcanServiceProvider)
    .getTrashcansNeedingAttention();
```

### Update Status

```dart
await ref.read(trashcansProvider.notifier)
    .updateStatus(id, TrashcanStatus.full, 0.95);
```

### Mark as Emptied

```dart
await ref.read(trashcansProvider.notifier)
    .markAsEmptied(id);
```

## 🎯 Key Features

### Battery Monitoring
- **Good**: 80-100% (Green)
- **Fair**: 50-79% (Yellow)  
- **Low**: 20-49% (Orange)
- **Critical**: 0-19% (Red)

Bins with battery <20% show a red battery icon and can be filtered:
```dart
final lowBatteryBins = await ref.read(trashcanServiceProvider)
    .getTrashcansWithLowBattery();
```

### Device Management
Each trashcan has a unique `device_id` (e.g., ESP32-001) that can be used to:
- Track specific hardware
- Update status from IoT devices
- Identify maintenance needs

### Real-time Updates
Use the stream provider for live updates:
```dart
final trashcansStream = ref.watch(trashcansStreamProvider);
```

### Soft Delete
Trashcans are never hard-deleted. Use `is_active` flag:
```dart
await ref.read(trashcanServiceProvider).deactivateTrashcan(id);
```

## 📱 UI Components

### Trashcan Card
Shows at a glance:
- Name (e.g., "Library Bin")
- Status badge (EMPTY, HALF, FULL, MAINTENANCE)
- Fill level progress bar
- Battery level (if available)
- Color-coded by status

### Detail Modal
Comprehensive information:
- Header with name and status
- Large fill percentage display
- Location details
- GPS coordinates
- Device information
- Sensor type
- Battery status with indicator
- Last updated timestamp
- Notes section
- Action buttons (View on Map, Refresh)

## 🔄 Integration with Smart Bins

The system now supports BOTH:
1. **Smart Bins** (`smart_bin` table) - Raw sensor readings
2. **Trashcans** (`trashcans` table) - Managed assets

You can:
- Keep smart_bin for IoT device data
- Use trashcans for inventory management
- Link them via `device_id` field
- Display both in different sections

## 🐛 Troubleshooting

### No Trashcans Showing
1. Check if data exists: `SELECT * FROM trashcans WHERE is_active = true`
2. Verify Supabase connection
3. Check browser console for errors
4. Try the refresh button

### Wrong Fill Levels
- `fill_level` should be 0.0 to 1.0 (0% to 100%)
- Use: `UPDATE trashcans SET fill_level = 0.5 WHERE id = 'xxx'`

### Battery Not Showing
- Battery level is optional
- Insert with: `battery_level = 85`
- Will show indicator if present

### Coordinates Issue
- Latitude: -90 to 90 (numeric(10, 8))
- Longitude: -180 to 180 (numeric(11, 8))
- Example: `latitude = 11.771098, longitude = 124.886578`

## 📈 Statistics Dashboard

Get comprehensive statistics:
```dart
final stats = await ref.read(trashcanStatisticsProvider.future);
// Returns:
// {
//   'total': 8,
//   'empty': 3,
//   'half': 2,
//   'full': 2,
//   'maintenance': 1,
//   'lowBattery': 1
// }
```

## 🔮 Future Enhancements

Potential features:
- [ ] Collection route optimization
- [ ] Predictive maintenance based on battery trends
- [ ] Historical fill level charts
- [ ] Automated alerts for full bins
- [ ] QR code generation for trashcans
- [ ] Collection task automation
- [ ] Analytics dashboard
- [ ] Export reports (PDF/Excel)

## ✅ Summary

You now have a fully-functional trashcan management system that:
- ✅ Displays all active trashcans
- ✅ Shows real-time status
- ✅ Tracks battery levels
- ✅ Monitors device information
- ✅ Provides GPS coordinates
- ✅ Supports CRUD operations
- ✅ Works with IoT devices
- ✅ Beautiful, intuitive UI
- ✅ Real-time updates
- ✅ Complete documentation

## 📚 Files Created/Modified

**Created:**
- `lib/core/services/trashcan_service.dart` - Service layer
- `lib/core/providers/trashcan_provider.dart` - State management
- `supabase/INSERT_TRASHCAN_TEST_DATA.sql` - Test data script
- `TRASHCAN_INTEGRATION_COMPLETE.md` - This guide

**Modified:**
- `lib/core/models/trashcan_model.dart` - Added new fields
- `lib/features/dashboard/presentation/pages/admin_dashboard_page.dart` - UI updates

## 🎉 Ready to Use!

Your trashcan integration is complete! Just add data and start managing your bins.

For questions or issues, refer to:
- This guide for trashcan management
- `BIN_STATUS_FEATURE_GUIDE.md` for smart bin features
- `SMART_BIN_STATUS_SUMMARY.md` for implementation details







