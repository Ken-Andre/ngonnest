# Cloud Database Migration Guide

## Issue: Database Schema Mismatch

The error you're seeing:
```
DatabaseException(datatype mismatch (code 20 SQLITE_MISMATCH))
```

This occurs because the local database was migrated to v12 (adding `percentage` column to `budget_categories`), but the cloud database (Supabase) doesn't have this column yet.

## Solution: Apply Cloud Migration

### Step 1: Backup Your Database (IMPORTANT!)

Before applying any migration, backup your Supabase database:

1. Go to https://supabase.com/dashboard
2. Select your project: `twihbdmgqrsvfpyuhkoz`
3. Navigate to **Database** → **Backups**
4. Create a manual backup or verify automatic backups are enabled

### Step 2: Apply the Migration

#### Option A: Using Supabase Dashboard (Recommended)

1. Open your Supabase project dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of:
   ```
   code/flutter/ngonnest_app/supabase/migrations/20241113_add_percentage_to_budget_categories.sql
   ```
5. Paste into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for confirmation: "Success. No rows returned"

#### Option B: Using Supabase CLI

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref twihbdmgqrsvfpyuhkoz

# Apply migration
cd code/flutter/ngonnest_app
supabase db push
```

### Step 3: Verify Migration

Run this query in Supabase SQL Editor to verify:

```sql
-- Check if percentage column exists
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'budget_categories' 
  AND column_name = 'percentage';

-- Check schema version
SELECT * FROM public.schema_versions WHERE version = 12;

-- View sample data
SELECT id, name, limit_amount, percentage, month
FROM public.budget_categories
LIMIT 5;
```

Expected results:
- Column `percentage` should exist with type `real`
- Schema version 12 should be recorded
- Existing budget categories should have calculated percentages

### Step 4: Test Sync

After applying the migration:

1. **Clear local data** (optional, for clean test):
   - In app: Settings → Advanced → Clear Local Data
   
2. **Test import from cloud**:
   - Open NgonNest app
   - Go to Settings → Cloud Sync
   - Click "Import from Cloud"
   - Should complete without errors

3. **Test export to cloud**:
   - Make a local change (add a budget category)
   - Sync to cloud
   - Verify in Supabase dashboard

## What the Migration Does

The migration script (`20241113_add_percentage_to_budget_categories.sql`):

1. **Adds `percentage` column**:
   - Type: `real` (floating point number)
   - Constraint: NOT NULL, between 0.0 and 1.0
   - Default: 0.25 (25%)

2. **Calculates percentages for existing data**:
   - Groups by household and month
   - Calculates each category's percentage of total budget
   - Updates all existing records

3. **Creates performance index**:
   - Index on `(household_id, month)` for faster queries

4. **Records migration**:
   - Adds entry to `schema_versions` table

## Troubleshooting

### Error: "column already exists"

If you see this error, the migration was already applied. Verify with:

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'budget_categories' AND column_name = 'percentage';
```

### Error: "permission denied"

Make sure you're logged in as the project owner or have sufficient permissions.

### Data looks wrong after migration

The migration calculates percentages based on existing `limit_amount` values. If these look incorrect:

```sql
-- Recalculate percentages for a specific household
UPDATE public.budget_categories
SET percentage = limit_amount / (
  SELECT SUM(limit_amount) 
  FROM public.budget_categories AS bc2
  WHERE bc2.household_id = budget_categories.household_id
    AND bc2.month = budget_categories.month
)
WHERE household_id = 'YOUR_HOUSEHOLD_ID'
  AND month = '2024-11';
```

## Future Migrations

When adding new columns or tables:

1. **Update local schema** in `lib/db.dart`
2. **Create local migration** in `DatabaseService`
3. **Create cloud migration** in `supabase/migrations/`
4. **Test locally** first
5. **Apply to cloud** using this guide
6. **Update documentation**

## Rollback (Emergency Only)

If something goes wrong and you need to rollback:

```sql
-- Remove percentage column (WARNING: Deletes data!)
ALTER TABLE public.budget_categories DROP COLUMN IF EXISTS percentage;

-- Remove schema version entry
DELETE FROM public.schema_versions WHERE version = 12;

-- Restore from backup if needed
```

## Contact

If you encounter issues:
1. Check the error logs in Supabase Dashboard → Logs
2. Verify your local database version: Check `schema_version` in local SQLite
3. Compare schemas: Local vs Cloud

## Summary

✅ **Before migration**: Local DB v12, Cloud DB v11 → Sync fails  
✅ **After migration**: Local DB v12, Cloud DB v12 → Sync works  

The migration is **safe** and **reversible** (with backup).
