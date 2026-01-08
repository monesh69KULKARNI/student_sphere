# Debug Announcements Not Showing

## 🔍 Debug Steps

### Step 1: Run the App
1. Open student dashboard
2. Click on "Announcements" tab (bottom navigation)
3. Check debug console for these messages:

```
🔍 Loading announcements...
  isPublicOnly: false
🔍 AnnouncementService.getUserAnnouncements()
  Current user: YOUR_UID (student)
  Total announcements available: X
  🔍 Filtering announcements...
  Total announcements: X
  Search query: ""
  Priority filter: "all"
  Final filtered count: X
```

### Step 2: Check What Debug Shows

**If you see "Total announcements available: 0"**
- Problem: Database query returning empty results
- Solution: Check RLS policies or table data

**If you see "Total announcements available: X" but "Final filtered count: 0"**
- Problem: Filtering logic removing all announcements
- Solution: Check filtering conditions

**If you see announcements but they don't display**
- Problem: UI state not updating
- Solution: Check setState() calls

### Step 3: Test Database Query
Run this SQL in Supabase to check data:
```sql
SELECT COUNT(*) as total_announcements FROM announcements;
SELECT id, title, author_name, is_public, created_at 
FROM announcements 
ORDER BY created_at DESC 
LIMIT 5;
```

### Step 4: Common Issues & Solutions

**Issue 1: RLS blocking reads**
```sql
-- Temporarily disable RLS for testing
ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;
```

**Issue 2: Field name mismatch**
- Check if database has snake_case or camelCase fields

**Issue 3: User not authenticated**
- Check if user is properly logged in

### Step 5: Report Back
Share what debug console shows so we can identify the exact issue!
