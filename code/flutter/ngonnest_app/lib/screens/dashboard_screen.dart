import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/household_profile.dart';
import '../services/household_service.dart';
import '../theme/app_theme.dart';
import 'add_product_screen.dart';
import '../theme/theme_mode_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  HouseholdProfile? _profile;
  bool _isLoading = true;
  bool _offlineMode = false;
  int _selectedTabIndex = 0;

  // Mock data for demonstration
  final int _totalItems = 5;
  final int _expiringSoon = 2;
  final int _urgentAlerts = 1;

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 1,
      'type': 'low-stock',
      'title': 'Stock faible',
      'message': 'Papier toilette presque épuisé',
      'urgency': 'high',
      'read': false,
    },
    {
      'id': 2,
      'type': 'expiry',
      'title': 'Expiration proche',
      'message': 'Huile de palme expire dans 2 semaines',
      'urgency': 'medium',
      'read': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await HouseholdService.getHouseholdProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: CupertinoActivityIndicator(radius: 20)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildDashboardContent()
                  : _buildPlaceholderContent(),
            ),

            // Bottom navigation
            _buildBottomNavigation(),

            // Status bar
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenue dans votre espace personnel NgonNest',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
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
                  size: 24,
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
                      size: 24,
                    ),
                    if (_mockNotifications.where((n) => !n['read']).isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(6),
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
      onRefresh: _loadProfile,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Alerts section
            _buildAlertsSection(),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActionsSection(),
            const SizedBox(height: 24),

            // Household info
            if (_profile != null) _buildHouseholdInfoSection(),
            const SizedBox(height: 24),

            // Recent items placeholder
            _buildRecentItemsSection(),
          ],
        ),
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
      },
      {
        'icon': CupertinoIcons.time,
        'value': _expiringSoon.toString(),
        'label': 'À surveiller',
        'color': Theme.of(context).colorScheme.secondary,
      },
      {
        'icon': CupertinoIcons.exclamationmark_triangle,
        'value': _urgentAlerts.toString(),
        'label': 'Urgences',
        'color': Theme.of(context).colorScheme.error,
      },
    ];

    return Row(
      children: stats.map((stat) {
        final isLast = stat == stats.last;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 28,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
              if (_mockNotifications.length > 2)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showNotificationsSheet,
                  child: Text(
                    'Tout (${_mockNotifications.length})',
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
          if (_mockNotifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  Text(
                    'Aucune alerte urgente pour le moment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._mockNotifications.take(2).map((notification) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification['urgency'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getNotificationColor(
                      notification['urgency'],
                    ).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getNotificationIcon(notification['type']),
                      color: _getNotificationColor(notification['urgency']),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification['read'])
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            notification['read'] = true;
                          });
                        },
                        child: Icon(
                          CupertinoIcons.checkmark_circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
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
        'onTap': () => _navigateToTab(1),
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: actions.map((action) {
            final isLast = action == actions.last;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 12),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: action['onTap'] as VoidCallback,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: (action['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            size: 24,
                            color: action['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          action['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
          _buildInfoRow('Personnes', '${_profile!.nbPersonnes}'),
          _buildInfoRow('Pièces', '${_profile!.nbPieces}'),
          _buildInfoRow(
            'Type de logement',
            LogementType.getDisplayName(_profile!.typeLogement),
          ),
          _buildInfoRow('Langue', Language.getDisplayName(_profile!.langue)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                  ).colorScheme.onBackground.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Aucun article ajouté pour le moment',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
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
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Fonctionnalité en cours de développement',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final tabs = [
      {'icon': CupertinoIcons.house, 'label': 'Accueil'},
      {'icon': CupertinoIcons.cube_box, 'label': 'Inventaire'},
      {'icon': CupertinoIcons.add, 'label': 'Ajouter'},
      {'icon': CupertinoIcons.bell, 'label': 'Alertes'},
      {'icon': CupertinoIcons.gear, 'label': 'Paramètres'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = _selectedTabIndex == index;

            return Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => _navigateToTab(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 24,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: _offlineMode
          ? Theme.of(context).colorScheme.tertiary.withOpacity(0.2)
          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _offlineMode ? CupertinoIcons.wifi_slash : CupertinoIcons.wifi,
            size: 16,
            color: _offlineMode
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _offlineMode
                ? 'Hors ligne - Données sauvegardées localement'
                : 'Connecté - Synchronisation des données',
            style: TextStyle(
              fontSize: 12,
              color: _offlineMode
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // TODO: Implement actual navigation
    if (index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Navigation vers ${_getTabName(index)} en cours de développement',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddProductScreen()));

    // If product was added successfully, refresh the inventory data
    if (result == true) {
      _loadProfile(); // Refresh dashboard data
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 1:
        return 'Inventaire';
      case 2:
        return 'Ajouter produit';
      case 3:
        return 'Alertes';
      case 4:
        return 'Paramètres';
      default:
        return 'Accueil';
    }
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
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
                  itemCount: _mockNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _mockNotifications[index];
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
                            notification['urgency'],
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getNotificationIcon(notification['type']),
                            color: _getNotificationColor(
                              notification['urgency'],
                            ),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'],
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
                                  notification['message'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
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

  Color _getNotificationColor(String urgency) {
    switch (urgency) {
      case 'high':
        return AppTheme.primaryRed;
      case 'medium':
        return AppTheme.primaryOrange;
      case 'low':
        return AppTheme.primaryGreen;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'low-stock':
        return CupertinoIcons.exclamationmark_triangle;
      case 'expiry':
        return CupertinoIcons.time;
      case 'reminder':
        return CupertinoIcons.bell;
      default:
        return CupertinoIcons.info_circle;
    }
  }
}
