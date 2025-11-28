import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/foyer.dart';
import '../models/household_profile.dart';
import '../providers/foyer_provider.dart';
import '../repository/inventory_repository.dart';
import '../services/alert_generation_service.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/error_logger_service.dart';
import '../services/household_service.dart';
import '../services/navigation_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_mode_notifier.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../widgets/premium_banner.dart';
import '../widgets/sync_banner.dart';
import 'add_product_screen.dart';

/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: DASHBOARD_DATA_LOADING - Data loading may fail or be incomplete
///       - Household profile loading not properly handled
///       - Inventory stats calculation may be inaccurate
///       - Alert integration not fully functional
/// TODO: DASHBOARD_ALERTS_DISPLAY - Alert display functionality incomplete
///       - AlertGenerationService integration not tested
///       - Alert filtering and sorting may not work
///       - Real-time alert updates not implemented
/// TODO: DASHBOARD_NAVIGATION - Navigation actions need validation
///       - Quick action buttons may not navigate correctly
///       - Tab navigation integration incomplete
/// TODO: DASHBOARD_ERROR_HANDLING - Error states not properly handled
///       - Database connection errors not gracefully handled
///       - Loading states may hang indefinitely
/// TODO: DASHBOARD_PERFORMANCE - Performance issues with large datasets
///       - Stats calculation may be slow with many items
///       - UI may freeze during data loading
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Foyer? _foyerProfile;
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;
  bool _isLoading = true;
  bool _offlineMode = false;
  DateTime? _lastSyncTime;

  // Real data for demonstration
  int _totalItems = 0;
  int _expiringSoon = 0;
  int _urgentAlerts = 0;

  List<Alert> _notifications = [];

  @override
  void initState() {
    super.initState();

    // Initialize services
    _databaseService = DatabaseService();
    _inventoryRepository = InventoryRepository(_databaseService);

    _loadDashboardData();

    // Track dashboard view for analytics testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<AnalyticsService>().logEvent(
            'screen_viewed',
            parameters: {
              'screen_name': 'dashboard',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          );
        } catch (e) {
          print('Analytics error: $e');
        }
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final foyer = await HouseholdService.getFoyer();
      if (foyer != null) {
        // Batch all database calls in parallel for better performance
        final foyerIdInt = int.parse(foyer.id!);
        
        // Get the AlertGenerationService from context instead of creating a new instance
        final alertService = context.read<AlertGenerationService>();
        
        final results = await Future.wait([
          _inventoryRepository.getTotalCount(foyerIdInt),
          _inventoryRepository.getExpiringSoonCount(foyerIdInt),
          alertService.generateAllAlerts(foyerIdInt),
        ]);

        setState(() {
          _foyerProfile = foyer;
          _totalItems = int.parse(results[0] as String);
          _expiringSoon = int.parse(results[1] as String);
          
          // Filter out read alerts
          final allAlerts = results[2] as List<Alert>;
          _notifications = alertService.filterAlerts(
            allAlerts, 
            includeRead: false,
            includeResolved: false,
          );
          
          _urgentAlerts = _notifications.length;
          _lastSyncTime =
              DateTime.now(); // Update sync time on successful data load
        });

        // Log succès du chargement du dashboard (debug uniquement)
        if (kDebugMode) {
          print(
            '[Dashboard] Successfully loaded: ${foyer.id} - $_totalItems items, $_expiringSoon expiring',
          );
        }
      }
    } catch (e, stackTrace) {
      // Log détaillé pour debugging
      await ErrorLoggerService.logError(
        component: 'DashboardScreen',
        operation: 'loadDashboardData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'foyerExists': _foyerProfile != null,
          'previousTotalItems': _totalItems,
        },
      );

      // Affichage convivial pour l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Messages d'erreur conviviaux pour l'utilisateur
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }
    if (errorStr.contains('database') || errorStr.contains('sqflite')) {
      return 'Erreur de base de données. Redémarrage de l\'application recommandé.';
    }
    if (errorStr.contains('null') || errorStr.contains('id is null')) {
      return 'Erreur de configuration. Essayez de redémarrer l\'application.';
    }

    return 'Erreur lors du chargement des données. Réessayez plus tard.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme
            .primaryGreen, // Match splash screen background during loading
        body: const Center(
          child: CupertinoActivityIndicator(radius: 20, color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Main navigation wrapper with dashboard content
        MainNavigationWrapper(
          currentIndex: 0, // Dashboard is index 0
          onTabChanged: (index) =>
              NavigationService.navigateToTab(context, index),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(child: _buildDashboardContent()),
              ],
            ),
          ),
        ),

        // Connectivity banner overlay at bottom
        Positioned(
          bottom: 80, // Above bottom navigation
          left: 16,
          right: 16,
          child: const ConnectivityBanner(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ! 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bienvenue dans votre espace personnel NgonNest',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                // TextButton(
                //   onPressed: () => throw Exception("error"),
                //   child: const Text("Throw Test Exception 2"),
                // ),
              ],
            ),
          ),
          Row(
            children: [
              // Dark mode toggle
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.read<ThemeModeNotifier>().toggleTheme();
                },
                child: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? CupertinoIcons.moon_fill
                      : CupertinoIcons.sun_max_fill,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              // Notification button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showNotificationsSheet();
                },
                child: Stack(
                  children: [
                    Icon(
                      CupertinoIcons.bell,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    if (_notifications.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Theme.of(context).colorScheme.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick stats (RepaintBoundary for performance)
                  RepaintBoundary(child: _buildQuickStats()),
                  const SizedBox(height: 16),

                  // Sync banner
                  if (_lastSyncTime != null)
                    Center(
                      child: SyncBanner(
                        lastSyncTime: _lastSyncTime,
                        onTap: _loadDashboardData,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Alerts section
                  if (_notifications.isNotEmpty) ...[
                    RepaintBoundary(child: _buildAlertsSection()),
                    const SizedBox(height: 24),
                  ],

                  // Premium Banner (Remote Config controlled)
                  const RepaintBoundary(child: PremiumBanner()),

                  // Quick actions
                  _buildQuickActionsSection(),
                  const SizedBox(height: 24),

                  // Household info
                  if (_foyerProfile != null) _buildHouseholdInfoSection(),
                  const SizedBox(height: 24),

                  // Recent items placeholder
                  _buildRecentItemsSection(),

                  // Add bottom padding to account for connectivity banner
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {
        'icon': CupertinoIcons.cube_box,
        'value': _totalItems.toString(),
        'label': 'Articles totaux',
        'color': Theme.of(context).colorScheme.primary,
        'onTap': () => NavigationService.navigateToTab(
          context,
          1,
        ), // Navigate to inventory
      },
      {
        'icon': CupertinoIcons.time,
        'value': _expiringSoon.toString(),
        'label': 'À surveiller',
        'color': Theme.of(context).colorScheme.secondary,
        'onTap': () =>
            _navigateToUrgentItems(), // Navigate to filtered urgent items
      },
      {
        'icon': CupertinoIcons.exclamationmark_triangle,
        'value': _urgentAlerts.toString(),
        'label': 'Urgences',
        'color': Theme.of(context).colorScheme.error,
        'onTap': () => _showNotificationsSheet(), // Show notifications
      },
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: stat['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        size: 24,
                        color: stat['color'] as Color,
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          stat['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          stat['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_notifications.length > 2)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showNotificationsSheet,
                  child: Text(
                    'Tout (${_notifications.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Show alerts or empty state
          if (_notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune alerte urgente pour le moment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._notifications.take(2).map((notification) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.priority,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getNotificationColor(
                      notification.priority,
                    ).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.priority),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _markNotificationAsRead(notification);
                        },
                        child: Icon(
                          CupertinoIcons.checkmark_circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'title': 'Inventaire',
        'subtitle': 'Voir mes produits',
        'icon': CupertinoIcons.cube_box,
        'color': Theme.of(context).colorScheme.primary,
        'onTap': () => NavigationService.navigateToTab(context, 1),
      },
      {
        'title': 'Ajouter',
        'subtitle': 'Nouveau produit',
        'icon': CupertinoIcons.add_circled,
        'color': Theme.of(context).colorScheme.secondary,
        'onTap': () => _navigateToAddProduct(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: action['onTap'] as VoidCallback,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (action['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            size: 20,
                            color: action['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            action['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            action['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHouseholdInfoSection() {
    // Use Consumer to listen to FoyerProvider changes
    return Consumer<FoyerProvider>(
      builder: (context, foyerProvider, child) {
        // Use provider data if available, fallback to local state
        final foyer = foyerProvider.foyer ?? _foyerProfile;
        
        if (foyer == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.house,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Informations du foyer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Personnes', '${foyer.nbPersonnes}'),
              _buildInfoRow('Pièces', '${foyer.nbPieces}'),
              if (foyer.budgetMensuelEstime != null)
                _buildInfoRow(
                  'Budget mensuel',
                  '${foyer.budgetMensuelEstime!.toStringAsFixed(1)} €',
                ),
              _buildInfoRow(
                'Type de logement',
                LogementType.getDisplayName(foyer.typeLogement),
              ),
              _buildInfoRow(
                'Langue',
                Language.getDisplayName(foyer.langue),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Articles récents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.cube_box,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Aucun article ajouté pour le moment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.cube_box,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Fonctionnalité en cours de développement',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddProductScreen()));

    // If product was added successfully, refresh the inventory data
    if (result == true) {
      _loadDashboardData(); // Refresh dashboard data
    }
  }

  void _navigateToUrgentItems() {
    // Navigate to inventory screen with urgent items filter
    // For now, navigate to inventory tab - filtering will be implemented in task 2
    NavigationService.navigateToTab(context, 1);

    // Show a snackbar to indicate we're showing urgent items
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Affichage des articles urgents'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationsSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 400,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getNotificationColor(
                            notification.priority,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.priority),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _markNotificationAsRead(notification);
                              },
                              child: Icon(
                                CupertinoIcons.checkmark_circle,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markNotificationAsRead(Alert notification) async {
    try {
      // Use the context-provided AlertGenerationService instance
      final alertService = context.read<AlertGenerationService>();
      await alertService.markAlertAsRead(notification.id);
      
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        _urgentAlerts = _notifications.length;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> _refreshNotifications() async {
    try {
      final foyer = await HouseholdService.getFoyer();
      if (foyer != null && foyer.id != null) {
        final foyerIdInt = int.parse(foyer.id!);
        
        // Use the context-provided AlertGenerationService instance
        final alertService = context.read<AlertGenerationService>();
        final alerts = await alertService.generateAllAlerts(foyerIdInt);
        
        setState(() {
          _notifications = alertService.filterAlerts(
            alerts,
            includeRead: false,
            includeResolved: false,
          );
          _urgentAlerts = _notifications.length;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing notifications: $e');
      }
    }
  }

  Color _getNotificationColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
      case AlertPriority.high:
        return AppTheme.primaryRed;
      case AlertPriority.medium:
        return AppTheme.primaryOrange;
      case AlertPriority.low:
        return AppTheme.primaryGreen;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }

  IconData _getNotificationIcon(AlertType type) {
    switch (type) {
      case AlertType.stockCritical:
      case AlertType.stockLow:
        return CupertinoIcons.exclamationmark_triangle;
      case AlertType.expired:
      case AlertType.expiringSoon:
        return CupertinoIcons.time;
      case AlertType.reminder:
      case AlertType.maintenanceDue:
        return CupertinoIcons.bell;
      case AlertType.budgetHigh:
      case AlertType.budgetUncertain:
        return CupertinoIcons.money_dollar_circle;
      case AlertType.recommendation:
        return CupertinoIcons.lightbulb;
      case AlertType.system:
        return CupertinoIcons.info_circle;
      default:
        return CupertinoIcons.info_circle;
    }
  }
}
