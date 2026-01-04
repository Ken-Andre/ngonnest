# Quick Fix: Cloud Sync Error

## Problem
```
DatabaseException(datatype mismatch (code 20 SQLITE_MISMATCH))
INSERT OR REPLACE INTO foyer ... args [46e102b5-88dc-40a7-8a27-edc200306696, 4, 3, appartement, fr, 0]
```

## Root Cause
**CRITICAL**: Local `foyer` table uses INTEGER IDs, but cloud uses UUID strings. This is a fundamental schema mismatch that cannot be fixed with a simple migration.

**Secondary Issue**: Local database has `percentage` column in `budget_categories` table (v12), but cloud database doesn't.

## Quick Fix (5 minutes)

### 1. Open Supabase Dashboard
https://supabase.com/dashboard/project/twihbdmgqrsvfpyuhkoz

### 2. Go to SQL Editor
Click **SQL Editor** in left sidebar → **New Query**

### 3. Run This SQL

```sql
-- Add percentage column
ALTER TABLE public.budget_categories 
ADD COLUMN IF NOT EXISTS percentage real NOT NULL DEFAULT 0.25 
CHECK (percentage >= 0 AND percentage <= 1);

-- Calculate percentages for existing data
DO $$
DECLARE
  household_record RECORD;
  total_limit real;
BEGIN
  FOR household_record IN 
    SELECT DISTINCT household_id, month 
    FROM public.budget_categories 
    WHERE percentage = 0.25
  LOOP
    SELECT COALESCE(SUM(limit_amount), 0) INTO total_limit
    FROM public.budget_categories
    WHERE household_id = household_record.household_id 
      AND month = household_record.month;
    
    IF total_limit > 0 THEN
      UPDATE public.budget_categories
      SET percentage = limit_amount / total_limit
      WHERE household_id = household_record.household_id 
        AND month = household_record.month
        AND percentage = 0.25;
    END IF;
  END LOOP;
END $$;

-- Create index
CREATE INDEX IF NOT EXISTS idx_budget_categories_household_month 
ON public.budget_categories(household_id, month);

-- Record migration
INSERT INTO public.schema_versions (version, description, created_by)
VALUES (12, 'Add percentage column to budget_categories', 'manual_fix')
ON CONFLICT (version) DO NOTHING;
```

### 4. Verify

```sql
-- Should return 1 row showing the percentage column
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'budget_categories' AND column_name = 'percentage';
```

### 5. Test in App

1. Open NgonNest app
2. Go to Settings → Cloud Sync
3. Try "Import from Cloud" again
4. Should work now! ✅

## ⚠️ WAIT! There's a Bigger Problem

After applying the percentage column fix, you'll still get errors because:

**The `foyer` table has incompatible ID types:**
- Local: `id INTEGER` (auto-increment)
- Cloud: `id uuid` (UUID strings)

This requires a more complex migration. See `CRITICAL_SCHEMA_MISMATCH.md` for details.

## Temporary Solution

**Disable cloud import** until the schema mismatch is resolved:

1. Comment out the import functionality in the app
2. Use local-only mode
3. Plan the UUID migration (see CRITICAL_SCHEMA_MISMATCH.md)

---

**For full details**: 
- `CRITICAL_SCHEMA_MISMATCH.md` - The main issue
- `CLOUD_MIGRATION_GUIDE.md` - The percentage column fix (still needed)
