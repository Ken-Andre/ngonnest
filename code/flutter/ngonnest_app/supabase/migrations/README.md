# Supabase Database Migrations

This directory contains SQL migration scripts for the Supabase (cloud) database.

## How to Apply Migrations

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of the migration file
5. Execute the query
6. Verify the migration was successful by checking the `schema_versions` table

### Option 2: Using Supabase CLI

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Apply migration
supabase db push
```

## Migration Files

### 20241113_add_percentage_to_budget_categories.sql

**Purpose**: Adds `percentage` column to `budget_categories` table to support dynamic budget allocation.

**Changes**:
- Adds `percentage` column (real, NOT NULL, default 0.25, CHECK constraint 0-1)
- Calculates and updates percentages for existing records based on current limits
- Creates performance index on `household_id` and `month`
- Records migration in `schema_versions` table

**Compatibility**: Aligns with local database migration v12

**To Apply**:
1. Open Supabase SQL Editor
2. Copy contents of `20241113_add_percentage_to_budget_categories.sql`
3. Execute the script
4. Verify by running: `SELECT * FROM schema_versions WHERE version = 12;`

## Verification

After applying a migration, verify it was successful:

```sql
-- Check schema_versions table
SELECT * FROM public.schema_versions ORDER BY version DESC LIMIT 5;

-- Verify percentage column exists
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'budget_categories' AND column_name = 'percentage';

-- Check sample data
SELECT id, name, limit_amount, percentage, month
FROM public.budget_categories
LIMIT 10;
```

## Important Notes

1. **Always backup your database** before applying migrations
2. Test migrations in a development environment first
3. Migrations should be applied in order by date/version number
4. Keep local (SQLite) and cloud (Supabase) schemas in sync
5. Document any manual steps required after migration

## Rollback

If you need to rollback a migration:

```sql
-- Remove the percentage column (CAUTION: This will delete data)
ALTER TABLE public.budget_categories DROP COLUMN IF EXISTS percentage;

-- Remove from schema_versions
DELETE FROM public.schema_versions WHERE version = 12;
```

## Schema Sync Checklist

When adding a new column or table:

- [ ] Update local SQLite schema in `lib/db.dart`
- [ ] Create local migration in `DatabaseService`
- [ ] Create Supabase migration SQL file
- [ ] Update Supabase schema documentation
- [ ] Test sync between local and cloud
- [ ] Update any affected models/services
- [ ] Update API calls if needed
