# Requirements Document

## Introduction

This specification addresses critical architectural gaps in NgonNest's budget management system to transform it from a static, disconnected, and ignored feature into a dynamic, real-time, and intelligent budget tracking system. The current implementation has several critical issues:

1. **Static budgets**: Budget categories use hardcoded values (120€, 80€, etc.) with no relationship to the household's total monthly budget
2. **Console-only notifications**: Budget alerts are logged to console instead of showing real system notifications to users also
3. **No auto-refresh**: BudgetScreen doesn't automatically update when inventory changes affect budgets
4. **Missing sync integration**: Budget operations aren't enqueued in SyncService for cloud synchronization
<!-- 5. **No migration strategy**: Existing users can't benefit from the new intelligent budget system -->

This feature will implement a percentage-based dynamic budget system, real-time notifications, observer pattern for auto-refresh, complete sync integration, and a migration system for existing users. The implementation prioritizes gaps #1 (real notifications), #7 (dynamic budgets), and #9 (migration) first, with remaining improvements following in the same spec.

## Requirements

### Requirement 1: Dynamic Percentage-Based Budget System

**User Story:** As a household manager, I want my category budgets to automatically adjust when I change my total monthly budget, so that my budget allocations remain proportional and realistic without manual recalculation.

#### Acceptance Criteria

1. WHEN a foyer is created with a total monthly budget THEN the system SHALL calculate category budgets as percentages of the total (Hygiène: h%, Nettoyage: n%, Cuisine: c%, Divers(Pleasure,gifts,offrands,...): d%) based on what is done widely about budget repartition in these categories for students and family households in the world.
2. WHEN the user updates their total monthly budget in settings THEN the system SHALL automatically recalculate all category budgets maintaining the same percentages
3. WHEN budget categories are initialized during onboarding THEN the system SHALL use the foyer's budgetMensuelEstime to calculate recommended amounts
4. IF a user manually adjusts a category budget THEN the system SHALL store the custom percentage for that category
5. WHEN displaying budget information THEN the system SHALL show both the amount and the percentage of total budget
6. WHEN the total budget is zero or not set THEN the system SHALL use default fallback amounts (120€, 80€, 100€, 60€) based on the sized of the foyer median salary on Cameroon(converted after in euros)

### Requirement 2: Real-Time System Notifications

**User Story:** As a user, I want to receive actual system notifications when I exceed or approach my budget limits, so that I'm immediately aware of my spending status even when not actively using the app.

#### Acceptance Criteria

1. WHEN a budget category reaches 80% of its limit THEN the system SHALL show a warning notification with the message "⚠️ Budget [Category] à 80% - Il vous reste [amount]€ pour ce mois"
2. WHEN a budget category reaches 100% of its limit THEN the system SHALL show an alert notification with the message "🚨 Budget [Category] dépassé - Vous avez dépensé [spent]€ sur [limit]€"
3. WHEN a budget category reaches 120% of its limit THEN the system SHALL show a critical notification with the message "⛔ Budget [Category] largement dépassé - Attention à vos dépenses"
4. WHEN a budget notification is triggered THEN the system SHALL use NotificationService.showBudgetAlert() instead of debugPrint()
5. WHEN a budget alert is shown THEN the system SHALL log the event to AnalyticsService with event name 'budget_alert_triggered' and metadata including category, percentage, and severity level
6. IF notification permissions are not granted THEN the system SHALL fall back to in-app banner alerts

### Requirement 3: Auto-Refresh with Observer Pattern

**User Story:** As a user, I want the budget screen to automatically update when I add or modify inventory items, so that I always see current spending information without manually refreshing.

#### Acceptance Criteria

1. WHEN BudgetService is instantiated THEN it SHALL extend ChangeNotifier to support observer pattern
2. WHEN InventoryRepository creates or updates an objet THEN it SHALL call BudgetService.checkBudgetAlertsAfterPurchase()
3. WHEN BudgetService updates a budget category's spending THEN it SHALL call notifyListeners() to notify all observers
4. WHEN BudgetScreen is mounted THEN it SHALL register as a listener to BudgetService changes
5. WHEN BudgetService notifies listeners THEN BudgetScreen SHALL automatically reload budget data without user interaction
6. WHEN BudgetScreen is disposed THEN it SHALL unregister from BudgetService listeners to prevent memory leaks
7. WHEN multiple inventory operations occur rapidly THEN the system SHALL debounce notifications to avoid excessive UI updates (max 1 update per 500ms)

### Requirement 4: Complete SyncService Integration

**User Story:** As a user with cloud sync enabled, I want all my budget operations to synchronize to the cloud, so that my budget data is backed up and accessible across devices.

#### Acceptance Criteria

1. WHEN a budget category is created THEN the system SHALL call SyncService.enqueueOperation() with operation_type='CREATE', entity_type='budget_categories', and the category data
2. WHEN a budget category is updated THEN the system SHALL call SyncService.enqueueOperation() with operation_type='UPDATE', entity_type='budget_categories', and the updated data
3. WHEN a budget category is deleted THEN the system SHALL call SyncService.enqueueOperation() with operation_type='DELETE', entity_type='budget_categories', and the category id
4. WHEN budget spending is automatically updated from inventory changes THEN the system SHALL enqueue the update operation for sync
5. WHEN sync operations are enqueued THEN they SHALL include all necessary payload data (id, name, limit_amount, spent_amount, month, foyer_id)
6. IF SyncService is disabled or user hasn't consented THEN operations SHALL still be enqueued but not synced until enabled
7. WHEN sync fails with retry exhaustion THEN the system SHALL log the error but NOT block local budget operations

### Requirement 5: Migration System for Existing Users

**User Story:** As an existing user upgrading to the new version, I want my budget data to be automatically migrated to the new percentage-based system, so that I can benefit from dynamic budgets without losing my existing data.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL check the database schema version
2. IF the schema version is less than the required version THEN the system SHALL execute migration scripts in sequence
3. WHEN migrating from vx to vy THEN the system SHALL add a 'percentage' column to budget_categories table with default values (Hygiène: 0.33, Nettoyage: 0.22, Cuisine: 0.28, Divers: 0.17)
4. WHEN migrating existing budget categories THEN the system SHALL calculate percentages based on current limit amounts and foyer's budgetMensuelEstime
5. IF a foyer doesn't have budgetMensuelEstime set THEN the migration SHALL calculate it as the sum of all category limits
6. WHEN migration completes successfully THEN the system SHALL update the schema version in the database
7. WHEN migration fails THEN the system SHALL log the error, rollback changes, and allow the app to continue with the old schema
8. WHEN migration is complete THEN the system SHALL log analytics event 'migration_completed' with version information

### Requirement 6: Budget Allocation Rules Engine

**User Story:** As a household manager, I want the system to intelligently recommend budget allocations based on my household profile, so that my budgets are realistic for my family size and living situation.

#### Acceptance Criteria

1. WHEN calculating recommended budgets THEN the system SHALL apply household size multiplier: base * (1.0 + (nb_personnes - 1) * 0.3)
2. WHEN calculating recommended budgets THEN the system SHALL apply housing type multiplier: 1.2 for 'maison', 1.0 for 'appartement'
3. WHEN calculating recommended budgets THEN the system SHALL apply room count multiplier for cleaning products: base * (1.0 + (nb_pieces - 1) * 0.15)
4. WHEN calculating Hygiène budget THEN the system SHALL use formula: averagePrice * 15 * personMultiplier, clamped between 80€ and 300€
5. WHEN calculating Nettoyage budget THEN the system SHALL use formula: averagePrice * 10 * roomMultiplier, clamped between 60€ and 200€
6. WHEN calculating Cuisine budget THEN the system SHALL use formula: averagePrice * 12 * personMultiplier, clamped between 70€ and 250€
7. WHEN calculating Divers budget THEN the system SHALL use formula: averagePrice * 8 * totalMultiplier, clamped between 40€ and 150€
8. IF PriceService returns no average price THEN the system SHALL use fallback base prices (Hygiène: 8€, Nettoyage: 8€, Cuisine: 8.33€, Divers: 7.5€)

### Requirement 7: Settings Integration for Budget Management

**User Story:** As a user, I want to view and modify my total monthly budget from the settings screen, so that I can easily adjust my budget as my financial situation changes.

#### Acceptance Criteria

1. WHEN the user opens Settings screen THEN they SHALL see a "Budget mensuel" section displaying the current total budget
2. WHEN the user taps on the budget section THEN the system SHALL show a dialog to edit the total monthly budget
3. WHEN the user updates the total budget THEN the system SHALL validate that the amount is positive and reasonable (between 50€ and 2000€)
4. WHEN the user saves a new total budget THEN the system SHALL update foyer.budgetMensuelEstime in the database
5. WHEN the total budget is updated THEN the system SHALL call BudgetService.recalculateCategoryBudgets() to update all category budgets
6. WHEN category budgets are recalculated THEN the system SHALL maintain custom percentages if the user has manually adjusted categories
7. WHEN the budget update completes THEN the system SHALL show a success message and enqueue the foyer update for sync

### Requirement 8: Enhanced Budget Screen UI

**User Story:** As a user, I want to see clear visual indicators of my budget status, so that I can quickly understand my spending situation at a glance.

#### Acceptance Criteria

1. WHEN displaying budget summary THEN the system SHALL show total budget from foyer.budgetMensuelEstime instead of sum of category limits
2. WHEN a category is over budget THEN the card SHALL display with red accent color and warning icon
3. WHEN a category is near limit (>80%) THEN the card SHALL display with orange accent color and caution icon
4. WHEN a category is under 80% THEN the card SHALL display with green accent color
5. WHEN displaying spending percentage THEN the system SHALL show a progress bar with color coding (green <80%, orange 80-100%, red >100%)
6. WHEN the budget screen loads THEN it SHALL show a loading state with skeleton cards
7. IF an error occurs loading budget data THEN the system SHALL show an error message with a retry button
8. WHEN the user pulls to refresh THEN the system SHALL reload budget data and sync with purchases

### Requirement 9: Analytics and Monitoring

**User Story:** As a product manager, I want comprehensive analytics on budget usage, so that I can understand user behavior and improve the feature.

#### Acceptance Criteria

1. WHEN a user views the budget screen THEN the system SHALL log event 'screen_view' with screen_name='budget'
2. WHEN a user adds a budget category THEN the system SHALL log event 'budget_category_added' with category name
3. WHEN a user edits a budget category THEN the system SHALL log event 'budget_category_edited' with category name and whether limit was changed
4. WHEN a user deletes a budget category THEN the system SHALL log event 'budget_category_deleted' with category name
5. WHEN a budget alert is triggered THEN the system SHALL log event 'budget_alert_triggered' with category, percentage, and alert level (warning/alert/critical)
6. WHEN the user clicks "Conseils" button THEN the system SHALL log event 'budget_savings_tips_clicked'
7. WHEN budget categories are initialized during onboarding THEN the system SHALL log event 'onboarding_completed_with_budgets' with number of categories created
8. WHEN migration completes THEN the system SHALL log event 'budget_migration_completed' with from_version and to_version

### Requirement 10: Error Handling and Resilience

**User Story:** As a user, I want the budget system to work reliably even when there are errors, so that I can always track my spending without app crashes.

#### Acceptance Criteria

1. WHEN any budget operation fails THEN the system SHALL log the error using ErrorLoggerService with appropriate severity
2. WHEN BudgetService.getBudgetCategories() fails THEN it SHALL return an empty list instead of throwing an exception
3. WHEN budget calculation fails THEN the system SHALL use the last known values and show a warning banner
4. WHEN sync operations fail THEN the system SHALL retry with exponential backoff up to 5 times
5. IF database operations fail THEN the system SHALL show user-friendly error messages in French
6. WHEN NotificationService fails to show a notification THEN the system SHALL fall back to in-app alerts
7. WHEN migration fails THEN the system SHALL rollback to the previous schema version and log the error for debugging
