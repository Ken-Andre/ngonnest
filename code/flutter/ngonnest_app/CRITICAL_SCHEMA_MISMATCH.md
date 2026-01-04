# CRITICAL: Schema Mismatch Between Local and Cloud

## Issue

The local SQLite database and cloud Supabase database have **fundamentally incompatible schemas** for the `foyer` table:

### Local Schema (SQLite)
```sql
CREATE TABLE foyer (
  id INTEGER PRIMARY KEY AUTOINCREMENT,  -- ❌ INTEGER
  nb_personnes INTEGER NOT NULL,
  nb_pieces INTEGER NOT NULL DEFAULT 1,
  type_logement TEXT NOT NULL,
  langue TEXT NOT NULL,
  budget_mensuel_estime REAL
)
```

### Cloud Schema (Supabase)
```sql
CREATE TABLE public.households (
  id uuid NOT NULL DEFAULT gen_random_uuid(),  -- ❌ UUID
  user_id uuid,
  nb_personnes integer NOT NULL CHECK (nb_personnes > 0),
  nb_pieces integer NOT NULL DEFAULT 1,
  type_logement text NOT NULL,
  langue text NOT NULL,
  budget_mensuel_estime real,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT households_pkey PRIMARY KEY (id)
)
```

## Error Manifestation

```
DatabaseException(datatype mismatch (code 20 SQLITE_MISMATCH)) 
sql 'INSERT OR REPLACE INTO foyer (id, ...) VALUES (?, ...)' 
args [46e102b5-88dc-40a7-8a27-edc200306696, ...]
       ↑ UUID string trying to insert into INTEGER column
```

## Root Cause

The app was designed with two conflicting approaches:

1. **Local-first with INTEGER IDs**: Optimized for offline operation with auto-increment IDs
2. **Cloud-first with UUIDs**: Standard for distributed systems to avoid ID conflicts

These two approaches are **incompatible** without a mapping layer.

## Impact

- ❌ Cloud import fails completely
- ❌ Cloud export may work but creates orphaned records
- ❌ Sync between devices impossible
- ❌ Multi-user households cannot share data

## Why This Wasn't Caught Earlier

1. The app was developed offline-first without cloud sync initially
2. Cloud sync was added later without migrating the schema
3. Tests don't cover the full import/export cycle with real cloud data
4. The `budget_categories` issue masked this deeper problem

## Solutions

### Option 1: Migrate Local to UUIDs (Recommended)

**Pros**:
- Aligns with cloud schema
- Standard approach for distributed systems
- Enables proper sync and multi-device support
- Future-proof

**Cons**:
- Breaking change for existing users
- Requires data migration
- More complex than INTEGER IDs
- Slightly larger storage footprint

**Implementation**:
1. Create migration v13 to change `foyer.id` from INTEGER to TEXT
2. Generate UUIDs for existing records
3. Update all foreign keys in related tables
4. Update Dart models to use String for IDs
5. Test thoroughly with existing data

### Option 2: Add ID Mapping Layer

**Pros**:
- No breaking changes for local database
- Keeps INTEGER IDs for offline performance
- Can be added incrementally

**Cons**:
- Complex to maintain
- Requires mapping table (local_id ↔ cloud_id)
- Sync logic becomes more complicated
- Potential for mapping conflicts

**Implementation**:
1. Create `id_mappings` table
2. Store (entity_type, local_id, cloud_id) mappings
3. Translate IDs during import/export
4. Handle conflicts when mappings diverge

### Option 3: Separate Local and Cloud Data (Not Recommended)

**Pros**:
- No migration needed
- Simple to implement

**Cons**:
- No real sync capability
- Defeats the purpose of cloud storage
- Poor user experience
- Data duplication issues

## Recommended Action Plan

### Phase 1: Immediate (Stop the Bleeding)
1. **Disable cloud import** until schema is fixed
2. Add warning in UI about sync limitations
3. Document the issue for users

### Phase 2: Short-term (Fix the Schema)
1. Design UUID migration strategy
2. Create migration v13 for local database
3. Test migration with production-like data
4. Implement rollback mechanism

### Phase 3: Long-term (Full Sync)
1. Migrate all users to UUID schema
2. Re-enable cloud import/export
3. Implement proper conflict resolution
4. Add multi-device sync support

## Temporary Workaround

For development/testing only:

```dart
// In CloudImportService._importHouseholds()
// Convert UUID to hash for local storage
final cloudId = household['id'] as String;
final localId = cloudId.hashCode.abs(); // Convert UUID to INTEGER

await db.insert('foyer', {
  'id': localId,  // Use hashed ID instead of UUID
  'nb_personnes': household['nb_personnes'],
  // ... rest of fields
});

// Store mapping for later sync
await db.insert('id_mappings', {
  'entity_type': 'foyer',
  'local_id': localId,
  'cloud_id': cloudId,
});
```

**Warning**: This is a hack and will cause issues with:
- Hash collisions (unlikely but possible)
- Sync conflicts
- Data integrity

## Related Issues

1. **`budget_categories` percentage column**: Fixed in migration v12 (local) and cloud migration
2. **`products` table**: Likely has same INTEGER vs UUID issue
3. **`purchases` table**: Likely has same INTEGER vs UUID issue
4. **All foreign keys**: Need to be updated if migrating to UUIDs

## Decision Required

This is an **architectural decision** that affects:
- Database schema
- Sync strategy
- User experience
- Development complexity

**Recommendation**: Migrate to UUIDs (Option 1) for long-term viability, but requires careful planning and testing.

## Next Steps

1. **Immediate**: Review this document with the team
2. **Decision**: Choose migration strategy (Option 1 recommended)
3. **Planning**: Create detailed migration plan
4. **Implementation**: Execute migration in phases
5. **Testing**: Comprehensive testing with real data
6. **Deployment**: Gradual rollout with monitoring

## Contact

This issue was discovered during Task 4.3 implementation. The `percentage` column migration is complete, but this deeper schema mismatch must be addressed before cloud sync can work properly.

---

**Status**: 🔴 CRITICAL - Blocks cloud sync functionality  
**Priority**: HIGH - Affects core feature  
**Complexity**: HIGH - Requires careful migration  
**Risk**: HIGH - Data loss potential if not handled correctly
