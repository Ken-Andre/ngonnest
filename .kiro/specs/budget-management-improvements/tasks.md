# Implementation Plan

- [x] 1. Database Schema and Migration Setup




  - Create migration V12 to add percentage column to budget_categories table
  - Implement migration logic to calculate percentages from existing data
  - Add database indexes for performance (month, name+month)
  - Update foyer.budgetMensuelEstime for existing users without it set
  - Add rollback mechanism for failed migrations
  - Write unit tests for migration logic
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_
-

- [x] 2. Enhance BudgetCategory Model
  - [x] 2.1 Add percentage field to BudgetCategory model

    - Add percentage property to BudgetCategory class
    - Update toMap() to include percentage field
    - Update fromMap() to parse percentage field
    - Add default percentage value (0.25) for backward compatibility
    - Update copyWith() method to support percentage
    - _Requirements: 1.1, 1.4, 1.5_

  - [x] 2.2 Add alert level logic to BudgetCategory



    - Create BudgetAlertLevel enum (normal, warning, alert, critical)
    - Implement alertLevel getter based on spendingPercentage
    - Add unit tests for alert level calculations
    - Test edge cases (zero limit, negative values)
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Implement BudgetAllocationRules Engine
  - [x] 3.1 Create BudgetAllocationRules class


    - Define default percentage allocations map
    - Define fallback base prices map
    - Create BudgetAllocation data class
    - _Requirements: 6.8_
  
  - [x] 3.2 Implement household multiplier calculations


    - Implement _calculatePersonMultiplier() method
    - Implement _calculateRoomMultiplier() method
    - Implement _calculateHousingMultiplier() method
    - Add unit tests for each multiplier with various inputs
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 3.3 Implement recommended budget calculation

    - Implement calculateRecommendedBudgets() method
    - Apply category-specific formulas (Hygiène, Nettoyage, Cuisine, Divers)
    - Implement clamping logic for min/max amounts
    - Handle PriceService failures with fallback values

    - Add integration tests with PriceService
    - _Requirements: 6.4, 6.5, 6.6, 6.7, 6.8_
  
  - [x] 3.4 Implement percentage-based budget calculation

    - Implement calculateFromTotal() method
    - Calculate category amounts from total budget and percentages
    - Add unit tests with various total budget amounts
    - Test with zero and very large budgets
    - _Requirements: 1.1, 1.2, 1.6_

- [x] 4. Convert BudgetService to ChangeNotifier


  - [x] 4.1 Extend ChangeNotifier in BudgetService
    - Change class declaration to extend ChangeNotifier
    - Add dispose() method to clean up resources
    - Add _debounceTimer field for debouncing
    - Implement _notifyListenersDebounced() method
    - _Requirements: 3.1, 3.7_
  
  - [x] 4.2 Update mutation methods to notify listeners
    - Add notifyListeners() call to createBudgetCategory()
    - Add notifyListeners() call to updateBudgetCategory()
    - Add notifyListeners() call to deleteBudgetCategory()
    - Add notifyListeners() call to syncBudgetWithPurchases()
    - Implement debouncing to prevent excessive notifications
    - _Requirements: 3.3, 3.7_

  - [x] 4.3 Implement recalculateCategoryBudgets method

    - Create recalculateCategoryBudgets() method
    - Load all categories for current month
    - Calculate new limits based on percentages and new total
    - Update each category in database
    - Enqueue sync operations for updates
    - Call notifyListeners() after completion
    - Add unit tests for recalculation logic


    - _Requirements: 1.2, 1.4, 7.5, 7.6_
  
  - [ ] 4.4 Add unit tests for ChangeNotifier behavior
    - Test that listeners are notified on create
    - Test that listeners are notified on update
    - Test that listeners are notified on delete
    - Test debouncing (multiple rapid calls → single notification)
    - Test dispose() cleans up timer
    - _Requirements: 3.1, 3.3, 3.6, 3.7_

- [ ] 5. Integrate SyncService with Budget Operations
  - [ ] 5.1 Add sync to createBudgetCategory
    - Call SyncService.enqueueOperation() after DB insert
    - Set operation_type='CREATE', entity_type='budget_categories'
    - Include full category data in payload
    - Add error handling for sync failures
    - _Requirements: 4.1, 4.6_
  
  - [ ] 5.2 Add sync to updateBudgetCategory
    - Call SyncService.enqueueOperation() after DB update
    - Set operation_type='UPDATE', entity_type='budget_categories'
    - Include updated category data in payload
    - Add error handling for sync failures
    - _Requirements: 4.2, 4.4, 4.6_
  
  - [ ] 5.3 Add sync to deleteBudgetCategory
    - Call SyncService.enqueueOperation() after DB delete
    - Set operation_type='DELETE', entity_type='budget_categories'
    - Include category id in payload
    - Add error handling for sync failures
    - _Requirements: 4.3, 4.6_
  
  - [ ] 5.4 Add integration tests for sync operations
    - Test that operations are enqueued correctly
    - Test payload structure matches requirements
    - Test that local operations succeed even if sync fails
    - Test sync disabled scenario (operations still enqueued)
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 4.6, 4.7_

- [x] 6. Implement Real Notification System

  - [x] 6.1 Create BudgetNotifications extension


    - Create extension on NotificationService
    - Implement showBudgetAlert() method
    - Determine notification content based on alert level
    - Set appropriate colors for each severity level
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [x] 6.2 Replace console logs with real notifications
    - Update _triggerBudgetAlert() in BudgetService
    - Call NotificationService.showBudgetAlert() instead of debugPrint()
    - Pass BudgetCategory to notification method
    - Add fallback to in-app banner if permissions denied
    - _Requirements: 2.4, 2.6_
  
  - [x] 6.3 Add analytics tracking for notifications
    - Log 'budget_alert_triggered' event when notification shown
    - Include category, percentage, alert_level in parameters
    - Include spent and limit amounts
    - Add unit tests for analytics tracking
    - _Requirements: 2.5, 9.5_
  
  - [x] 6.4 Add integration tests for notification flow
    - Test notification shown when budget reaches 80%
    - Test notification shown when budget reaches 100%
    - Test notification shown when budget reaches 120%
    - Test fallback to in-app banner when permissions denied
    - Test analytics events are logged correctly
    - _Requirements: 2.1, 2.2, 2.3, 2.6_

- [x] 7. Integrate Budget Updates with Inventory Operations





  - [x] 7.1 Update InventoryRepository.create()


    - Add BudgetService instance to InventoryRepository
    - Call checkBudgetAlertsAfterPurchase() after object insert
    - Only trigger if prixUnitaire is set and > 0
    - Add error handling to not block inventory operations
    - _Requirements: 3.2_
  

  - [x] 7.2 Update InventoryRepository.update()

    - Check if prix_unitaire changed in updates
    - Call checkBudgetAlertsAfterPurchase() if price changed
    - Only trigger if new price is set and > 0
    - Add error handling to not block inventory operations
    - _Requirements: 3.2_
  
  - [x] 7.3 Add integration tests for inventory-budget flow


    - Test adding inventory item triggers budget update
    - Test updating item price triggers budget update
    - Test budget notification shown when threshold exceeded
    - Test BudgetScreen auto-refreshes after inventory change
    - Test error in budget update doesn't block inventory operation
    - _Requirements: 3.2, 3.3, 3.5_

- [x] 8. Update BudgetScreen with Observer Pattern
  - [x] 8.1 Register BudgetScreen as listener


    - Add BudgetService instance to BudgetScreen state
    - Register listener in initState()
    - Implement listener callback to reload data
    - Unregister listener in dispose()
    - _Requirements: 3.4, 3.5, 3.6_
  
  - [x] 8.2 Add loading and error states

    - Add isLoading boolean to state
    - Show CircularProgressIndicator during load
    - Add errorMessage string to state
    - Show error banner with retry button on error
    - Implement retry logic
    - _Requirements: 8.6, 8.7, 10.5_
  
  - [x] 8.3 Enhance visual indicators for alert levels

    - Update BudgetCategoryCard to show color based on alertLevel
    - Add warning icon for categories over 80%
    - Add alert icon for categories over 100%
    - Add critical icon for categories over 120%
    - Update progress bar colors (green/orange/red)
    - _Requirements: 8.2, 8.3, 8.4, 8.5_
  
  - [x] 8.4 Update budget summary to use foyer total

    - Load foyer.budgetMensuelEstime instead of sum of limits
    - Display total budget from foyer
    - Calculate remaining from total - spent
    - Update UI to show "Budget total" label
    - _Requirements: 8.1_
  
  - [x] 8.5 Add widget tests for BudgetScreen


    - Test loading state displays correctly
    - Test error state with retry button
    - Test category cards with different alert levels
    - Test pull-to-refresh functionality
    - Test listener registration and cleanup
    - _Requirements: 8.6, 8.7, 8.8_

- [-] 9. Add Budget Management to Settings Screen


  - [x] 9.1 Create budget section in SettingsScreen


    - Add "Budget mensuel" section to settings
    - Display current total budget from foyer
    - Add tap handler to show edit dialog
    - Style section consistently with other settings
    - _Requirements: 7.1_
  
  - [x] 9.2 Implement budget edit dialog

    - Create dialog with TextFormField for budget amount
    - Add validation for positive values
    - Add validation for reasonable range (50€ - 2000€)
    - Show current value as initial text
    - Add Cancel and Save buttons
    - _Requirements: 7.2, 7.3_
  
  - [x] 9.3 Implement budget update logic

    - Update foyer.budgetMensuelEstime in database
    - Call BudgetService.recalculateCategoryBudgets()
    - Enqueue foyer update for sync
    - Show success SnackBar with confirmation message
    - Show error SnackBar if update fails
    - _Requirements: 7.4, 7.5, 7.6, 7.7_
  
  - [x] 9.4 Add localized error messages


    - Add French error messages to app_fr.arb
    - Add English error messages to app_en.arb
    - Add Spanish error messages to app_es.arb
    - Use localized strings in all error displays
    - Ensure error messages are user-friendly and actionable
    - _Requirements: 10.5_
  
  - [x] 9.5 Add widget tests for settings budget UI
    - Test budget section displays current value
    - Test edit dialog opens on tap
    - Test validation rejects invalid values
    - Test validation accepts valid values
    - Test success message shown on save
    - Test error message shown on failure
    - _Requirements: 7.1, 7.2, 7.3_

- [x] 10. Implement Enhanced initializeRecommendedBudgets




  - [x] 10.1 Update initializeRecommendedBudgets to use BudgetAllocationRules

    - Call BudgetAllocationRules.calculateRecommendedBudgets()
    - Pass foyer and PriceService to calculation
    - Create categories with calculated amounts and percentages
    - Store percentage in database
    - _Requirements: 1.1, 1.3, 6.4, 6.5, 6.6, 6.7_
  


  - [x] 10.2 Update onboarding flow to initialize budgets

    - Call initializeRecommendedBudgets() after foyer creation
    - Pass foyer_id to initialization
    - Log 'onboarding_completed_with_budgets' analytics event
    - Handle errors gracefully (use defaults if calculation fails)
    - _Requirements: 1.1, 1.3, 9.7_

  

  - [x] 10.3 Add integration tests for onboarding budget initialization

    - Test budgets created during onboarding
    - Test percentages sum to 1.0 (100%)
    - Test amounts are reasonable for household profile
    - Test fallback to defaults if PriceService unavailable
    - Test analytics event logged
    - _Requirements: 1.1, 1.3, 9.7_

- [x] 11. Add Comprehensive Analytics Tracking

  - [ ] 11.1 Add screen view tracking
    - Log 'screen_view' event when BudgetScreen mounted
    - Include screen_name='budget' parameter
    - Include timestamp parameter
    - _Requirements: 9.1_
  
  - [ ] 11.2 Add category management tracking
    - Log 'budget_category_added' on create with category name
    - Log 'budget_category_edited' on update with category name and limit_changed flag
    - Log 'budget_category_deleted' on delete with category name
    - _Requirements: 9.2, 9.3, 9.4_
  

  - [ ] 11.3 Add budget alert tracking
    - Log 'budget_alert_triggered' when notification shown
    - Include category, percentage, alert_level parameters
    - Include spent and limit amounts
    - _Requirements: 9.5_
  
  - [ ] 11.4 Add savings tips tracking
    - Log 'budget_savings_tips_clicked' when user taps Conseils button
    - Include timestamp parameter
    - _Requirements: 9.6_
  
  - [ ] 11.5 Add migration tracking
    - Log 'budget_migration_completed' after successful migration
    - Include from_version and to_version parameters
    - _Requirements: 9.8_
  
  - [ ] 11.6 Add total budget update tracking
    - Log 'budget_total_updated' when user changes total budget
    - Include old_amount and new_amount parameters
    - Include number of categories recalculated
    - _Requirements: 7.4, 7.5_

- [x] 12. Implement Comprehensive Error Handling



  - [x] 12.1 Add error handling to BudgetService operations


    - Wrap all database operations in try-catch
    - Log errors with ErrorLoggerService
    - Return safe defaults instead of throwing (e.g., empty list)
    - Add severity levels to error logs
    - _Requirements: 10.1, 10.2_
  
  - [x] 12.2 Add error handling to budget calculations

    - Handle division by zero in percentage calculations
    - Handle null/missing foyer data
    - Use fallback values when calculations fail
    - Show warning banner to user
    - _Requirements: 10.3_
  
  - [x] 12.3 Add error handling to sync operations

    - Implement exponential backoff for retries
    - Limit retries to 5 attempts
    - Log sync failures with context
    - Don't block local operations on sync failure
    - _Requirements: 10.4, 4.7_
  
  - [x] 12.4 Add error handling to notification operations


    - Catch notification permission errors
    - Fall back to in-app banners if notifications fail
    - Log notification failures
    - Don't block budget operations on notification failure
    - _Requirements: 10.6, 2.6_
  

  - [x] 12.5 Add error handling to migration

    - Wrap migration in transaction for atomicity
    - Implement rollback on migration failure
    - Log migration errors with full context
    - Allow app to continue with old schema if migration fails
    - _Requirements: 10.7, 5.7_
  


  - [x] 12.6 Add localized error messages for all scenarios





    - Database connection errors
    - Budget calculation errors
    - Sync failures
    - Notification permission errors
    - Migration failures
    - Validation errors (budget amount out of range)
    - Network errors
    - Ensure all messages are in French, English, and Spanish
    - _Requirements: 10.5_

- [x] 13. Write Integration Tests





  - [x] 13.1 End-to-end budget flow test


    - Test: Create inventory item → budget updates → notification shown → UI refreshes
    - Verify budget spending increases correctly
    - Verify notification triggered at correct threshold
    - Verify BudgetScreen shows updated data
    - _Requirements: 3.2, 3.3, 3.5_
  
  - [x] 13.2 Total budget update flow test


    - Test: Update total budget → categories recalculated → UI reflects changes
    - Verify all category limits updated proportionally
    - Verify percentages maintained
    - Verify sync operations enqueued
    - _Requirements: 1.2, 7.5, 7.6_
  


  - [ ] 13.3 Observer pattern test
    - Test: BudgetScreen mounts → registers listener
    - Test: Budget updated → screen refreshes automatically
    - Test: Screen disposed → listener unregistered (no memory leak)


    - _Requirements: 3.4, 3.5, 3.6_
  
  - [ ] 13.4 Migration flow test
    - Test: Install with old schema → migration runs → data preserved → new features work
    - Verify percentages calculated correctly from existing data


    - Verify foyer.budgetMensuelEstime set if missing
    - Verify app continues if migration fails
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_
  
  - [ ] 13.5 Sync integration test
    - Test: Budget operations enqueue sync correctly
    - Test: Sync disabled → operations still work locally
    - Test: Sync fails → retries with backoff
    - Test: Sync succeeds → operations marked as synced
    - _Requirements: 4.1, 4.2, 4.3, 4.6, 4.7_

- [ ] 14. Performance Optimization and Testing
  - [ ] 14.1 Implement database indexes
    - Create index on budget_categories(month)
    - Create index on budget_categories(name, month)
    - Verify query performance improvement
    - _Requirements: Performance targets_
  
  - [ ] 14.2 Implement debouncing for rapid updates
    - Set debounce duration to 500ms
    - Test with rapid inventory additions
    - Verify only one UI update occurs
    - _Requirements: 3.7_
  
  - [ ] 14.3 Profile and optimize budget calculations
    - Use Flutter DevTools to profile BudgetScreen load
    - Optimize database queries
    - Cache foyer data in FoyerProvider
    - Target: BudgetScreen load < 800ms
    - _Requirements: Performance targets_
  
  - [ ] 14.4 Profile and optimize migration
    - Test migration with large datasets (100+ categories)
    - Optimize batch operations
    - Target: Migration < 2 seconds
    - _Requirements: Performance targets_
  
  - [ ] 14.5 Memory leak testing
    - Test BudgetScreen mount/unmount cycles
    - Verify listeners properly cleaned up
    - Verify no memory growth over time
    - Target: < 50MB for budget operations
    - _Requirements: 3.6, Performance targets_

- [ ] 15. Documentation and Deployment
  - [ ] 15.1 Update technical documentation
    - Update Gestion_Budget_NgonNest.md with new features
    - Document BudgetAllocationRules usage
    - Document migration process
    - Add code examples for common scenarios
    - _Requirements: All_
  
  - [ ] 15.2 Update user-facing documentation
    - Create user guide for budget management
    - Document how to set total budget
    - Explain budget notifications
    - Add FAQ section
    - Translate to French, English, Spanish
    - _Requirements: All_
  
  - [ ] 15.3 Create deployment checklist
    - Verify all tests passing
    - Verify migration tested with production-like data
    - Verify analytics events configured
    - Verify error logging configured
    - Verify notification permissions requested
    - _Requirements: All_
  
  - [ ] 15.4 Prepare rollback plan
    - Document rollback procedure
    - Create database backup script
    - Test rollback on staging environment
    - Document feature flag to disable new features
    - _Requirements: Deployment strategy_
  
  - [ ] 15.5 Configure monitoring and alerts
    - Set up alerts for migration failures
    - Set up alerts for high error rates
    - Configure dashboard for budget metrics
    - Set up analytics funnel for budget flow
    - _Requirements: Monitoring and analytics_
