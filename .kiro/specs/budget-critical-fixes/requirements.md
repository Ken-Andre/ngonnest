# Requirements Document

## Introduction

Cette spécification adresse les problèmes critiques identifiés dans le système de gestion budgétaire de NgonNest qui empêchent son fonctionnement correct. Malgré l'existence d'une architecture solide, plusieurs bugs et gaps d'implémentation rendent le système inutilisable en production.

## Glossary

- **BudgetService**: Service gérant les catégories budgétaires et le suivi des dépenses
- **BudgetScreen**: Écran d'interface utilisateur affichant les budgets et catégories
- **AnalyticsService**: Service Firebase Analytics pour le tracking des événements
- **NotificationService**: Service gérant les notifications système
- **ChangeNotifier**: Pattern Flutter pour notifier les observateurs de changements d'état
- **Pull-to-refresh**: Geste utilisateur pour rafraîchir manuellement les données
- **Firebase Analytics**: Plateforme d'analyse qui n'accepte que des paramètres string/number/boolean

## Requirements

### Requirement 1: Fix ChangeNotifier Implementation in BudgetService

**User Story:** En tant qu'utilisateur, je veux que l'écran budget se rafraîchisse automatiquement quand j'ajoute ou modifie un produit, pour que je voie toujours mes dépenses à jour sans action manuelle.

#### Acceptance Criteria

1. WHEN BudgetService extends ChangeNotifier THEN it SHALL properly notify all registered listeners on data changes
2. WHEN BudgetScreen mounts THEN it SHALL register as a listener to BudgetService using context.read<BudgetService>()
3. WHEN BudgetService updates budget data THEN it SHALL call notifyListeners() to trigger UI refresh
4. WHEN BudgetScreen unmounts THEN it SHALL unregister its listener to prevent memory leaks
5. WHEN multiple rapid updates occur THEN the system SHALL debounce notifications to avoid excessive UI rebuilds
6. WHEN BudgetService is provided via Provider THEN it SHALL be a singleton instance accessible throughout the app
7. IF notifyListeners() is called while no listeners are registered THEN the system SHALL not throw an error

### Requirement 2: Fix Firebase Analytics Boolean Parameters

**User Story:** En tant que développeur, je veux que tous les événements Analytics soient envoyés correctement à Firebase, pour que nous puissions analyser le comportement utilisateur sans erreurs.

#### Acceptance Criteria

1. WHEN logging analytics events with boolean values THEN the system SHALL convert them to string ('true'/'false')
2. WHEN BudgetService logs 'budget_category_edited' event THEN the 'limit_changed' parameter SHALL be a string not a boolean
3. WHEN any service logs analytics events THEN all parameters SHALL be of type string, number, or null only
4. WHEN AnalyticsService receives invalid parameter types THEN it SHALL log a warning and convert or skip the parameter
5. IF a boolean parameter is required for business logic THEN it SHALL be converted to string before passing to Firebase
6. WHEN reviewing analytics events THEN no Firebase errors SHALL appear in logs related to parameter types

### Requirement 3: Implement Real System Notifications for Budget Alerts

**User Story:** En tant qu'utilisateur, je veux recevoir de vraies notifications système quand je dépasse mon budget, pour être alerté même quand l'app n'est pas ouverte.

#### Acceptance Criteria

1. WHEN a budget category reaches 80% THEN the system SHALL show a system notification with title and body
2. WHEN a budget category reaches 100% THEN the system SHALL show a critical system notification
3. WHEN a budget category reaches 120% THEN the system SHALL show an urgent system notification
4. WHEN _triggerBudgetAlert() is called THEN it SHALL call NotificationService.showBudgetAlert() AND log the event using ErrorLoggerService
5. WHEN NotificationService.showBudgetAlert() is called THEN it SHALL use flutter_local_notifications to show real notifications
6. IF notification permissions are denied THEN the system SHALL fall back to in-app SnackBar alerts
7. WHEN a notification is shown THEN it SHALL be logged using ErrorLoggerService with severity INFO for debugging purposes
8. WHEN a notification fails to show THEN it SHALL be logged using ErrorLoggerService with severity ERROR including the error details

### Requirement 4: Connect Inventory Operations to Budget Updates

**User Story:** En tant qu'utilisateur, je veux que mes budgets se mettent à jour automatiquement quand j'ajoute un produit, pour suivre mes dépenses en temps réel.

#### Acceptance Criteria

1. WHEN InventoryRepository.create() adds a product THEN it SHALL call BudgetService.checkBudgetAlertsAfterPurchase()
2. WHEN InventoryRepository.update() modifies a product price THEN it SHALL call BudgetService.checkBudgetAlertsAfterPurchase()
3. WHEN checkBudgetAlertsAfterPurchase() is called THEN it SHALL recalculate spending for the affected category
4. WHEN category spending is updated THEN BudgetService SHALL call notifyListeners() to refresh BudgetScreen
5. IF the budget update fails THEN the inventory operation SHALL still succeed (non-blocking)
6. WHEN a product is added without a price THEN no budget update SHALL be triggered
7. WHEN a product category doesn't match any budget category THEN no error SHALL be thrown

### Requirement 5: Fix BudgetScreen Data Source

**User Story:** En tant qu'utilisateur, je veux voir mes vrais budgets configurés dans les paramètres, pas des valeurs statiques ou calculées localement.

#### Acceptance Criteria

1. WHEN BudgetScreen loads THEN it SHALL fetch data from BudgetService via Provider not local state
2. WHEN displaying total budget THEN it SHALL use foyer.budgetMensuelEstime from FoyerProvider
3. WHEN displaying category budgets THEN it SHALL use BudgetService.getBudgetCategories()
4. WHEN BudgetService notifies listeners THEN BudgetScreen SHALL automatically reload data
5. IF foyer.budgetMensuelEstime is null or zero THEN it SHALL display a message prompting user to set budget in settings
6. WHEN budget data changes in SettingsScreen THEN BudgetScreen SHALL reflect changes immediately
7. WHEN BudgetScreen is not visible THEN it SHALL not reload data unnecessarily

### Requirement 6: Implement Pull-to-Refresh Globally

**User Story:** En tant qu'utilisateur, je veux pouvoir rafraîchir manuellement mes données en tirant vers le bas, pour forcer une mise à jour quand je le souhaite.

#### Acceptance Criteria

1. WHEN BudgetScreen is displayed THEN it SHALL wrap content in RefreshIndicator
2. WHEN user pulls down on BudgetScreen THEN it SHALL call _loadBudgetData() and show loading indicator
3. WHEN InventoryScreen is displayed THEN it SHALL wrap content in RefreshIndicator
4. WHEN user pulls down on InventoryScreen THEN it SHALL reload inventory data
5. WHEN DashboardScreen is displayed THEN it SHALL wrap content in RefreshIndicator
6. WHEN refresh completes successfully THEN the loading indicator SHALL disappear
7. IF refresh fails THEN an error message SHALL be shown and loading indicator SHALL disappear

### Requirement 7: Implement Dynamic Budget Recalculation

**User Story:** En tant qu'utilisateur, je veux que mes catégories budgétaires s'ajustent automatiquement quand je change mon budget total, pour maintenir des proportions cohérentes.

#### Acceptance Criteria

1. WHEN user updates total budget in SettingsScreen THEN BudgetService.recalculateCategoryBudgets() SHALL be called
2. WHEN recalculateCategoryBudgets() executes THEN it SHALL update all category limits based on their percentages
3. WHEN category limits are recalculated THEN the system SHALL maintain custom percentages if user modified them
4. WHEN recalculation completes THEN BudgetService SHALL call notifyListeners()
5. IF total budget is set to zero THEN the system SHALL use default fallback amounts
6. WHEN recalculation fails THEN the system SHALL log error and keep existing values
7. WHEN recalculation succeeds THEN an analytics event 'budget_total_updated' SHALL be logged

### Requirement 8: Fix Error Handling in Budget UI

**User Story:** En tant qu'utilisateur, je veux voir des messages d'erreur clairs en français quand quelque chose ne fonctionne pas, pour comprendre le problème et savoir quoi faire.

#### Acceptance Criteria

1. WHEN BudgetScreen fails to load data THEN it SHALL display an error message in French
2. WHEN an error occurs THEN it SHALL show a "Réessayer" button to retry the operation
3. WHEN budget operations fail THEN error messages SHALL be user-friendly not technical
4. WHEN displaying errors THEN the system SHALL use ErrorLoggerService not print() or debugPrint()
5. IF network is unavailable THEN error message SHALL indicate offline mode
6. WHEN retry succeeds THEN error state SHALL clear and data SHALL display
7. WHEN multiple errors occur THEN only the most recent error SHALL be displayed

### Requirement 9: Fix Budget Expense History Display

**User Story:** En tant qu'utilisateur, je veux voir l'historique de mes dépenses par catégorie, pour comprendre mes habitudes de consommation sur plusieurs mois.

#### Acceptance Criteria

1. WHEN user taps on a budget category THEN it SHALL navigate to expense history screen
2. WHEN expense history loads THEN it SHALL display spending for last 12 months
3. WHEN displaying history THEN it SHALL show month name, spending amount, and percentage of limit
4. WHEN history data is unavailable THEN it SHALL show an empty state with explanation
5. IF spending data exists THEN it SHALL display a chart showing trends over time
6. WHEN history screen loads THEN it SHALL call BudgetService.getMonthlyExpenseHistory()
7. WHEN user navigates back THEN BudgetScreen SHALL still show current data

### Requirement 10: Fix Connectivity and Sync Integration

**User Story:** En tant qu'utilisateur, je veux que mes opérations budgétaires se synchronisent avec le cloud quand je suis en ligne, pour ne pas perdre mes données.

#### Acceptance Criteria

1. WHEN BudgetService creates a category THEN it SHALL call SyncService.enqueueOperation()
2. WHEN BudgetService updates a category THEN it SHALL call SyncService.enqueueOperation()
3. WHEN BudgetService deletes a category THEN it SHALL call SyncService.enqueueOperation()
4. WHEN sync operations are enqueued THEN they SHALL include operation_type, entity_type, and payload
5. IF SyncService is disabled THEN operations SHALL still be enqueued but not synced
6. WHEN sync fails THEN it SHALL retry with exponential backoff
7. IF sync fails after max retries THEN the system SHALL log error but not block local operations

