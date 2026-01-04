# Implementation Plan

- [x] 1. Fix BudgetService Provider Setup and ChangeNotifier
  - Add BudgetService to MultiProvider in main.dart as ChangeNotifierProvider
  - Verify BudgetService singleton pattern works correctly
  - Test that BudgetService can be accessed via context.read<BudgetService>()
  - _Requirements: 1.6_

- [x] 2. Fix notifyListeners() Calls in BudgetService




  - [x] 2.1 Add notifyListeners() to createBudgetCategory()


    - Call notifyListeners() after successful category creation
    - Ensure it's called after analytics tracking
    - _Requirements: 1.3_
  

  - [x] 2.2 Add notifyListeners() to updateBudgetCategory()

    - Call notifyListeners() after successful category update
    - Ensure it's called after analytics tracking
    - _Requirements: 1.3_
  


  - [x] 2.3 Add notifyListeners() to deleteBudgetCategory()

    - Call notifyListeners() after successful category deletion
    - Ensure it's called after analytics tracking
    - _Requirements: 1.3_


  
  - [x] 2.4 Add notifyListeners() to recalculateCategoryBudgets()

    - Call notifyListeners() after all categories recalculated
    - Ensure it's called after analytics tracking
    - _Requirements: 1.3, 7.4_


  

  - [ ] 2.5 Add notifyListeners() to checkBudgetAlertsAfterPurchase()
    - Call notifyListeners() after spending updated
    - Ensure it's called after alert check
    - _Requirements: 1.3, 4.4_

- [x] 3. Implement BudgetScreen Listener Registration





  - [x] 3.1 Add listener registration in initState()

    - Get BudgetService instance using context.read<BudgetService>()
    - Call addListener(_onBudgetChanged) to register callback
    - Store BudgetService reference in _budgetService field
    - _Requirements: 1.2_
  
  - [x] 3.2 Implement _onBudgetChanged() callback

    - Check if widget is mounted before updating
    - Call _loadBudgetData() to refresh UI
    - _Requirements: 1.1, 5.4_
  
  - [x] 3.3 Add listener cleanup in dispose()

    - Call removeListener(_onBudgetChanged) to unregister
    - Prevent memory leaks
    - _Requirements: 1.4_
  
  - [x] 3.4 Add debouncing to prevent excessive updates


    - Implement Timer to debounce rapid updates
    - Set debounce duration to 500ms
    - Cancel timer in dispose()
    - _Requirements: 1.5_

- [x] 4. Fix Firebase Analytics Boolean Parameters





  - [x] 4.1 Add parameter sanitization in AnalyticsService.logEvent()


    - Map over parameters to convert booleans to strings
    - Convert true → 'true', false → 'false'
    - Leave other types unchanged
    - _Requirements: 2.1, 2.5_
  
  - [x] 4.2 Fix BudgetService analytics calls


    - Update 'budget_category_edited' event to use string for 'limit_changed'
    - Verify all other analytics calls use correct types
    - _Requirements: 2.2, 2.3_
  
  - [x] 4.3 Add validation and logging for invalid parameters


    - Log warning when invalid parameter type detected
    - Skip invalid parameters instead of crashing
    - _Requirements: 2.4, 2.6_

- [x] 5. Implement Real System Notifications for Budget Alerts



  - [x] 5.1 Create BudgetNotifications extension on NotificationService

    - Create static method showBudgetAlert()
    - Accept BudgetCategory and AnalyticsService parameters
    - _Requirements: 3.4_
  

  - [x] 5.2 Implement notification content logic
    - Determine title, body, priority based on alertLevel
    - Use appropriate emoji and wording for each level (warning/alert/critical)
    - _Requirements: 3.1, 3.2, 3.3_

  
  - [x] 5.3 Call flutter_local_notifications to show notification
    - Use NotificationService.showNotification() method
    - Set channelId='budget_alerts', channelName='Alertes Budgétaires'
    - Pass appropriate priority level

    - _Requirements: 3.5_
  
  - [x] 5.4 Add fallback to SnackBar for denied permissions
    - Catch notification permission errors

    - Show in-app SnackBar with same message
    - _Requirements: 3.6_
  
  - [x] 5.5 Add comprehensive logging
    - Log notification shown with INFO severity for debugging

    - Log notification failures with ERROR severity
    - Include all relevant metadata (category, alert_level, spending)
    - _Requirements: 3.7, 3.8_
  

  - [x] 5.6 Track analytics event
    - Log 'budget_alert_triggered' event
    - Include category, percentage, alert_level, spent, limit
    - _Requirements: 3.7_
  
  - [ ] 5.7 Update BudgetService._triggerBudgetAlert()

    - Replace debugPrint() with BudgetNotifications.showBudgetAlert()
    - Keep error handling to not block budget operations
    - _Requirements: 3.4_

- [x] 6. Connect Inventory Operations to Budget Updates






  - [x] 6.1 Add BudgetService instance to InventoryRepository




    - Create _budgetService field
    - Initialize with BudgetService() singleton
    - _Requirements: 4.1_
  
  - [x] 6.2 Update InventoryRepository.create()

    - Check if prixUnitaire is set and > 0
    - Call _budgetService.checkBudgetAlertsAfterPurchase()
    - Wrap in try-catch to not block inventory operation
    - Log errors with LOW severity
    - _Requirements: 4.1, 4.5_
  
  - [x] 6.3 Update InventoryRepository.update()

    - Get original object to check if price changed
    - Check if prix_unitaire changed in updates
    - Call _budgetService.checkBudgetAlertsAfterPurchase() if changed
    - Wrap in try-catch to not block inventory operation
    - Log errors with LOW severity
    - _Requirements: 4.2, 4.5_
  
  - [x] 6.4 Handle products without prices

    - Skip budget update if prixUnitaire is null or 0
    - No error should be thrown
    - _Requirements: 4.6_
  
  - [x] 6.5 Handle category mismatches

    - Skip budget update if category doesn't match any budget category
    - No error should be thrown
    - _Requirements: 4.7_

- [x] 7. Fix BudgetScreen Data Source








  - [x] 7.1 Update _loadBudgetData() to use Provider



    - Use context.read<FoyerProvider>() to get foyer data
    - Get budgetMensuelEstime from foyer
    - Use this as totalBudget instead of sum of category limits
    - _Requirements: 5.2, 5.3_
  
  - [x] 7.2 Handle null or zero total budget



    - Check if budgetMensuelEstime is null or 0
    - Show message prompting user to set budget in settings
    - Provide button to navigate to settings
    - _Requirements: 5.5_
  
  - [x] 7.3 Ensure BudgetScreen reflects settings changes



    - Verify listener registration works
    - Test that changing budget in settings updates BudgetScreen
    - _Requirements: 5.6_
  
  - [x] 7.4 Optimize data loading



    - Only reload when screen is visible
    - Add _isLoadingData flag to prevent infinite loops
    - _Requirements: 5.7_
-

- [x] 8. Implement Pull-to-Refresh Globally



  - [x] 8.1 Add RefreshIndicator to BudgetScreen



    - Wrap ListView in RefreshIndicator
    - Set onRefresh to _loadBudgetData
    - _Requirements: 6.1, 6.2_
  
  - [x] 8.2 Add RefreshIndicator to InventoryScreen




    - Wrap ListView in RefreshIndicator
    - Set onRefresh to reload inventory data
    - _Requirements: 6.3, 6.4_
  
  - [x] 8.3 Add RefreshIndicator to DashboardScreen



    - Wrap content in RefreshIndicator
    - Set onRefresh to reload dashboard data
    - _Requirements: 6.5_
  
  - [x] 8.4 Handle refresh completion




    - Ensure loading indicator disappears after refresh
    - Show success feedback if needed
    - _Requirements: 6.6_
  
  - [x] 8.5 Handle refresh errors




    - Show error message if refresh fails
    - Keep loading indicator visible until error shown
    - _Requirements: 6.7_

- [x] 9. Implement Dynamic Budget Recalculation

  - [x] 9.1 Verify recalculateCategoryBudgets() implementation


    - Check that it loads all categories for current month
    - Verify it calculates new limits based on percentages
    - Ensure it updates each category in database
    - _Requirements: 7.2, 7.3_
  
  - [x] 9.2 Connect SettingsScreen to recalculation


    - Call BudgetService.recalculateCategoryBudgets() when user updates total budget
    - Pass old and new total budget values
    - _Requirements: 7.1_
  
  - [x] 9.3 Ensure notifyListeners() is called


    - Verify recalculateCategoryBudgets() calls notifyListeners()
    - Test that BudgetScreen updates after recalculation
    - _Requirements: 7.4_
  
  - [x] 9.4 Handle zero total budget


    - Use default fallback amounts if total is 0
    - Log warning but don't throw error
    - _Requirements: 7.5_
  
  - [x] 9.5 Handle recalculation errors


    - Log error with HIGH severity
    - Keep existing values
    - Show user-friendly error message
    - _Requirements: 7.6_
  
  - [x] 9.6 Track analytics event


    - Log 'budget_total_updated' event
    - Include old_amount, new_amount, categories_recalculated
    - _Requirements: 7.7_

- [x] 10. Fix Error Handling in Budget UI


  - [x] 10.1 Add localized error messages to l10n files
    - Add budgetLoadError to app_fr.arb, app_en.arb, app_es.arb
    - Add budgetRetry to all language files
    - Add budgetUpdateError to all language files
    - Add budgetDeleteError to all language files
    - _Requirements: 8.3_
  
  - [x] 10.2 Update BudgetScreen error handling
    - Use AppLocalizations.of(context) to get localized strings
    - Replace hardcoded error messages with localized ones
    - _Requirements: 8.1, 8.3_
  
  - [x] 10.3 Add error state UI with retry button
    - Show error icon, message, and retry button
    - Center content vertically
    - Use theme colors for consistency
    - _Requirements: 8.2_
  
  - [x] 10.4 Log technical errors for debugging
    - Use ErrorLoggerService.logError() for all errors
    - Include component, operation, error, stackTrace
    - Set appropriate severity levels
    - _Requirements: 8.4_
  
  - [x] 10.5 Handle offline mode
    - Detect network unavailability
    - Show specific offline error message
    - _Requirements: 8.5_
  
  - [x] 10.6 Implement retry logic
    - Retry button calls _loadBudgetData()
    - Clear error state before retry
    - Show loading indicator during retry
    - _Requirements: 8.6_
  
  - [x] 10.7 Handle multiple errors
    - Only display most recent error
    - Clear previous error when new one occurs
    - _Requirements: 8.7_

- [-] 11. Fix Budget Expense History Display

  - [x] 11.1 Verify getMonthlyExpenseHistory() implementation





    - Check that it returns last 12 months of data
    - Verify month names are in French
    - Ensure spending amounts are correct
    - _Requirements: 9.2, 9.3_
  
  - [x] 11.2 Create or update expense history screen




    - Navigate to history screen when user taps category
    - Display month, spending, percentage of limit
    - _Requirements: 9.1_
  
  - [ ] 11.3 Add empty state for no history
    - Show message when no data available
    - Explain why history is empty
    - _Requirements: 9.4_
  
  - [ ] 11.4 Add chart for spending trends
    - Use charts library to display trends
    - Show last 6-12 months
    - _Requirements: 9.5_
  
  - [ ] 11.5 Ensure navigation back works
    - Verify BudgetScreen still shows current data after back navigation
    - _Requirements: 9.7_
  
  - [ ] 11.6 Call getMonthlyExpenseHistory() on screen load
    - Pass category name and foyer ID
    - Handle loading and error states
    - _Requirements: 9.6_

- [ ] 12. Integrate SyncService with Budget Operations
  - [ ] 12.1 Add SyncService calls to createBudgetCategory()
    - Call SyncService.enqueueOperation() after DB insert
    - Set operation_type='CREATE', entity_type='budget_categories'
    - Include full category data in payload
    - Wrap in try-catch to not block local operation
    - _Requirements: 10.1, 10.4_
  
  - [ ] 12.2 Add SyncService calls to updateBudgetCategory()
    - Call SyncService.enqueueOperation() after DB update
    - Set operation_type='UPDATE', entity_type='budget_categories'
    - Include updated category data in payload
    - Wrap in try-catch to not block local operation
    - _Requirements: 10.2, 10.4_
  
  - [ ] 12.3 Add SyncService calls to deleteBudgetCategory()
    - Call SyncService.enqueueOperation() after DB delete
    - Set operation_type='DELETE', entity_type='budget_categories'
    - Include category id in payload
    - Wrap in try-catch to not block local operation
    - _Requirements: 10.3, 10.4_
  
  - [ ] 12.4 Handle SyncService disabled
    - Operations should still be enqueued
    - They won't sync until user enables sync
    - _Requirements: 10.5_
  
  - [ ] 12.5 Implement retry with exponential backoff
    - Verify SyncService retries failed operations
    - Check exponential backoff is working
    - _Requirements: 10.6_
  
  - [ ] 12.6 Handle max retries exceeded
    - Log error with HIGH severity
    - Don't block local operations
    - _Requirements: 10.7_

- [ ] 13. Add Comprehensive Unit Tests
  - [ ] 13.1 Test BudgetService notifyListeners()
    - Test that listeners are notified on create
    - Test that listeners are notified on update
    - Test that listeners are notified on delete
    - Test that listeners are notified on recalculation
    - _Requirements: 1.1, 1.3_
  
  - [ ] 13.2 Test AnalyticsService parameter sanitization
    - Test boolean converted to string
    - Test other types unchanged
    - Test invalid parameters handled
    - _Requirements: 2.1, 2.4_
  
  - [ ] 13.3 Test NotificationService.showBudgetAlert()
    - Test notification content for each alert level
    - Test fallback to SnackBar
    - Test analytics tracking
    - _Requirements: 3.1, 3.2, 3.3, 3.6_
  
  - [ ] 13.4 Test InventoryRepository budget integration
    - Test budget updated after product creation
    - Test budget updated after price change
    - Test no update for products without price
    - Test no error for category mismatch
    - _Requirements: 4.1, 4.2, 4.6, 4.7_

- [ ] 14. Add Integration Tests
  - [ ] 14.1 Test Inventory → Budget flow
    - Add product → budget updates → notification shown → UI refreshes
    - Verify spending increases correctly
    - Verify notification triggered at correct threshold
    - Verify BudgetScreen shows updated data
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 14.2 Test Settings → Budget flow
    - Update total budget → categories recalculated → UI updates
    - Verify all category limits updated proportionally
    - Verify percentages maintained
    - Verify BudgetScreen reflects changes
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [ ] 14.3 Test Observer pattern
    - BudgetScreen mounts → registers listener
    - Budget updated → screen refreshes automatically
    - Screen disposed → listener unregistered (no memory leak)
    - _Requirements: 1.2, 1.4, 5.4_
  
  - [ ] 14.4 Test Sync integration
    - Budget operations enqueue sync correctly
    - Sync disabled → operations still work locally
    - Sync fails → retries with backoff
    - _Requirements: 10.1, 10.2, 10.3, 10.5, 10.6_

- [x] 15. Add Widget Tests





  - [x] 15.1 Test BudgetScreen loading state


    - Verify CircularProgressIndicator shown during load
    - Verify loading state clears after data loaded
    - _Requirements: 8.1_
  
  - [x] 15.2 Test BudgetScreen error state

    - Verify error message displayed
    - Verify retry button shown
    - Verify retry button triggers reload
    - _Requirements: 8.1, 8.2, 8.6_
  
  - [x] 15.3 Test BudgetScreen pull-to-refresh

    - Verify RefreshIndicator present
    - Verify pulling down triggers reload
    - Verify loading indicator shown and hidden
    - _Requirements: 6.1, 6.2, 6.6_
  
  - [x] 15.4 Test BudgetScreen listener cleanup

    - Verify listener registered in initState
    - Verify listener unregistered in dispose
    - Verify no memory leaks
    - _Requirements: 1.2, 1.4_

- [ ] 16. Documentation and Deployment
  - [ ] 16.1 Update technical documentation
    - Document all fixes made
    - Update architecture diagrams
    - Add troubleshooting guide
    - _Requirements: All_
  
  - [ ] 16.2 Update user-facing documentation
    - Explain budget notifications
    - Explain pull-to-refresh
    - Add FAQ section
    - _Requirements: All_
  
  - [ ] 16.3 Create deployment checklist
    - Verify all tests passing
    - Verify analytics events configured
    - Verify error logging configured
    - Verify notification permissions requested
    - _Requirements: All_
  
  - [ ] 16.4 Prepare rollback plan
    - Document rollback procedure
    - Test rollback on staging
    - _Requirements: All_
  
  - [ ] 16.5 Configure monitoring and alerts
    - Set up alerts for high error rates
    - Configure dashboard for budget metrics
    - Set up analytics funnel
    - _Requirements: All_

