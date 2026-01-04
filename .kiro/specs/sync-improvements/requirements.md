# Requirements Document

## Introduction

This specification addresses critical gaps in NgonNest's synchronization and authentication system to transform it from a basic unidirectional sync into a complete, bidirectional, user-friendly cloud synchronization experience. The current implementation has several critical issues identified in the sequence diagram analysis:

1. **Gap 1 - No onboarding authentication**: Users are not offered cloud sync during onboarding, missing the opportunity to enable sync from the start
2. **Gap 2 - No cloud data import**: When users authenticate, there's no logic to check for and import existing cloud data
3. **Gap 3 - Settings auth flow incomplete**: Enabling sync in settings doesn't redirect to authentication if user isn't logged in
4. **Gap 4 - No bidirectional sync**: Only local→cloud sync exists; cloud→local changes are never pulled
5. **Gap 5 - No conflict resolution**: When both local and cloud data exist, there's no strategy to merge them
6. **Gap 6 - Missing Supabase migrations**: No developer tooling to keep cloud PostgreSQL schema in sync with local SQLite changes
7. **Gap 7 - No real-time sync**: Users must manually trigger sync; no automatic background sync on reconnection

This feature will implement a complete authentication flow during onboarding, bidirectional synchronization with conflict resolution, cloud data import capabilities, Supabase schema migration tooling, and real-time sync triggers. The implementation follows the offline-first principle while providing seamless cloud backup when available.

## Requirements

### Requirement 1: Onboarding Authentication Flow

**User Story:** As a new user completing onboarding, I want to be offered the option to enable cloud synchronization, so that my data is backed up from the start without having to configure it later.

#### Acceptance Criteria

1. WHEN the user completes the household profile form THEN the system SHALL show a dialog asking "Voulez-vous synchroniser vos données dans le cloud?"
2. WHEN the user accepts cloud sync THEN the system SHALL navigate to an authentication screen
3. WHEN the authentication screen loads THEN it SHALL offer email/password and OAuth options (Google, Apple)
4. WHEN the user successfully authenticates THEN the system SHALL check for existing cloud data for this user
5. IF cloud data exists for the authenticated user THEN the system SHALL show a dialog "Importer vos données du cloud?"
6. WHEN the user confirms import THEN the system SHALL download all cloud data (foyer, products, budgets) and save locally
7. IF no cloud data exists THEN the system SHALL create the local foyer profile and enqueue it for cloud sync
8. WHEN authentication completes THEN the system SHALL call SyncService.enableSync(userConsent: true)
9. IF the user declines cloud sync during onboarding THEN the system SHALL create local profile only and show message "Vous pouvez activer la synchronisation plus tard dans les paramètres"
10. WHEN onboarding completes with sync enabled THEN the system SHALL log analytics event 'onboarding_completed_with_sync'

### Requirement 2: Authentication Service

**User Story:** As a developer, I want a centralized authentication service that manages user sessions, so that authentication logic is consistent across the app.

#### Acceptance Criteria

1. WHEN AuthService is instantiated THEN it SHALL extend ChangeNotifier to notify listeners of auth state changes
2. WHEN the app starts THEN AuthService SHALL check for an existing Supabase session
3. WHEN a valid session exists THEN AuthService SHALL set isAuthenticated = true and populate currentUser
4. WHEN AuthService.signInWithEmail() is called THEN it SHALL authenticate with Supabase and store the session
5. WHEN AuthService.signInWithOAuth() is called THEN it SHALL use Supabase OAuth flow for the specified provider
6. WHEN AuthService.signOut() is called THEN it SHALL clear the Supabase session and set isAuthenticated = false
7. WHEN authentication state changes THEN AuthService SHALL call notifyListeners()
8. WHEN AuthService.getCurrentUser() is called THEN it SHALL return the current Supabase user or null
9. WHEN a session expires THEN AuthService SHALL automatically refresh it using Supabase refresh tokens
10. IF session refresh fails THEN AuthService SHALL set isAuthenticated = false and notify listeners

### Requirement 3: Cloud Data Import

**User Story:** As a user who previously used the app on another device, I want to import my existing cloud data when I sign in, so that I don't lose my previous work.

#### Acceptance Criteria

1. WHEN a user authenticates successfully THEN the system SHALL call CloudImportService.checkCloudData()
2. WHEN checking cloud data THEN the system SHALL query Supabase for households associated with the user's ID
3. IF one or more households exist in the cloud THEN the system SHALL return hasCloudData = true
4. WHEN hasCloudData is true THEN the system SHALL show a dialog with options: "Importer", "Ignorer", "Fusionner"
5. WHEN the user selects "Importer" THEN the system SHALL call CloudImportService.importAllData()
6. WHEN importing data THEN the system SHALL download households, products, budget_categories, and purchases from Supabase
7. WHEN saving imported data locally THEN the system SHALL use INSERT OR REPLACE to avoid duplicates
8. WHEN import completes THEN the system SHALL update last_sync_time to prevent re-downloading
9. IF the user selects "Fusionner" THEN the system SHALL merge cloud and local data using conflict resolution strategy
10. WHEN import fails THEN the system SHALL log the error and allow the user to retry or continue with local data only

### Requirement 4: Settings Screen Authentication Integration

**User Story:** As a user who initially declined cloud sync, I want to enable it from settings and be guided through authentication, so that I can start backing up my data whenever I'm ready.

#### Acceptance Criteria

1. WHEN the user toggles "Synchronisation Cloud" ON in settings THEN the system SHALL check AuthService.isAuthenticated
2. IF the user is not authenticated THEN the system SHALL navigate to the authentication screen
3. WHEN the authentication screen is shown from settings THEN it SHALL display context message "Connectez-vous pour activer la synchronisation"
4. WHEN the user successfully authenticates from settings THEN the system SHALL check for cloud data
5. IF cloud data exists THEN the system SHALL show import dialog with "Importer", "Conserver local", "Fusionner" options
6. WHEN the user selects "Conserver local" THEN the system SHALL upload local data to cloud without importing
7. WHEN the user completes authentication and import THEN the system SHALL call SyncService.enableSync(userConsent: true)
8. WHEN sync is enabled THEN the system SHALL trigger an initial sync to upload pending local operations
9. IF the user is already authenticated THEN toggling sync ON SHALL immediately enable SyncService
10. WHEN the user toggles sync OFF THEN the system SHALL call SyncService.disableSync() but keep authentication active

### Requirement 5: Bidirectional Sync Service

**User Story:** As a user with multiple devices, I want changes made on one device to appear on my other devices, so that my data stays consistent across all my devices.

#### Acceptance Criteria

1. WHEN BidirectionalSyncService is instantiated THEN it SHALL extend ChangeNotifier
2. WHEN BidirectionalSyncService.enableBidirectionalSync() is called THEN it SHALL set up Supabase real-time listeners
3. WHEN a change occurs in the cloud THEN the real-time listener SHALL receive a notification
4. WHEN a cloud change is received THEN the system SHALL call ConflictResolver.resolveConflict()
5. WHEN no conflict exists THEN the system SHALL apply the cloud change to the local database
6. WHEN a conflict is detected THEN the system SHALL use the configured strategy (lastModifiedWins, localWins, cloudWins)
7. WHEN using lastModifiedWins strategy THEN the system SHALL compare updated_at timestamps and keep the newer version
8. WHEN applying a cloud change locally THEN the system SHALL NOT enqueue it in sync_outbox to avoid sync loops
9. WHEN BidirectionalSyncService.disableBidirectionalSync() is called THEN it SHALL unsubscribe from all real-time listeners
10. WHEN bidirectional sync is active THEN the system SHALL log analytics event 'bidirectional_sync_active'

### Requirement 6: Conflict Resolution Strategy

**User Story:** As a user, I want the system to intelligently handle conflicts when the same data is modified on multiple devices, so that I don't lose important changes.

#### Acceptance Criteria

1. WHEN ConflictResolver.resolveConflict() is called THEN it SHALL receive local and cloud versions of the entity
2. WHEN both versions have the same updated_at timestamp THEN the system SHALL use localWins strategy
3. WHEN the cloud version is newer THEN the system SHALL apply the cloud version locally
4. WHEN the local version is newer THEN the system SHALL keep the local version and enqueue an update to cloud
5. WHEN resolving conflicts for budget_categories THEN the system SHALL preserve spent_amount from the local version
6. WHEN resolving conflicts for products THEN the system SHALL preserve quantite_restante from the local version
7. WHEN a conflict cannot be automatically resolved THEN the system SHALL log a warning and use localWins
8. WHEN a conflict is resolved THEN the system SHALL log analytics event 'conflict_resolved' with strategy used
9. WHEN multiple conflicts exist for the same entity THEN the system SHALL resolve them in chronological order
10. IF conflict resolution fails THEN the system SHALL log the error and continue with the next entity

### Requirement 7: Supabase Schema Migration System

**User Story:** As a developer, I want automated tooling to keep the Supabase PostgreSQL schema in sync with local SQLite changes, so that I don't forget to update the cloud database when I modify the local schema.

#### Acceptance Criteria

1. WHEN a developer runs `flutter run migration:generate` THEN the system SHALL create a new migration file in `supabase/migrations/`
2. WHEN a migration file is created THEN it SHALL include the current timestamp and a descriptive name
3. WHEN a migration file is generated THEN it SHALL contain SQL statements to match the local SQLite schema changes
4. WHEN a developer runs `flutter run migration:apply` THEN the system SHALL execute all pending migrations on Supabase
5. WHEN applying migrations THEN the system SHALL use Supabase's migration API or direct SQL execution
6. WHEN a migration succeeds THEN the system SHALL record it in a `schema_versions` table in Supabase
7. WHEN a migration fails THEN the system SHALL rollback the transaction and log the error
8. WHEN checking migration status THEN the system SHALL compare local migration files with applied migrations in Supabase
9. WHEN migrations are out of sync THEN the system SHALL display a warning in the developer console
10. WHEN a migration adds a new column THEN the system SHALL include a default value to avoid breaking existing data

### Requirement 8: Automatic Background Sync

**User Story:** As a user, I want my data to automatically sync when I reconnect to the internet, so that I don't have to manually trigger synchronization.

#### Acceptance Criteria

1. WHEN ConnectivityService detects a connection change from offline to online THEN it SHALL notify SyncService
2. WHEN SyncService receives an online notification THEN it SHALL check if sync is enabled and user has consented
3. IF sync is enabled and more than 5 minutes have passed since last sync THEN the system SHALL trigger backgroundSync()
4. WHEN backgroundSync() runs THEN it SHALL first perform unidirectional sync (local→cloud)
5. WHEN unidirectional sync completes THEN it SHALL trigger bidirectional sync (cloud→local)
6. WHEN background sync is running THEN the system SHALL NOT show UI feedback (silent sync)
7. IF background sync fails THEN the system SHALL retry with exponential backoff (2s, 4s, 8s, 16s, 32s)
8. WHEN background sync succeeds THEN the system SHALL update last_sync_time
9. WHEN the app comes to foreground THEN the system SHALL trigger background sync if last sync was > 30 minutes ago
10. WHEN background sync completes THEN the system SHALL log analytics event 'background_sync_completed'

### Requirement 9: Sync Status Indicators

**User Story:** As a user, I want to see clear indicators of my sync status, so that I know when my data is backed up and when there are pending changes.

#### Acceptance Criteria

1. WHEN the user opens settings THEN they SHALL see a "Synchronisation" section with current status
2. WHEN sync is disabled THEN the status SHALL show "Désactivée" with an orange indicator
3. WHEN sync is enabled and up-to-date THEN the status SHALL show "✓ Synchronisé" with a green indicator and last sync time
4. WHEN sync is enabled with pending operations THEN the status SHALL show "⏳ En attente (X opérations)" with a blue indicator
5. WHEN sync is in progress THEN the status SHALL show "🔄 Synchronisation..." with an animated spinner
6. WHEN sync has errors THEN the status SHALL show "⚠️ Erreur de sync" with a red indicator and error count
7. WHEN the user taps on the sync status THEN they SHALL see a detailed sync status dialog
8. WHEN the sync status dialog opens THEN it SHALL show: last sync time, pending operations count, failed operations count, and sync history
9. WHEN there are failed operations THEN the dialog SHALL show a "Réessayer" button
10. WHEN the user taps "Réessayer" THEN the system SHALL call SyncService.forceSyncWithFeedback()

### Requirement 10: Authentication UI Components

**User Story:** As a user, I want a clean and intuitive authentication interface, so that signing in is quick and easy.

#### Acceptance Criteria

1. WHEN the authentication screen loads THEN it SHALL show the NgonNest logo and a welcome message
2. WHEN the screen displays THEN it SHALL offer two tabs: "Email" and "Réseaux sociaux"
3. WHEN the Email tab is active THEN it SHALL show email and password fields with validation
4. WHEN the Réseaux sociaux tab is active THEN it SHALL show buttons for Google and Apple sign-in
5. WHEN the user enters an invalid email THEN the system SHALL show an error message "Email invalide"
6. WHEN the user enters a password < 6 characters THEN the system SHALL show "Mot de passe trop court (min 6 caractères)"
7. WHEN authentication is in progress THEN the system SHALL show a loading indicator and disable the submit button
8. WHEN authentication succeeds THEN the system SHALL show a success message and navigate to the next screen
9. WHEN authentication fails THEN the system SHALL show an error message with the reason (e.g., "Email ou mot de passe incorrect")
10. WHEN the user taps "Créer un compte" THEN the system SHALL switch to sign-up mode with additional fields (name, confirm password)

### Requirement 11: Data Migration Between Devices

**User Story:** As a user switching devices, I want to easily transfer all my data to my new device, so that I can continue where I left off.

#### Acceptance Criteria

1. WHEN a user signs in on a new device THEN the system SHALL detect that no local data exists
2. WHEN no local data exists and cloud data is available THEN the system SHALL automatically suggest importing
3. WHEN importing to a fresh device THEN the system SHALL download all entities in the correct order (foyer → products → budgets → purchases)
4. WHEN importing foyer data THEN the system SHALL set the local foyer_id to match the cloud household_id
5. WHEN importing products THEN the system SHALL maintain relationships with the imported foyer
6. WHEN importing budget_categories THEN the system SHALL recalculate spent_amount based on local purchases
7. WHEN import completes THEN the system SHALL show a summary: "X produits, Y budgets, Z achats importés"
8. WHEN import fails partially THEN the system SHALL show which entities succeeded and which failed
9. WHEN the user has data on both devices THEN the system SHALL offer "Fusionner" option to merge both datasets
10. WHEN merging datasets THEN the system SHALL use conflict resolution to handle duplicates

### Requirement 12: Sync Performance Optimization

**User Story:** As a user with limited data connectivity, I want sync operations to be fast and efficient, so that I don't waste my mobile data or time.

#### Acceptance Criteria

1. WHEN syncing data THEN the system SHALL only send changed fields, not entire entities
2. WHEN downloading cloud changes THEN the system SHALL use pagination with max 50 records per request
3. WHEN multiple operations exist for the same entity THEN the system SHALL batch them into a single request
4. WHEN syncing large datasets THEN the system SHALL show progress indicators (e.g., "Synchronisation 45/120")
5. WHEN network is slow THEN the system SHALL increase timeout from 30s to 60s
6. WHEN sync operations are queued THEN the system SHALL prioritize critical entities (foyer, then products, then budgets)
7. WHEN bidirectional sync runs THEN it SHALL only fetch changes since last_sync_time, not all data
8. WHEN compressing data THEN the system SHALL use gzip for payloads > 1KB
9. WHEN sync completes THEN the system SHALL log performance metrics (duration, bytes transferred, operations count)
10. WHEN sync is slow (> 30s) THEN the system SHALL log a warning for performance monitoring

### Requirement 13: Error Handling and Recovery

**User Story:** As a user, I want the sync system to gracefully handle errors and recover automatically, so that temporary issues don't permanently break my data sync.

#### Acceptance Criteria

1. WHEN a sync operation fails with a network error THEN the system SHALL retry with exponential backoff
2. WHEN a sync operation fails with a 401 Unauthorized THEN the system SHALL refresh the auth token and retry
3. WHEN a sync operation fails with a 409 Conflict THEN the system SHALL trigger conflict resolution
4. WHEN a sync operation fails with a 500 Server Error THEN the system SHALL retry up to 5 times
5. WHEN all retries are exhausted THEN the system SHALL mark the operation as 'failed' and notify the user
6. WHEN authentication expires during sync THEN the system SHALL pause sync and prompt the user to re-authenticate
7. WHEN the database is locked during sync THEN the system SHALL wait and retry up to 3 times
8. WHEN import fails due to schema mismatch THEN the system SHALL log the error and suggest updating the app
9. WHEN a critical error occurs THEN the system SHALL log it with ErrorLoggerService at severity 'critical'
10. WHEN sync errors are resolved THEN the system SHALL automatically resume sync without user intervention

### Requirement 14: Analytics and Monitoring

**User Story:** As a product manager, I want comprehensive analytics on sync usage and performance, so that I can identify issues and improve the feature.

#### Acceptance Criteria

1. WHEN a user enables sync THEN the system SHALL log event 'sync_enabled' with source (onboarding/settings)
2. WHEN a user disables sync THEN the system SHALL log event 'sync_disabled' with reason if provided
3. WHEN authentication succeeds THEN the system SHALL log event 'auth_success' with method (email/google/apple)
4. WHEN authentication fails THEN the system SHALL log event 'auth_failed' with error_type
5. WHEN cloud data is imported THEN the system SHALL log event 'cloud_data_imported' with entity counts
6. WHEN a conflict is resolved THEN the system SHALL log event 'conflict_resolved' with strategy and entity_type
7. WHEN background sync completes THEN the system SHALL log event 'background_sync_completed' with duration and operation count
8. WHEN sync fails THEN the system SHALL log event 'sync_failed' with error_type and retry_count
9. WHEN bidirectional sync is enabled THEN the system SHALL log event 'bidirectional_sync_enabled'
10. WHEN a user switches devices THEN the system SHALL log event 'device_migration' with data_imported flag

### Requirement 15: Security and Privacy

**User Story:** As a user, I want my data to be secure during synchronization, so that my personal information is protected.

#### Acceptance Criteria

1. WHEN authenticating THEN the system SHALL use HTTPS for all API calls
2. WHEN storing auth tokens THEN the system SHALL use secure storage (flutter_secure_storage)
3. WHEN syncing data THEN the system SHALL include the user's household_id to enforce Row Level Security (RLS)
4. WHEN a user signs out THEN the system SHALL clear all auth tokens and session data
5. WHEN accessing Supabase THEN the system SHALL use the anon key, not the service role key
6. WHEN a user deletes their account THEN the system SHALL delete all cloud data associated with their user_id
7. WHEN syncing sensitive data THEN the system SHALL NOT log full payloads, only metadata
8. WHEN handling errors THEN the system SHALL NOT expose internal system details to the user
9. WHEN multiple users share a device THEN the system SHALL ensure data isolation per authenticated user
10. WHEN a session expires THEN the system SHALL automatically sign out and clear local auth state
