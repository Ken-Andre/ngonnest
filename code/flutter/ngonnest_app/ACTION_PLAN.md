# Action Plan: Fix Cloud Sync

## Current Situation

✅ **Task 4.3 Complete**: `recalculateCategoryBudgets()` works perfectly locally  
🔴 **Cloud Sync Broken**: INTEGER vs UUID schema mismatch  
⚠️ **Secondary Issue**: Missing `percentage` column in cloud

## The Two Problems

### Problem 1: Missing Column (Easy Fix - 5 minutes)
Cloud `budget_categories` table missing `percentage` column.

**Fix**: Run SQL migration in Supabase dashboard.

### Problem 2: ID Type Mismatch (Hard Fix - Requires Planning)
Local uses INTEGER IDs, cloud uses UUID strings.

**Fix**: Requires database migration and code changes.

## Quick Decision Tree

```
Do you need cloud sync working RIGHT NOW?
│
├─ NO → Apply percentage column fix, continue with local-only
│        (See: CLOUD_MIGRATION_GUIDE.md)
│
└─ YES → You need to fix the ID mismatch first
         │
         ├─ Option A: Migrate to UUIDs (Recommended)
         │   - Breaking change for existing users
         │   - Future-proof solution
         │   - Takes 1-2 days to implement safely
         │   - See: CRITICAL_SCHEMA_MISMATCH.md → Option 1
         │
         ├─ Option B: Add ID Mapping Layer
         │   - No breaking changes
         │   - More complex to maintain
         │   - Takes 2-3 days to implement
         │   - See: CRITICAL_SCHEMA_MISMATCH.md → Option 2
         │
         └─ Option C: Disable Cloud Sync
             - Immediate solution
             - Add warning in UI
             - Plan migration for later
```

## Recommended Path

### Phase 1: Today (30 minutes)

1. **Apply percentage column fix** ✅
   ```bash
   # Open Supabase Dashboard
   # Go to SQL Editor
   # Run: supabase/migrations/20241113_add_percentage_to_budget_categories.sql
   ```

2. **Disable cloud import in UI** ⚠️
   ```dart
   // In settings_screen.dart or cloud_import_dialog.dart
   // Add warning banner:
   "Cloud sync temporarily disabled due to maintenance"
   ```

3. **Document the limitation** 📝
   - Add note in README
   - Update user documentation
   - Set expectations

### Phase 2: This Week (2-3 days)

1. **Design UUID migration** (Day 1)
   - Review `CRITICAL_SCHEMA_MISMATCH.md`
   - Choose migration strategy
   - Create detailed plan
   - Identify risks

2. **Implement migration** (Day 2)
   - Create migration v13
   - Update Dart models
   - Update all references
   - Write tests

3. **Test thoroughly** (Day 3)
   - Test with production-like data
   - Test rollback procedure
   - Test on multiple devices
   - Verify data integrity

### Phase 3: Next Week (1-2 days)

1. **Deploy to staging**
   - Monitor for issues
   - Test with real users
   - Gather feedback

2. **Deploy to production**
   - Gradual rollout
   - Monitor error rates
   - Be ready to rollback

3. **Re-enable cloud sync**
   - Remove UI warnings
   - Update documentation
   - Announce to users

## If You Need Cloud Sync TODAY

**Emergency Workaround** (Not recommended for production):

```dart
// In CloudImportService._importHouseholds()
// Convert UUID to INTEGER hash
final cloudId = household['id'] as String;
final localId = cloudId.hashCode.abs();

await db.insert('foyer', {
  'id': localId,  // Hashed UUID
  'nb_personnes': household['nb_personnes'],
  // ... rest
});

// Store mapping
await db.insert('id_mappings', {
  'entity_type': 'foyer',
  'local_id': localId,
  'cloud_id': cloudId,
});
```

**Risks**:
- Hash collisions possible
- Sync conflicts likely
- Data integrity issues
- Not a long-term solution

## Files to Read

### Must Read (Priority Order)
1. `TASK_4.3_FINAL_REPORT.md` - Overview of situation
2. `CRITICAL_SCHEMA_MISMATCH.md` - Detailed analysis
3. `CLOUD_MIGRATION_GUIDE.md` - Percentage column fix

### Reference
4. `QUICK_FIX.md` - Quick commands
5. `supabase/migrations/README.md` - How to apply migrations

## Decision Points

### Decision 1: When to Fix?
- [ ] Fix now (requires 2-3 days)
- [ ] Fix later (disable sync for now)
- [ ] Emergency workaround (risky)

### Decision 2: How to Fix?
- [ ] Migrate to UUIDs (recommended)
- [ ] Add ID mapping layer
- [ ] Keep separate (not recommended)

### Decision 3: Migration Strategy?
- [ ] Big bang (all at once)
- [ ] Gradual (feature flag)
- [ ] Opt-in (user choice)

## Success Criteria

✅ Cloud import works without errors  
✅ Cloud export works without errors  
✅ Multi-device sync works  
✅ No data loss during migration  
✅ Existing users can continue using app  
✅ Performance remains acceptable  

## Risk Mitigation

1. **Backup everything** before migration
2. **Test on staging** first
3. **Gradual rollout** to production
4. **Monitor error rates** closely
5. **Have rollback plan** ready
6. **Communicate with users** about changes

## Timeline Estimate

| Task | Time | Risk |
|------|------|------|
| Apply percentage fix | 5 min | Low |
| Disable cloud sync UI | 30 min | Low |
| Design UUID migration | 1 day | Medium |
| Implement migration | 2 days | High |
| Test thoroughly | 1 day | Medium |
| Deploy to staging | 0.5 day | Medium |
| Deploy to production | 0.5 day | High |
| **Total** | **5-6 days** | **High** |

## Questions to Answer

1. How many users are actively using cloud sync?
2. How much data would be affected?
3. Can we afford 2-3 days of disabled sync?
4. Do we have a staging environment?
5. Do we have database backups?
6. What's the rollback procedure?

## Next Action

**Choose one**:

- [ ] I'll fix it now → Start with Phase 2
- [ ] I'll fix it later → Do Phase 1 only
- [ ] I need help deciding → Review CRITICAL_SCHEMA_MISMATCH.md

---

**Status**: Waiting for decision  
**Priority**: HIGH (blocks cloud sync)  
**Complexity**: HIGH (requires careful migration)  
**Risk**: HIGH (potential data loss if not done correctly)
