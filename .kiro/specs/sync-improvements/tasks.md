# Implementation Plan

- [x] 1. Setup Authentication Infrastructure




  - [x] 1.1 Create AuthService class


    - Create AuthService class extending ChangeNotifier
    - Add fields for _isAuthenticated, _currentUser
    - Implement initialize() method to check existing session
    - Set up auth state change listener
    - Add unit tests for initialization
    - _Requirements: 2.1, 2.2, 2.3_


  
  - [x] 1.2 Implement email authentication

    - Implement signInWithEmail() method
    - Implement signUpWithEmail() method
    - Add session storage using flutter_secure_storage
    - Handle auth errors and exceptions


    - Add unit tests for email auth
    - _Requirements: 2.4, 2.5_
  
  - [x] 1.3 Implement OAuth authentication

    - Implement signInWithOAuth() method for Google
    - Implement signInWithOAuth() method for Apple

    - Configure OAuth providers in Supabase
    - Add error handling for OAuth flows
    - Add unit tests for OAuth
    - _Requirements: 2.6_
  
  - [x] 1.4 Implement session management


    - Implement signOut() method
    - Implement automatic token refresh
    - Handle session expiry
    - Clear secure storage on sign out
    - Add unit tests for session management
    - _Requirements: 2.7, 2.8, 2.9, 2.10_

- [x] 2. Create Authentication UI

  - [x] 2.1 Create AuthenticationScreen widget


    - Create stateful widget with tab controller
    - Add Email and OAuth tabs
    - Implement loading states
    - Add error message display
    - Style according to NgonNest design system
    - _Requirements: 10.1, 10.2_
  
  - [x] 2.2 Implement email authentication form


    - Create email and password TextFormFields
    - Add validation for email format
    - Add validation for password length (min 6 chars)
    - Implement sign in button with loading state
    - Add "Créer un compte" toggle
    - _Requirements: 10.3, 10.5, 10.6_
  
  - [x] 2.3 Implement OAuth buttons


    - Create Google sign-in button
    - Create Apple sign-in button
    - Add provider icons and styling
    - Implement tap handlers
    - Add loading indicators
    - _Requirements: 10.4_
  
  - [x] 2.4 Add sign-up mode

    - Add full name field for sign-up
    - Add confirm password field
    - Add validation for matching passwords
    - Toggle between sign-in and sign-up modes
    - Update button text based on mode
    - _Requirements: 10.10_
  
  - [x] 2.5 Implement authentication feedback


    - Show loading indicator during auth
    - Display success message on successful auth
    - Display error messages for auth failures
    - Disable submit button during loading
    - Add widget tests for all states
    - _Requirements: 10.7, 10.8, 10.9_

- [ ] 3. Implement Cloud Import Service




  - [x] 3.1 Create CloudImportService class


    - Create CloudImportService class
    - Add SupabaseClient and DatabaseService dependencies
    - Create ImportResult data class
    - Add error handling structure
    - _Requirements: 3.1_
  


  - [x] 3.2 Implement cloud data check

    - Implement checkCloudData() method
    - Query Supabase for user's households
    - Return boolean indicating data existence
    - Handle errors gracefully
    - Add unit tests for checkCloudData


    - _Requirements: 3.2, 3.3_
  

  - [ ] 3.3 Implement household import
    - Implement _importHouseholds() method
    - Query Supabase households table
    - Insert into local foyer table with conflict resolution


    - Map cloud schema to local schema
    - Add unit tests for household import
    - _Requirements: 3.6_

  
  - [ ] 3.4 Implement product import
    - Implement _importProducts() method

    - Query Supabase products table by household_id
    - Map cloud product schema to local objet schema
    - Insert with conflict resolution
    - Add unit tests for product import
    - _Requirements: 3.6_
  
  - [x] 3.5 Implement budget and purchase import

    - Implement _importBudgetCategories() method
    - Implement _importPurchases() method
    - Map schemas correctly
    - Insert with conflict resolution
    - Add unit tests for both imports
    - _Requirements: 3.6_
  
  - [x] 3.6 Implement importAllData orchestration


    - Implement importAllData() method
    - Import in correct order (households → products → budgets → purchases)
    - Track import counts in ImportResult
    - Update last_sync_time after successful import

    - Log analytics event with entity counts


    - Add integration tests for full import
    - _Requirements: 3.6, 3.7, 3.8, 14.5_

- [-] 4. Create Cloud Import UI
  - [x] 4.1 Create CloudImportDialog widget

    - Create dialog widget with import options
    - Add "Importer", "Fusionner", "Ignorer" buttons
    - Show explanation text for each option
    - Style according to design system
    - _Requirements: 3.4, 3.5_
  
  - [x] 4.2 Implement import progress UI


    - Add progress indicator during import
    - Show entity counts being imported
    - Display current operation (e.g., "Importation des produits...")
    - Add cancel button (if feasible)
    - _Requirements: 12.4_
  
  - [x] 4.3 Implement import result display
    - Show success message with import summary
    - Display entity counts (X produits, Y budgets, etc.)
    - Show partial success if some entities failed
    - Add retry button for failed imports
    - Add widget tests for all states
    - _Requirements: 3.7, 3.8, 11.7_

- [ ] 5. Integrate Authentication with Onboarding
  - [x] 5.1 Add sync offer to onboarding
    - Show "Voulez-vous synchroniser vos données?" dialog after profile creation
    - Add "Oui" and "Non, plus tard" buttons
    - Style dialog consistently
    - _Requirements: 1.1_
  
  - [x] 5.2 Implement onboarding auth flow
    - Navigate to AuthenticationScreen when user accepts sync
    - Pass context indicating source is onboarding
    - Handle successful authentication
    - Call CloudImportService.checkCloudData()
    - _Requirements: 1.2, 1.3, 1.4_
  
  - [x] 5.3 Implement cloud data import from onboarding
    - Show CloudImportDialog if cloud data exists
    - Handle "Importer" selection
    - Handle "Ignorer" selection (create local profile)
    - Call SyncService.enableSync() after import
    - _Requirements: 1.5, 1.6, 1.7, 1.8_
  
  - [x] 5.4 Handle onboarding decline sync
    - Create local profile only when user declines
    - Show message "Vous pouvez activer la synchronisation plus tard"
    - Ensure app works fully offline
    - Log analytics event
    - _Requirements: 1.9_
  
  - [x] 5.5 Complete onboarding sync flow
    - Call SyncService.enableSync(userConsent: true) after auth
    - Trigger initial sync if no cloud data
    - Navigate to Dashboard after completion
    - Log analytics event 'onboarding_completed_with_sync'
    - Add integration tests for full onboarding flow
    - _Requirements: 1.8, 1.10_
- [x] 6. Enhance Settings Screen for Sync

  - [x] 6.1 Add sync status section to settings
    - Add "Synchronisation" section to SettingsScreen
    - Display current sync status with icon
    - Show last sync time if available
    - Add tap handler to show details
    - _Requirements: 9.1, 9.2, 9.3_
  


  - [x] 6.2 Implement sync toggle with auth check
    - Add sync toggle switch
    - Check AuthService.isAuthenticated when toggling ON
    - Navigate to AuthenticationScreen if not authenticated
    - Pass context indicating source is settings
    - _Requirements: 4.1, 4.2, 4.3_
  
  - [x] 6.3 Implement settings auth flow
    - Show context message "Connectez-vous pour activer la synchronisation"
    - Handle successful authentication from settings
    - Check for cloud data after auth
    - Show import options dialog
    - _Requirements: 4.3, 4.4, 4.5_
  
  - [x] 6.4 Implement import options from settings

    - Add "Conserver local" option to upload local data
    - Add "Importer" option to download cloud data
    - Add "Fusionner" option to merge both
    - Handle each option appropriately
    - _Requirements: 4.5, 4.6_
  
  - [x] 6.5 Complete settings sync enable flow
    - Call SyncService.enableSync() after auth and import
    - Trigger initial sync to upload pending operations
    - Show success message
    - Update sync status display
    - Add integration tests for settings flow
    - _Requirements: 4.7, 4.8, 4.9, 4.10_

- [ ] 7. Implement Bidirectional Sync Service
  - [ ] 7.1 Create BidirectionalSyncService class
    - Create class extending ChangeNotifier
    - Add SupabaseClient and DatabaseService dependencies
    - Add _subscriptions map for real-time channels
    - Add _isEnabled boolean flag
    - _Requirements: 5.1_
  
  - [ ] 7.2 Implement real-time listener setup
    - Implement enableBidirectionalSync() method
    - Set up real-time channel for households table
    - Set up real-time channel for products table
    - Set up real-time channel for budget_categories table
    - Store subscriptions in _subscriptions map
    - _Requirements: 5.2_
  
  - [ ] 7.3 Implement change handlers
    - Implement _handleHouseholdChange() method
    - Implement _handleProductChange() method
    - Implement _handleBudgetChange() method
    - Parse payload for event type (INSERT/UPDATE/DELETE)
    - Extract new and old records from payload
    - _Requirements: 5.3_
  
  - [ ] 7.4 Implement change application
    - Implement _applyHouseholdChange() method
    - Implement _applyProductChange() method
    - Implement _applyBudgetChange() method
    - Query local database for existing entity
    - Call ConflictResolver if local version exists
    - Apply change to local database
    - _Requirements: 5.4, 5.5_
  
  - [ ] 7.5 Implement sync loop prevention
    - Ensure applied changes are NOT enqueued in sync_outbox
    - Add flag or metadata to distinguish cloud-originated changes
    - Test that changes don't create infinite loops
    - _Requirements: 5.8_
  
  - [ ] 7.6 Implement disableBidirectionalSync
    - Implement disableBidirectionalSync() method
    - Unsubscribe from all real-time channels
    - Clear _subscriptions map
    - Set _isEnabled to false
    - Add unit tests for enable/disable
    - _Requirements: 5.9_

- [ ] 8. Implement Conflict Resolution
  - [ ] 8.1 Create ConflictResolver class
    - Create ConflictResolver class
    - Add AnalyticsService dependency
    - Create ConflictStrategy enum
    - Create ConflictResolution data class
    - _Requirements: 6.1_
  
  - [ ] 8.2 Implement lastModifiedWins strategy
    - Implement _lastModifiedWins() method
    - Extract timestamps from local and cloud data
    - Compare timestamps
    - Return resolution indicating winner
    - Handle null timestamps
    - _Requirements: 6.2, 6.3, 6.4, 6.7_
  
  - [ ] 8.3 Implement entity-specific merge strategy
    - Implement _mergeData() method
    - For products: preserve local quantite_restante
    - For budgets: preserve local spent_amount
    - For other entities: use cloud data
    - Return merged data in resolution
    - _Requirements: 6.5, 6.6_
  
  - [ ] 8.4 Implement resolveConflict orchestration
    - Implement resolveConflict() method
    - Apply selected strategy
    - Log analytics event with strategy and winner
    - Handle errors gracefully (default to localWins)
    - Add unit tests for all strategies
    - _Requirements: 6.8, 6.9, 6.10_

- [ ] 9. Implement Supabase Migration System
  - [ ] 9.1 Create migration file structure
    - Create supabase/migrations/ directory
    - Add .gitkeep to track directory
    - Document migration file naming convention
    - _Requirements: 7.1, 7.2_
  
  - [ ] 9.2 Create SupabaseMigrationTool class
    - Create SupabaseMigrationTool class
    - Add SupabaseClient dependency
    - Create Migration data class
    - _Requirements: 7.1_
  
  - [ ] 9.3 Implement migration generation
    - Implement generateMigration() static method
    - Generate timestamp-based filename
    - Create migration file with template
    - Include SQL placeholder and schema_versions insert
    - Add CLI command to run generation
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 9.4 Implement migration application
    - Implement applyMigrations() method
    - Query Supabase for applied migrations
    - Read local migration files
    - Find pending migrations
    - Execute each pending migration
    - _Requirements: 7.4, 7.5_
  
  - [ ] 9.5 Implement migration execution
    - Implement _applyMigration() method
    - Execute SQL using Supabase RPC
    - Record migration in schema_versions table
    - Handle migration failures with rollback
    - Log success/failure
    - _Requirements: 7.6, 7.7_
  
  - [ ] 9.6 Add migration status check
    - Implement migration status check
    - Compare local and applied migrations
    - Display warning if out of sync
    - Add to developer console
    - Add unit tests for migration tool
    - _Requirements: 7.8, 7.9_

- [ ] 10. Enhance Background Sync
  - [ ] 10.1 Add connectivity listener to SyncService
    - Listen to ConnectivityService state changes
    - Detect online/offline transitions
    - Trigger sync on reconnection
    - _Requirements: 8.1_
  
  - [ ] 10.2 Implement background sync trigger
    - Enhance backgroundSync() method
    - Check if sync is enabled and user consented
    - Check time since last sync (> 5 minutes)
    - Perform unidirectional sync first
    - Then trigger bidirectional sync
    - _Requirements: 8.2, 8.3, 8.4, 8.5_
  
  - [ ] 10.3 Implement silent sync
    - Ensure background sync doesn't show UI feedback
    - Log sync operations to console
    - Update last_sync_time on success
    - Handle errors silently
    - _Requirements: 8.6_
  
  - [ ] 10.4 Implement retry logic for background sync
    - Add exponential backoff for failed syncs
    - Retry delays: 2s, 4s, 8s, 16s, 32s
    - Stop retrying after 5 attempts
    - Log retry attempts
    - _Requirements: 8.7_
  
  - [ ] 10.5 Add app foreground sync trigger
    - Listen to app lifecycle changes
    - Trigger sync when app comes to foreground
    - Only if last sync was > 30 minutes ago
    - Log analytics event
    - Add integration tests for background sync
    - _Requirements: 8.8, 8.9, 8.10_

- [ ] 11. Implement Sync Status Indicators
  - [ ] 11.1 Create sync status widget
    - Create SyncStatusIndicator widget
    - Show status icon (✓, ⏳, ⚠️, 🔄)
    - Show status text
    - Show last sync time
    - Add color coding (green, blue, orange, red)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_
  
  - [ ] 11.2 Create sync status dialog
    - Create SyncStatusDialog widget
    - Show detailed sync information
    - Display pending operations count
    - Display failed operations count
    - Show sync history (last 10 syncs)
    - _Requirements: 9.7, 9.8_
  
  - [ ] 11.3 Add retry functionality
    - Add "Réessayer" button to status dialog
    - Call SyncService.forceSyncWithFeedback()
    - Show progress during retry
    - Update status after retry
    - Add widget tests for status indicators
    - _Requirements: 9.9, 9.10_

- [ ] 12. Add Localization for New Features
  - [ ] 12.1 Add French strings
    - Add auth screen strings to app_fr.arb
    - Add sync status strings
    - Add import dialog strings
    - Add error messages
    - _Requirements: All_
  
  - [ ] 12.2 Add English strings
    - Add auth screen strings to app_en.arb
    - Add sync status strings
    - Add import dialog strings
    - Add error messages
    - _Requirements: All_
  
  - [ ] 12.3 Add Spanish strings
    - Add auth screen strings to app_es.arb
    - Add sync status strings
    - Add import dialog strings
    - Add error messages
    - _Requirements: All_

- [ ] 13. Implement Comprehensive Error Handling
  - [ ] 13.1 Add auth error handling
    - Handle 400 (invalid credentials)
    - Handle 429 (rate limit)
    - Handle network errors
    - Show user-friendly messages
    - Log errors with ErrorLoggerService
    - _Requirements: 13.1, 13.2_
  
  - [ ] 13.2 Add sync error handling
    - Handle 401 (unauthorized) with token refresh
    - Handle 409 (conflict) with resolution
    - Handle 500 (server error) with retry
    - Handle network errors with retry
    - _Requirements: 13.2, 13.3, 13.4, 13.5_
  
  - [ ] 13.3 Add import error handling
    - Handle partial import failures
    - Show which entities succeeded/failed
    - Allow retry for failed entities
    - Log errors with context
    - _Requirements: 13.6, 13.8_
  
  - [ ] 13.4 Add session expiry handling
    - Detect expired sessions during sync
    - Pause sync and prompt re-authentication
    - Resume sync after re-auth
    - Clear auth state on failure
    - _Requirements: 13.6, 13.10_
  
  - [ ] 13.5 Add database error handling
    - Handle database locked errors
    - Retry with delay (up to 3 times)
    - Handle schema mismatch errors
    - Log all database errors
    - _Requirements: 13.7, 13.9_

- [ ] 14. Add Comprehensive Analytics
  - [ ] 14.1 Add auth analytics
    - Log 'auth_success' with method and duration
    - Log 'auth_failed' with error_type
    - Log 'sync_enabled' with source
    - Log 'sync_disabled' with reason
    - _Requirements: 14.1, 14.2, 14.3_
  
  - [ ] 14.2 Add import analytics
    - Log 'cloud_data_imported' with entity counts
    - Log 'device_migration' with data_imported flag
    - Include import duration
    - _Requirements: 14.5, 14.10_
  
  - [ ] 14.3 Add sync analytics
    - Log 'conflict_resolved' with strategy and entity_type
    - Log 'background_sync_completed' with duration and count
    - Log 'sync_failed' with error_type and retry_count
    - Log 'bidirectional_sync_enabled'
    - _Requirements: 14.6, 14.7, 14.8, 14.9_

- [ ] 15. Implement Performance Optimizations
  - [ ] 15.1 Add pagination for cloud data fetch
    - Implement pagination in CloudImportService
    - Fetch max 50 records per request
    - Show progress during paginated import
    - _Requirements: 12.2_
  
  - [ ] 15.2 Implement operation batching
    - Batch multiple operations for same entity
    - Reduce number of API calls
    - Optimize sync performance
    - _Requirements: 12.3_
  
  - [ ] 15.3 Add progress indicators
    - Show progress for large imports (e.g., "45/120")
    - Update progress in real-time
    - Add to import dialog
    - _Requirements: 12.4_
  
  - [ ] 15.4 Implement adaptive timeouts
    - Increase timeout to 60s for slow networks
    - Detect slow network conditions
    - Adjust timeout dynamically
    - _Requirements: 12.5_
  
  - [ ] 15.5 Add sync prioritization
    - Prioritize critical entities (foyer first)
    - Then products, then budgets
    - Ensure correct sync order
    - _Requirements: 12.6_
  
  - [ ] 15.6 Implement data compression
    - Use gzip for payloads > 1KB
    - Compress before sending to cloud
    - Decompress when receiving
    - _Requirements: 12.8_
  
  - [ ] 15.7 Add performance logging
    - Log sync duration
    - Log bytes transferred
    - Log operation counts
    - Warn if sync > 30s
    - _Requirements: 12.9, 12.10_

- [ ] 16. Implement Security Enhancements
  - [ ] 16.1 Implement secure token storage
    - Use flutter_secure_storage for tokens
    - Store access_token and refresh_token
    - Clear on sign out
    - _Requirements: 15.2_
  
  - [ ] 16.2 Enforce HTTPS
    - Verify all API calls use HTTPS
    - Add certificate pinning if needed
    - _Requirements: 15.1_
  
  - [ ] 16.3 Implement Row Level Security
    - Add household_id to all sync operations
    - Filter queries by user_id
    - Verify RLS policies in Supabase
    - _Requirements: 15.3_
  
  - [ ] 16.4 Add data isolation
    - Ensure multi-user device support
    - Isolate data per authenticated user
    - Clear data on user switch
    - _Requirements: 15.9_
  
  - [ ] 16.5 Implement secure sign out
    - Clear all auth tokens
    - Clear session data
    - Sign out from Supabase
    - Clear local auth state
    - _Requirements: 15.4, 15.10_
  
  - [ ] 16.6 Add account deletion
    - Implement delete account functionality
    - Delete all cloud data for user
    - Clear local data
    - Sign out user
    - _Requirements: 15.6_
  
  - [ ] 16.7 Secure error logging
    - Never log full payloads
    - Log metadata only
    - Sanitize error messages
    - Don't expose internal details
    - _Requirements: 15.7, 15.8_

- [ ] 17. Write Integration Tests
  - [ ] 17.1 Onboarding flow tests
    - Test: Complete onboarding → accept sync → auth → import
    - Test: Complete onboarding → decline sync → local only
    - Verify data integrity after import
    - _Requirements: 1.1-1.10_
  
  - [ ] 17.2 Settings sync enable tests
    - Test: Enable sync when not authenticated → auth → import
    - Test: Enable sync when authenticated → immediate sync
    - Test: Disable sync → verify local data preserved
    - _Requirements: 4.1-4.10_
  
  - [ ] 17.3 Bidirectional sync tests
    - Test: Cloud change → local update
    - Test: Local change → cloud update
    - Test: Simultaneous changes → conflict resolution
    - Test: Real-time listener functionality
    - _Requirements: 5.1-5.10_
  
  - [ ] 17.4 Device migration tests
    - Test: Sign in on new device → import all data
    - Test: Verify data completeness after import
    - Test: Verify relationships preserved
    - _Requirements: 11.1-11.10_
  
  - [ ] 17.5 Background sync tests
    - Test: Reconnect → auto sync
    - Test: App foreground → auto sync
    - Test: Retry logic on failure
    - _Requirements: 8.1-8.10_

- [ ] 18. Write Unit Tests
  - [ ] 18.1 AuthService tests
    - Test sign in with valid credentials
    - Test sign in with invalid credentials
    - Test OAuth flow
    - Test session refresh
    - Test sign out
    - _Requirements: 2.1-2.10_
  
  - [ ] 18.2 CloudImportService tests
    - Test checkCloudData with/without data
    - Test importAllData with various datasets
    - Test partial import failures
    - Test schema mapping
    - _Requirements: 3.1-3.10_
  
  - [ ] 18.3 BidirectionalSyncService tests
    - Test listener setup
    - Test change handling (INSERT/UPDATE/DELETE)
    - Test conflict resolution integration
    - Test disable functionality
    - _Requirements: 5.1-5.10_
  
  - [ ] 18.4 ConflictResolver tests
    - Test lastModifiedWins with different timestamps
    - Test merge strategy for products
    - Test merge strategy for budgets
    - Test edge cases (null timestamps, same timestamps)
    - _Requirements: 6.1-6.10_
  
  - [ ] 18.5 SupabaseMigrationTool tests
    - Test migration generation
    - Test migration application
    - Test rollback on failure
    - Test status check
    - _Requirements: 7.1-7.10_

- [ ] 19. Write Widget Tests
  - [ ] 19.1 AuthenticationScreen tests
    - Test email/password validation
    - Test OAuth button interactions
    - Test loading states
    - Test error messages
    - Test sign-up mode toggle
    - _Requirements: 10.1-10.10_
  
  - [ ] 19.2 CloudImportDialog tests
    - Test import/merge/skip options
    - Test progress indicators
    - Test success/error states
    - Test retry functionality
    - _Requirements: 3.4, 3.5, 11.7_
  
  - [ ] 19.3 SyncStatusIndicator tests
    - Test status display for all states
    - Test color coding
    - Test last sync time display
    - Test tap to show details
    - _Requirements: 9.1-9.10_

- [ ] 20. Documentation and Deployment
  - [ ] 20.1 Update technical documentation
    - Document AuthService usage
    - Document CloudImportService usage
    - Document BidirectionalSyncService usage
    - Document migration tool usage
    - Add code examples
    - _Requirements: All_
  
  - [ ] 20.2 Create user documentation
    - Document how to enable cloud sync
    - Document how to import data
    - Document sync status indicators
    - Add troubleshooting guide
    - Translate to French, English, Spanish
    - _Requirements: All_
  
  - [ ] 20.3 Create deployment checklist
    - Verify all tests passing
    - Verify Supabase configuration
    - Verify OAuth providers configured
    - Verify RLS policies enabled
    - Verify analytics events configured
    - _Requirements: All_
  
  - [ ] 20.4 Prepare rollback plan
    - Document rollback procedure
    - Create feature flag for bidirectional sync
    - Test rollback on staging
    - Document emergency procedures
    - _Requirements: Deployment strategy_
  
  - [ ] 20.5 Configure monitoring
    - Set up alerts for auth failures
    - Set up alerts for sync errors
    - Configure dashboard for sync metrics
    - Set up analytics funnel
    - _Requirements: Monitoring and analytics_
