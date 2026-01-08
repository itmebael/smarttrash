# Task Completion Location Verification System

## Overview
When staff clicks "Complete" on a task, a popup appears showing:
1. **Map with trashcan position** - Shows where the trashcan is located
2. **Current location capture** - Captures staff's current GPS location
3. **Location verification** - Verifies staff is within acceptable range (default: 50 meters)
4. **Photo capture** (optional) - Allows staff to take a photo as evidence
5. **Automatic task completion** - Completes task if location is verified

## Database Tables

### 1. `task_completion_verifications` Table
Stores all location verification data when tasks are completed.

**Key Columns:**
- `task_id` - Reference to the task
- `trashcan_id` - Reference to the trashcan
- `staff_id` - Staff member who completed the task
- `verified_latitude`, `verified_longitude` - Staff's actual location
- `expected_latitude`, `expected_longitude` - Trashcan's location
- `distance_from_trashcan` - Calculated distance in meters
- `is_within_range` - Boolean (true if within 50m)
- `photo_url` - URL to photo evidence
- `verification_status` - pending, verified, failed, manual_override

### 2. Storage Bucket: `task-completion-photos`
Stores photo evidence for task completions.

**Configuration:**
- **Name:** `task-completion-photos`
- **Public:** false (private, requires authentication)
- **File size limit:** 10MB
- **Allowed types:** jpg, jpeg, png, webp
- **Path format:** `{staff_id}/{task_id}/{timestamp}.{ext}`

## Setup Instructions

### Step 1: Run SQL Files

1. **Run `TASK_COMPLETION_VERIFICATION.sql`** in Supabase SQL Editor:
   - Creates `task_completion_verifications` table
   - Creates helper functions
   - Sets up RLS policies
   - Creates views for easy querying

2. **Run `STORAGE_BUCKET_SETUP.sql`** (for reference):
   - Provides bucket configuration
   - Shows policy setup instructions

### Step 2: Create Storage Bucket

**Option A: Via Supabase Dashboard**
1. Go to **Storage** → **Buckets**
2. Click **"New bucket"**
3. Configure:
   - **Name:** `task-completion-photos`
   - **Public:** ❌ Unchecked (private)
   - **File size limit:** `10485760` (10MB)
   - **Allowed MIME types:** `image/jpeg, image/png, image/webp`

**Option B: Via SQL**
```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-completion-photos',
  'task-completion-photos',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);
```

### Step 3: Set Up Storage Policies

Go to **Storage** → **Policies** → **task-completion-photos**

**Policy 1: Staff can upload photos**
- **Policy name:** "Staff can upload task completion photos"
- **Allowed operation:** INSERT
- **Policy definition:**
```sql
(bucket_id = 'task-completion-photos'::text) 
AND (auth.uid()::text = (storage.foldername(name))[1])
AND (storage.extension(name) = ANY (ARRAY['jpg'::text, 'jpeg'::text, 'png'::text, 'webp'::text]))
```

**Policy 2: Staff can view own photos**
- **Policy name:** "Staff can view own task completion photos"
- **Allowed operation:** SELECT
- **Policy definition:**
```sql
(bucket_id = 'task-completion-photos'::text) 
AND (auth.uid()::text = (storage.foldername(name))[1])
```

**Policy 3: Admins can view all photos**
- **Policy name:** "Admins can view all task completion photos"
- **Allowed operation:** SELECT
- **Policy definition:**
```sql
(bucket_id = 'task-completion-photos'::text) 
AND (EXISTS ( SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'::text))
```

**Policy 4: Admins can delete photos**
- **Policy name:** "Admins can delete task completion photos"
- **Allowed operation:** DELETE
- **Policy definition:**
```sql
(bucket_id = 'task-completion-photos'::text) 
AND (EXISTS ( SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'::text))
```

## Usage

### For Staff: Completing a Task

1. **Click "Complete" button** on an in-progress task
2. **Popup appears** showing:
   - Map with trashcan location (red marker)
   - Staff's current location (blue marker)
   - Distance from trashcan
   - "Capture Location" button
3. **Click "Capture Location"** to:
   - Get current GPS coordinates
   - Calculate distance from trashcan
   - Verify if within range (50 meters)
4. **Optional: Take Photo**
   - Click camera icon
   - Take/select photo
   - Photo is uploaded to storage bucket
5. **Click "Complete Task"**
   - If within range: Task is automatically completed
   - If outside range: Shows error, requires admin override

### For Admins: Reviewing Verifications

**View all verifications:**
```sql
SELECT * FROM verification_details_view 
ORDER BY verified_at DESC;
```

**View failed verifications:**
```sql
SELECT * FROM failed_verifications_view;
```

**Manually override a failed verification:**
```sql
SELECT override_verification(
  'verification-id-here',
  'admin-user-id-here',
  'Staff was at correct location, GPS issue'
);
```

## API Functions

### 1. Verify Task Completion
```sql
SELECT verify_task_completion(
  p_task_id := 'task-uuid',
  p_staff_id := 'staff-uuid',
  p_verified_latitude := 12.8797,
  p_verified_longitude := 124.8447,
  p_verified_accuracy := 10.5,
  p_photo_url := 'https://...',
  p_acceptable_range_meters := 50
);
```

### 2. Get Verification Details
```sql
SELECT * FROM get_verification_details('verification-id');
```

### 3. Generate Photo Path
```sql
SELECT generate_task_photo_path(
  'staff-uuid',
  'task-uuid',
  'jpg'
);
-- Returns: staff-uuid/task-uuid/1234567890.jpg
```

## Frontend Implementation

### JavaScript/Flutter Flow:

1. **User clicks "Complete"**
2. **Show popup with:**
   - Map widget showing trashcan location
   - Current location request
   - Distance calculation
3. **Capture location:**
   ```javascript
   navigator.geolocation.getCurrentPosition(
     (position) => {
       const lat = position.coords.latitude;
       const lng = position.coords.longitude;
       const accuracy = position.coords.accuracy;
       // Calculate distance and verify
     }
   );
   ```
4. **Upload photo (optional):**
   ```javascript
   const file = // from camera/file picker
   const path = `${staffId}/${taskId}/${timestamp}.jpg`;
   await supabase.storage
     .from('task-completion-photos')
     .upload(path, file);
   ```
5. **Call verification function:**
   ```javascript
   const { data } = await supabase.rpc('verify_task_completion', {
     p_task_id: taskId,
     p_staff_id: staffId,
     p_verified_latitude: lat,
     p_verified_longitude: lng,
     p_photo_url: photoUrl,
     // ... other params
   });
   ```

## Configuration

### Adjustable Settings:

**Acceptable Range (default: 50 meters):**
```sql
-- Change in verify_task_completion function call
p_acceptable_range_meters := 100  -- Allow 100 meters
```

**File Size Limit:**
- Set in bucket configuration (default: 10MB)

**Allowed File Types:**
- Set in bucket configuration (default: jpg, jpeg, png, webp)

## Security

- ✅ RLS policies ensure staff can only see their own verifications
- ✅ Admins can view all verifications
- ✅ Photo uploads require authentication
- ✅ Location verification prevents fake completions
- ✅ Manual override requires admin privileges

## Troubleshooting

### Location not captured?
- Check browser/device location permissions
- Ensure GPS is enabled
- Check location accuracy settings

### Photo upload fails?
- Check file size (must be < 10MB)
- Check file type (must be jpg, png, or webp)
- Verify storage bucket exists
- Check storage policies

### Verification fails?
- Check if staff is within 50 meters of trashcan
- Verify trashcan has valid coordinates
- Check GPS accuracy (may need higher accuracy)

### Task not completing?
- Check if verification status is 'verified'
- Verify task is in 'in_progress' status
- Check for database errors in logs

## Example Queries

**Get verification for a specific task:**
```sql
SELECT * FROM verification_details_view 
WHERE task_id = 'task-uuid-here';
```

**Get all verifications by a staff member:**
```sql
SELECT * FROM verification_details_view 
WHERE staff_id = 'staff-uuid-here'
ORDER BY verified_at DESC;
```

**Get verification statistics:**
```sql
SELECT 
  verification_status,
  COUNT(*) as count,
  AVG(distance_from_trashcan) as avg_distance,
  MAX(distance_from_trashcan) as max_distance
FROM task_completion_verifications
GROUP BY verification_status;
```

**Get verifications outside range:**
```sql
SELECT * FROM verification_details_view
WHERE is_within_range = false
ORDER BY distance_from_trashcan DESC;
```






