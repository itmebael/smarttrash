# 🗑️ Trashcan Save to Database - Complete Guide

## ✅ Current Setup

Your app is **fully configured** to save trashcans to the `public.trashcans` table in Supabase.

### Database Table: `public.trashcans`
```sql
- id (UUID, auto-generated)
- name (TEXT, required)
- location (TEXT, required)
- latitude (NUMERIC(10,8), required)
- longitude (NUMERIC(11,8), required)
- status (TEXT, default 'empty')
- fill_level (NUMERIC(3,2), default 0.0)
- device_id (TEXT, nullable)
- sensor_type (TEXT, nullable)
- battery_level (INTEGER, nullable)
- last_emptied_at (TIMESTAMP, nullable)
- last_updated_at (TIMESTAMP, default now())
- created_at (TIMESTAMP, default now())
- notes (TEXT, nullable)
- is_active (BOOLEAN, default true)
```

### RPC Function: `add_trashcan`
Located in: `supabase/migrations/20250122_helper_functions.sql`

**Parameters:**
- `p_name` (TEXT) - Trashcan name
- `p_location` (TEXT) - Location description
- `p_latitude` (DECIMAL) - Latitude coordinate
- `p_longitude` (DECIMAL) - Longitude coordinate
- `p_device_id` (TEXT, optional) - Device ID
- `p_sensor_type` (TEXT, optional) - Sensor type

**Returns:** UUID of the newly created trashcan

**Default Values Set:**
- `status`: 'empty'
- `fill_level`: 0.0
- `is_active`: true
- `created_at`: NOW()
- `last_updated_at`: NOW()

## 🔄 How the Save Process Works

### Step 1: User Selects Location
1. Admin opens location picker dialog
2. **Satellite view** loads by default
3. Admin taps on map
4. **Green trashcan marker** appears
5. Coordinates shown in info box
6. Admin clicks "Use This Location"

### Step 2: Fill Form
1. Coordinates auto-fill (read-only)
2. Admin enters:
   - ✅ Bin Name (required)
   - ✅ Location description (required)
   - ⭕ Device ID (optional)
   - ⭕ Sensor Type (optional)

### Step 3: Save to Database
1. Admin clicks **"💾 Save Trashcan to Database"**
2. App validates all required fields
3. Calls `addNewTrashcan()` function

### Step 4: Database Insert
```dart
// Flutter calls Supabase RPC
final response = await supabase.rpc('add_trashcan', params: {
  'p_name': name,
  'p_location': location,
  'p_latitude': latitude,
  'p_longitude': longitude,
  'p_device_id': deviceId,
  'p_sensor_type': sensorType,
});
```

### Step 5: Confirmation
- ✅ Success: "Trashcan '[name]' saved to database!"
- ❌ Error: "Failed to save trashcan to database" + RETRY button
- 🔄 Map auto-reloads to show new trashcan
- 📍 Map centers on newly added trashcan

## 📊 Debug Console Output

When you save a trashcan, you'll see:

```
🗑️ Attempting to add trashcan: Main Building Bin at (12.879700, 124.844700)
📍 addNewTrashcan called with:
   Name: Main Building Bin
   Location: SSU Main Campus
   Lat: 12.879700, Lng: 124.844700
   Device ID: TC-001
   Sensor Type: Ultrasonic
🔄 Calling add_trashcan RPC function...
✅ RPC response: [uuid-here]
   Response type: String
💾 Trashcan saved with ID: [uuid-here]
🔄 Reloading trashcans list...
📍 SimpleMapProvider: Starting to load trashcans...
🔄 SimpleMapProvider: Fetching from Supabase...
📦 SimpleMapProvider: Got response with X items
✅ SimpleMapProvider: Successfully loaded X trashcans
✅ Trashcan list reloaded. Total count: X
```

## 🔍 How to Verify Data is Saved

### Method 1: Check in Supabase Dashboard
1. Go to your Supabase project
2. Click "Table Editor"
3. Select `trashcans` table
4. Look for your newly added trashcan
5. Check the `created_at` timestamp

### Method 2: Run SQL Query
Use the verification file: `VERIFY_TRASHCAN_SAVE.sql`

```sql
-- View all trashcans
SELECT 
    id, name, location, latitude, longitude, 
    status, created_at
FROM public.trashcans
ORDER BY created_at DESC;

-- View most recent
SELECT * FROM public.trashcans
ORDER BY created_at DESC
LIMIT 1;
```

### Method 3: Check the App
1. After saving, the map should reload
2. New trashcan marker should appear
3. Tap the marker to see details
4. Verify name and location match

## ⚠️ Troubleshooting

### Error: "Database not available"
**Cause:** Supabase client is not initialized
**Fix:** Check Supabase credentials in app

### Error: "Failed to add trashcan"
**Possible causes:**
1. **Network issue** - Check internet connection
2. **Permission issue** - Verify RPC function has SECURITY DEFINER
3. **Invalid data** - Check coordinates are valid numbers
4. **Duplicate device_id** - Device ID must be unique

**Check console for details:**
```
❌ ERROR in addNewTrashcan:
   Error: [specific error message]
   Type: [error type]
```

### Trashcan Not Appearing on Map
**Possible causes:**
1. **is_active = false** - Check database value
2. **Filter active** - Check map filter settings
3. **Not reloaded** - Refresh the map page

**Fix:**
```sql
-- Ensure trashcan is active
UPDATE public.trashcans 
SET is_active = true 
WHERE id = 'your-trashcan-id';
```

### Coordinates Out of Range
**Error:** Latitude/Longitude validation failed

**Valid ranges:**
- Latitude: -90 to 90
- Longitude: -180 to 180

**For Philippines (typical):**
- Latitude: 4 to 21
- Longitude: 116 to 127

## 🧪 Test the Function Manually

```sql
-- Test adding a trashcan directly in Supabase SQL Editor
SELECT add_trashcan(
    'Test Bin',
    'Test Location',
    12.8797,
    124.8447,
    'TEST-001',
    'Ultrasonic'
);

-- Verify it was added
SELECT * FROM public.trashcans 
WHERE name = 'Test Bin'
ORDER BY created_at DESC
LIMIT 1;

-- Clean up test data
DELETE FROM public.trashcans 
WHERE name = 'Test Bin';
```

## ✅ Expected Database Row

After saving "Main Building Bin":

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Main Building Bin",
  "location": "SSU Main Campus",
  "latitude": 12.87970000,
  "longitude": 124.84470000,
  "status": "empty",
  "fill_level": 0.00,
  "device_id": "TC-001",
  "sensor_type": "Ultrasonic",
  "battery_level": null,
  "last_emptied_at": null,
  "last_updated_at": "2025-01-24T10:30:00Z",
  "created_at": "2025-01-24T10:30:00Z",
  "notes": null,
  "is_active": true
}
```

## 📋 Checklist

Before reporting issues, verify:

- [ ] Supabase project is accessible
- [ ] `add_trashcan` RPC function exists
- [ ] `trashcans` table exists with correct schema
- [ ] App has internet connection
- [ ] All required fields are filled
- [ ] Coordinates are valid numbers
- [ ] Device ID is unique (if provided)
- [ ] Console shows detailed debug logs

## 🎯 Summary

✅ **Database Table:** `public.trashcans` (exists)  
✅ **RPC Function:** `add_trashcan` (configured)  
✅ **App Integration:** Complete with error handling  
✅ **Debug Logging:** Detailed console output  
✅ **User Feedback:** Success/error messages  
✅ **Auto-reload:** Map refreshes after save  

**Everything is ready! Just fill the form and click "Save Trashcan to Database"!** 💾🗑️✨















