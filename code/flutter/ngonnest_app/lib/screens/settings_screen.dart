import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/cloud_import_service.dart';
import '../services/export_import_service.dart';
import '../services/navigation_service.dart';
import '../services/notification_permission_service.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../services/user_feedback_service.dart';
import '../theme/theme_mode_notifier.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../widgets/settings_import_dialog.dart';
import '../widgets/sync_status_dialog.dart';
import '../widgets/sync_status_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for settings not managed by Provider
  bool _notificationsEnabled = true;
  bool _calendarSyncEnabled = true;
  bool _localDataOnly = true;
  bool _hasAcceptedCloudSync = false;
  String _notificationFrequency = 'quotidienne';
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isImporting = false;
  double _exportProgress = 0.0;
  double _importProgress = 0.0;

  static const String _feedbackEndpoint = 'https://httpbin.org/post';
  static const String _bugReportEndpoint = 'https://httpbin.org/post';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load all saved settings when screen opens
  Future<void> _loadSettings() async {
    try {
      final notificationsEnabled =
          await SettingsService.getNotificationsEnabled();
      final calendarSyncEnabled =
          await SettingsService.getCalendarSyncEnabled();

      final localDataOnly = await SettingsService.getLocalDataOnly();
      final hasAcceptedCloudSync = await SettingsService.getCloudSyncAccepted();
      final notificationFrequency =
          await SettingsService.getNotificationFrequency();

      const allowedFrequencies = {'quotidienne', 'hebdomadaire'};

      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _localDataOnly = localDataOnly;
        _calendarSyncEnabled = calendarSyncEnabled;
        _hasAcceptedCloudSync = hasAcceptedCloudSync;
        _notificationFrequency =
            allowedFrequencies.contains(notificationFrequency)
            ? notificationFrequency
            : 'quotidienne';
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  List<Map<String, String>> get _notificationFrequencies => [
    {
      'code': 'quotidienne',
      'name': AppLocalizations.of(context)?.daily ?? 'Quotidienne',
    },
    {
      'code': 'hebdomadaire',
      'name': AppLocalizations.of(context)?.weekly ?? 'Hebdomadaire',
    },
  ];

  /// Handle notification toggle with permission handling
  Future<void> _handleNotificationToggle(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        // Enabling notifications - request permission
        final result =
            await NotificationPermissionService.enableNotifications();

        switch (result) {
          case NotificationPermissionResult.granted:
            setState(() => _notificationsEnabled = true);

            await SettingsService.setNotificationsEnabled(true);
            _showSuccessMessage(
              AppLocalizations.of(context)?.settingsSaved ??
                  'Paramètres sauvegardés',
            );
            break;
          case NotificationPermissionResult.denied:
            NotificationPermissionService.showPermissionDeniedDialog(
              context,
              () => NotificationPermissionService.openSystemSettings(),
            );
            break;
          case NotificationPermissionResult.error:
            _showErrorMessage(
              AppLocalizations.of(context)?.errorActivatingNotifications ??
                  'Erreur lors de l\'activation des notifications',
            );
            break;
        }
      } else {
        // Disabling notifications
        await NotificationPermissionService.disableNotifications();
        setState(() => _notificationsEnabled = false);

        await SettingsService.setNotificationsEnabled(false);
        _showSuccessMessage(
          AppLocalizations.of(context)?.settingsSaved ??
              'Paramètres sauvegardés',
        );
      }
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCalendarSyncToggle(bool value) async {
    setState(() => _calendarSyncEnabled = value);
    try {
      await SettingsService.setCalendarSyncEnabled(value);
      _showSuccessMessage(
        AppLocalizations.of(context)?.settingsSaved ?? 'Paramètres sauvegardés',
      );
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    }
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show language changed message
  void _showLanguageChangedMessage() {
    _showSuccessMessage(
      AppLocalizations.of(context)?.languageChangedSuccessfully ??
          'Langue modifiée avec succès',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le Consumer entoure maintenant MainNavigationWrapper
    // Le contenu de l'écran (anciennement dans le body du Scaffold interne)
    // est passé en tant que 'body' à MainNavigationWrapper
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeModeNotifier, child) {
        // MainNavigationWrapper est le widget principal
        // Il gère probablement la barre de navigation en bas et un Scaffold
        return MainNavigationWrapper(
          currentIndex: 4, // Settings is index 4
          onTabChanged: (index) =>
              NavigationService.navigateToTab(context, index),
          // Le contenu spécifique de l'écran Paramètres est passé ici
          body: Builder(
            builder: (BuildContext context) {
              // Utiliser Builder pour accéder au contexte correct
              // si MainNavigationWrapper crée un nouveau Scaffold
              return Scaffold(
                // AppBar est défini ici, à l'intérieur du Scaffold
                // fourni par MainNavigationWrapper (espérons-le)
                appBar: AppBar(
                  title: Text(
                    AppLocalizations.of(context)?.settings ?? 'Paramètres',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  // Ne pas mettre automaticallyImplyLeading ici si MainNavigationWrapper gère la navigation
                  // Sinon, si c'est un écran de premier niveau, c'est ok.
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.settings,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.language ?? 'Langue',
                        ),
                        Consumer<LocaleProvider>(
                          builder: (context, localeProvider, child) {
                            return _buildSettingCard(
                              title:
                                  AppLocalizations.of(context)?.languageOfApp ??
                                  'Langue de l\'application',
                              subtitle:
                                  AppLocalizations.of(
                                    context,
                                  )?.choosePreferredLanguage ??
                                  'Choisissez votre langue préférée',
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: DropdownButton<Locale>(
                                      value: localeProvider.locale,
                                      underline: const SizedBox(),
                                      items: LocaleProvider.supportedLocales
                                          .map(
                                            (locale) => DropdownMenuItem(
                                              value: locale,
                                              child: Text(
                                                localeProvider
                                                    .getLocaleDisplayName(
                                                      locale,
                                                    ),
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (locale) async {
                                        if (locale != null) {
                                          await localeProvider.setLocale(
                                            locale,
                                          );
                                          if (mounted) {
                                            _showLanguageChangedMessage();
                                          }
                                        }
                                      },
                                      isExpanded: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      CupertinoIcons.globe,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 24,
                                    ),
                                    tooltip:
                                        AppLocalizations.of(
                                          context,
                                        )?.selectToChangeInterface ??
                                        'Sélectionnez pour changer l\'interface',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Notifications Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.notifications ??
                              'Notifications',
                        ),
                        _buildSettingCard(
                          title: _notificationsEnabled
                              ? (AppLocalizations.of(
                                      context,
                                    )?.notificationsEnabled ??
                                    'Notifications activées')
                              : (AppLocalizations.of(
                                      context,
                                    )?.notificationsDisabled ??
                                    'Notifications désactivées'),
                          subtitle:
                              AppLocalizations.of(context)?.receiveAppAlerts ??
                              'Recevoir des alertes sur l\'app',
                          child: Row(
                            children: [
                              CupertinoSwitch(
                                value: _notificationsEnabled,
                                onChanged: _isLoading
                                    ? null
                                    : (value) async {
                                        await _handleNotificationToggle(value);
                                      },
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  CupertinoIcons.bell,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                tooltip:
                                    AppLocalizations.of(
                                      context,
                                    )?.enableRemindersForLowStock ??
                                    'Activer rappels pour stocks bas',
                              ),
                            ],
                          ),
                        ),
                        if (_notificationsEnabled) ...[
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.only(left: 16),
                            child: _buildSettingCard(
                              title:
                                  AppLocalizations.of(
                                    context,
                                  )?.notificationFrequency ??
                                  'Fréquence des notifications',
                              subtitle:
                                  AppLocalizations.of(
                                    context,
                                  )?.chooseReminderFrequency ??
                                  'Choisissez la fréquence des rappels',
                              child: SizedBox(
                                width: 120,
                                child: DropdownButton<String>(
                                  value: _notificationFrequency,
                                  underline: const SizedBox(),
                                  items: _notificationFrequencies
                                      .map(
                                        (freq) => DropdownMenuItem(
                                          value: freq['code'],
                                          child: Text(
                                            freq['name']!,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) async {
                                    if (value != null) {
                                      setState(
                                        () => _notificationFrequency = value,
                                      );
                                      await SettingsService.setNotificationFrequency(
                                        value,
                                      );
                                    }
                                  },
                                  isExpanded: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildSectionTitle('Calendrier'),
                        _buildSettingCard(
                          title: _calendarSyncEnabled
                              ? 'Synchronisation calendrier activée'
                              : 'Synchronisation calendrier désactivée',
                          subtitle:
                              'Ajouter les rappels programmés au calendrier',
                          child: CupertinoSwitch(
                            value: _calendarSyncEnabled,
                            onChanged: (value) async {
                              await _handleCalendarSyncToggle(value);
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Synchronization Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.synchronization ??
                              'Synchronisation',
                        ),
                        _buildSyncStatusSection(),
                        const SizedBox(height: 24),
                        // Privacy Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.privacy ??
                              'Confidentialité',
                        ),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.localDataOnly ??
                              'Données locales uniquement',
                          subtitle:
                              AppLocalizations.of(
                                context,
                              )?.noSyncWithoutExplicitConsent ??
                              'Pas de sync sans accord explicite',
                          child: Row(
                            children: [
                              CupertinoSwitch(
                                value: _localDataOnly,
                                onChanged: (value) async {
                                  if (!value) {
                                    _showCloudSyncConsent();
                                  } else {
                                    setState(() {
                                      _localDataOnly = true;
                                      _hasAcceptedCloudSync = false;
                                    });
                                    await SettingsService.setLocalDataOnly(
                                      true,
                                    );
                                    await SettingsService.setCloudSyncAccepted(
                                      false,
                                    );
                                  }
                                },
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Theme Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.theme ?? 'Thème',
                        ),
                        _buildSettingCard(
                          title:
                              'Mode ${themeModeNotifier.themeMode == ThemeMode.light
                                  ? 'clair'
                                  : themeModeNotifier.themeMode == ThemeMode.dark
                                  ? 'sombre'
                                  : 'système'}',
                          subtitle:
                              AppLocalizations.of(
                                context,
                              )?.changeAppAppearance ??
                              'Changer l\'apparence de l\'application',
                          child: CupertinoSwitch(
                            value:
                                themeModeNotifier.themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              themeModeNotifier.toggleTheme();
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Support Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.support ?? 'Support',
                        ),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.sendFeedback ??
                              'Envoyer un feedback',
                          subtitle:
                              AppLocalizations.of(
                                context,
                              )?.shareYourSuggestions ??
                              'Partagez vos suggestions',
                          child: ElevatedButton.icon(
                            onPressed: _showFeedbackDialog,
                            icon: const Icon(CupertinoIcons.mail, size: 18),
                            label: Text(
                              AppLocalizations.of(context)?.send ?? 'Envoyer',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.reportBug ??
                              'Signaler un bug',
                          subtitle:
                              AppLocalizations.of(context)?.describeProblem ??
                              'Décrivez le problème',
                          child: ElevatedButton.icon(
                            onPressed: _showBugReportDialog,
                            icon: const Icon(Icons.bug_report, size: 18),
                            label: Text(
                              AppLocalizations.of(context)?.report ??
                                  'Signaler',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Data Management Section
                        _buildSectionTitle(
                          AppLocalizations.of(context)?.data ?? 'Données',
                        ),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.exportData ??
                              'Exporter les données',
                          subtitle:
                              AppLocalizations.of(context)?.backupDataLocally ??
                              'Sauvegarder vos données localement',
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportData,
                            icon: _isExporting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download, size: 16),
                            label: Text(
                              _isExporting
                                  ? 'Exportation...'
                                  : (AppLocalizations.of(context)?.export ??
                                        'Exporter'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExporting
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.6)
                                  : Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.importData ??
                              'Importer des données',
                          subtitle:
                              AppLocalizations.of(
                                context,
                              )?.restoreFromBackupFile ??
                              'Restaurer depuis un fichier sauvegardé',
                          child: ElevatedButton.icon(
                            onPressed: _isImporting ? null : _importData,
                            icon: _isImporting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.upload, size: 16),
                            label: Text(
                              _isImporting
                                  ? 'Importation...'
                                  : (AppLocalizations.of(context)?.import ??
                                        'Importer'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isImporting
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.6)
                                  : Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSettingCard(
                          title:
                              AppLocalizations.of(context)?.deleteAllData ??
                              'Supprimer toutes les données',
                          subtitle:
                              AppLocalizations.of(
                                context,
                              )?.completeResetIrreversible ??
                              'Reset complet - Action irréversible',
                          child: ElevatedButton.icon(
                            onPressed: _showDeleteAllDataConfirmation,
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              AppLocalizations.of(context)?.delete ??
                                  'Supprimer',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Save Button in content
                        ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.save ?? 'Sauvegarder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          const SizedBox(width: 16),
          child,
        ],
      ),
    );
  }

  /// Build the sync status section
  Widget _buildSyncStatusSection() {
    return Consumer2<SyncService, AuthService>(
      builder: (context, syncService, authService, child) {
        return Column(
          children: [
            // Sync status indicator
            SyncStatusIndicator(
              onTap: () => SyncStatusDialog.show(context),
            ),
            const SizedBox(height: 16),
            // Sync toggle
            _buildSettingCard(
              title: syncService.syncEnabled
                  ? (AppLocalizations.of(context)?.enableCloudSync ?? 'Cloud sync enabled')
                  : (AppLocalizations.of(context)?.disableCloudSync ?? 'Cloud sync disabled'),
              subtitle: authService.isAuthenticated
                  ? (syncService.syncEnabled 
                      ? 'Vos données sont sauvegardées dans le cloud'
                      : 'Activez pour sauvegarder vos données')
                  : (AppLocalizations.of(context)?.connectToEnableSync ?? 'Connect to enable sync'),
              child: CupertinoSwitch(
                value: syncService.syncEnabled && authService.isAuthenticated,
                onChanged: (value) => _handleSyncToggle(value, syncService, authService),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle sync toggle with authentication check
  Future<void> _handleSyncToggle(
    bool value,
    SyncService syncService,
    AuthService authService,
  ) async {
    if (value) {
      // Enabling sync
      if (!authService.isAuthenticated) {
        // Navigate to authentication screen with context
        await _navigateToAuthentication();
      } else {
        // User is authenticated, check for cloud data and enable sync
        await _handleAuthenticatedSyncEnable(syncService);
      }
    } else {
      // Disabling sync
      await syncService.disableSync();
      _showSuccessMessage(
        AppLocalizations.of(context)?.settingsSaved ?? 'Settings saved',
      );
    }
  }

  /// Handle sync enable when user is already authenticated
  Future<void> _handleAuthenticatedSyncEnable(SyncService syncService) async {
    try {
      // Check for cloud data and show import options if needed
      await _checkCloudDataAndShowOptions(syncService);
    } catch (e) {
      // If cloud check fails, still enable sync
      await syncService.enableSync(userConsent: true);
      _showSuccessMessage(
        AppLocalizations.of(context)?.syncSuccessMessage ?? 
        'Synchronization enabled successfully',
      );
    }
  }

  /// Navigate to authentication screen
  Future<void> _navigateToAuthentication() async {
    final result = await Navigator.of(context).pushNamed(
      '/authentication',
      arguments: {
        'contextMessage': AppLocalizations.of(context)?.connectToEnableSync ?? 
            'Connectez-vous pour activer la synchronisation',
        'source': 'settings',
      },
    );

    // Check if authentication was successful
    if (result == true) {
      // Authentication successful, handle the flow
      await _handleSuccessfulAuthentication();
    }
  }

  /// Handle successful authentication from settings
  Future<void> _handleSuccessfulAuthentication() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);
    
    if (authService.isAuthenticated) {
      // Check for cloud data and show import options
      await _checkCloudDataAndShowOptions(syncService);
    }
  }

  /// Check for cloud data and show import options
  Future<void> _checkCloudDataAndShowOptions(SyncService syncService) async {
    try {
      final cloudImportService = CloudImportService();
      final hasCloudData = await cloudImportService.checkCloudData();

      if (hasCloudData) {
        // Show import options dialog with enhanced options
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SettingsImportDialog(
            cloudImportService: cloudImportService,
            onComplete: () {
              // Dialog completion callback
            },
          ),
        );

        if (result != null) {
          // User made a choice, enable sync
          await syncService.enableSync(userConsent: true);
          
          // Handle each option appropriately
          await _handleImportOption(result, syncService);
          
          // Show appropriate success message based on choice
          _showImportSuccessMessage(result);
        }
      } else {
        // No cloud data, enable sync and trigger initial sync to upload local data
        await syncService.enableSync(userConsent: true);
        
        // Trigger initial sync to upload local data
        await syncService.forceSyncWithFeedback(context);
        
        _showSuccessMessage(
          'Synchronisation activée. Vos données locales seront sauvegardées dans le cloud.',
        );
      }
    } catch (e) {
      // Handle error gracefully
      await syncService.enableSync(userConsent: true);
      
      // Still try to trigger initial sync
      await syncService.forceSyncWithFeedback(context);
      
      _showSuccessMessage(
        AppLocalizations.of(context)?.syncSuccessMessage ?? 
        'Synchronization enabled successfully',
      );
    }
  }

  /// Handle the selected import option
  Future<void> _handleImportOption(String option, SyncService syncService) async {
    switch (option) {
      case 'keep_local':
        // For "Conserver local", upload local data to cloud
        // The sync service will handle uploading local data
        await syncService.forceSyncWithFeedback(context);
        break;
        
      case 'import_cloud':
        // For "Importer", cloud data has already been imported by the dialog
        // Just trigger a sync to ensure everything is up to date
        await syncService.forceSyncWithFeedback(context);
        break;
        
      case 'merge':
        // For "Fusionner", data has been merged by the dialog
        // Trigger sync to upload any local changes and resolve conflicts
        await syncService.forceSyncWithFeedback(context);
        break;
    }
  }

  /// Show success message based on import option
  void _showImportSuccessMessage(String option) {
    String message;
    switch (option) {
      case 'keep_local':
        message = 'Synchronisation activée. Vos données locales seront sauvegardées dans le cloud.';
        break;
      case 'import_cloud':
        message = 'Données importées du cloud et synchronisation activée.';
        break;
      case 'merge':
        message = 'Données fusionnées et synchronisation activée.';
        break;
      default:
        message = AppLocalizations.of(context)?.syncSuccessMessage ?? 
            'Synchronization enabled successfully';
    }
    
    _showSuccessMessage(message);
  }

  void _showCloudSyncConsent() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.cloudSynchronization ??
              'Synchronisation Cloud',
        ),
        content: Column(
          children: [
            Text(
              AppLocalizations.of(context)?.cloudSyncAllowsOnlineBackup ??
                  'La synchronisation cloud permet de sauvegarder vos données en ligne. Acceptez-vous cette fonctionnalité ?',
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                title: Text(
                  AppLocalizations.of(context)?.acceptCloudSync ??
                      'J\'accepte la synchronisation cloud',
                ),
                value: _hasAcceptedCloudSync,
                onChanged: (value) =>
                    setState(() => _hasAcceptedCloudSync = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.accept ?? 'Accepter'),
            onPressed: () async {
              if (_hasAcceptedCloudSync) {
                // TODO-SC2: Implement cloud synchronization
                // Details: Add proper cloud sync service integration with user consent handling
                //                 await SettingsService.setLocalDataOnly(false);
                setState(() => _localDataOnly = false);
                await SettingsService.setLocalDataOnly(false);
                await SettingsService.setCloudSyncAccepted(true);
                Navigator.of(context).pop();
                if (mounted) {
                  await _syncWithCloud();
                  _showSyncEnabledMessage();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSyncEnabledMessage() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.syncEnabled ??
              'Synchronisation activée',
        ),
        content: Text(
          AppLocalizations.of(context)?.cloudSyncActivated ??
              'La synchronisation cloud a été activée. Vos données seront automatiquement sauvegardées.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _syncWithCloud() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      await SettingsService.setLastSyncTime(DateTime.now());
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur de synchronisation: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitFeedback(String message) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Feedback submitted (length=${message.length})');
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur feedback: $e');
      }
    }
  }

  Future<void> _submitBugReport(String description) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Bug report submitted (length=${description.length})');
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur bug report: $e');
      }
    }
  }

  void _showFeedbackDialog() {
    String feedbackMessage = '';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.sendFeedbackTitle ??
              'Envoyer un feedback',
        ),
        content: Column(
          children: [
            Text(
              AppLocalizations.of(context)?.feedbackMessage ??
                  'Nous aimerions connaître votre avis sur l\'application.',
            ),
            const SizedBox(height: 12),
            Material(
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  maxLines: 4,
                  onChanged: (value) => feedbackMessage = value,
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)?.typeMessageHere ??
                        'Tapez votre message ici...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.send ?? 'Envoyer'),
            onPressed: () async {
              if (feedbackMessage.trim().isNotEmpty) {
                Navigator.of(context).pop();

                // Afficher un indicateur de chargement avec gestion d'état améliorée
                if (mounted) {
                  _showLoadingDialogWithState('Envoi du feedback...');
                }

                try {
                  // Envoyer le feedback avec timeout
                  final result =
                      await UserFeedbackService.sendFeedback(
                        message: feedbackMessage,
                        appVersion:
                            '1.0.0', // TODO: Récupérer depuis package_info
                      ).timeout(
                        const Duration(seconds: 15),
                        onTimeout: () => FeedbackResult(
                          success: false,
                          errorMessage:
                              'Délai d\'attente dépassé. Vérifiez votre connexion.',
                        ),
                      );

                  // Fermer le loading dialog
                  if (mounted) {
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (e) {
                      // Dialog déjà fermé ou widget démonté
                    }
                  }

                  if (result.success) {
                    if (mounted) {
                      _showFeedbackSentMessage();
                    }
                  } else {
                    if (mounted) {
                      _showFeedbackErrorMessage(
                        result.errorMessage ?? 'Erreur inconnue',
                      );
                    }
                  }
                } catch (e) {
                  // Fermer le loading dialog en cas d'erreur
                  if (mounted) {
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (_) {
                      // Dialog déjà fermé ou widget démonté
                    }
                  }
                  if (mounted) {
                    _showFeedbackErrorMessage('Erreur inattendue: $e');
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    String bugDescription = '';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.reportBugTitle ?? 'Signaler un bug',
        ),
        content: Column(
          children: [
            Text(
              AppLocalizations.of(context)?.bugReportWillBeSent ??
                  'Votre signalement sera envoyé à notre équipe de développement.',
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.continueContactTelegram ??
                  'Pour continuer à nous contacter, rejoignez notre bot Telegram :',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                const url = 'https://t.me/NgonNestBot';
                await Clipboard.setData(const ClipboardData(text: url));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.telegramLinkCopied ??
                            'Lien Telegram copié !',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  't.me/NgonNestBot',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  maxLines: 4,
                  onChanged: (value) => bugDescription = value,
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)?.typeMessageHere ??
                        'Décrivez le bug en détail...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.report ?? 'Signaler'),
            onPressed: () async {
              if (bugDescription.trim().isNotEmpty) {
                Navigator.of(context).pop();

                // Afficher un indicateur de chargement avec gestion d'état améliorée
                if (mounted) {
                  _showLoadingDialogWithState('Envoi du rapport...');
                }

                try {
                  // Envoyer le rapport de bug avec timeout
                  final result =
                      await UserFeedbackService.sendBugReport(
                        description: bugDescription,
                        appVersion:
                            '1.0.0', // TODO: Récupérer depuis package_info
                      ).timeout(
                        const Duration(seconds: 15),
                        onTimeout: () => FeedbackResult(
                          success: false,
                          errorMessage:
                              'Délai d\'attente dépassé. Vérifiez votre connexion.',
                        ),
                      );

                  // Fermer le loading dialog
                  if (mounted) {
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (e) {
                      // Dialog déjà fermé ou widget démonté
                    }
                  }

                  if (result.success) {
                    _showBugReportedMessage();
                  } else {
                    _showBugReportErrorMessage(
                      result.errorMessage ?? 'Erreur inconnue',
                    );
                  }
                } catch (e) {
                  // Fermer le loading dialog en cas d'erreur
                  if (mounted) {
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (_) {
                      // Dialog déjà fermé ou widget démonté
                    }
                  }
                  _showBugReportErrorMessage('Erreur inattendue: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackSentMessage() {
    if (!mounted) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.feedbackSent ?? 'Feedback envoyé',
        ),
        content: Text(
          AppLocalizations.of(context)?.feedbackSentSuccessfully ??
              'Merci pour votre retour ! Nous l\'utiliserons pour améliorer l\'application.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showBugReportedMessage() {
    if (!mounted) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.bugReportSent ?? 'Bug signalé',
        ),
        content: Text(
          AppLocalizations.of(context)?.bugReportSentSuccessfully ??
              'Merci d\'avoir signalé ce problème. Nous allons l\'examiner rapidement.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(
    String title,
    String message, {
    bool isPermanent = false,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (isPermanent)
            CupertinoDialogAction(
              child: Text(
                AppLocalizations.of(context)?.grantStoragePermission ??
                    'Accorder l\'autorisation',
              ),

              onPressed: () async {
                Navigator.of(context).pop();
                if (mounted) {
                  await ph.openAppSettings();
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    if (!mounted) return;

    try {
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppLocalizations.of(context)?.exportData ?? 'Exporter les données',
          ),
          content: Text(
            AppLocalizations.of(context)?.exportDataConfirm ??
                'Exporter toutes vos données vers un fichier JSON ?',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      // Start loading
      setState(() => _isExporting = true);

      // Request storage permission before proceeding
      ph.PermissionStatus permissionStatus;

      // Try MANAGE_EXTERNAL_STORAGE first (Android 11+)
      try {
        permissionStatus = await ph.Permission.manageExternalStorage.request();
      } catch (e) {
        // Fall back to media permissions for Android 13+
        try {
          // Request permissions one by one for Android 13+
          final photoStatus = await ph.Permission.photos.request();
          final videoStatus = await ph.Permission.videos.request();
          final audioStatus = await ph.Permission.audio.request();

          // Check if at least one permission is granted
          permissionStatus =
              (photoStatus.isGranted ||
                  videoStatus.isGranted ||
                  audioStatus.isGranted)
              ? ph.PermissionStatus.granted
              : (photoStatus.isPermanentlyDenied ||
                    videoStatus.isPermanentlyDenied ||
                    audioStatus.isPermanentlyDenied)
              ? ph.PermissionStatus.permanentlyDenied
              : ph.PermissionStatus.denied;
        } catch (e2) {
          // Last resort: try legacy storage permission
          permissionStatus = await ph.Permission.storage.request();
        }
      }

      if (permissionStatus.isDenied) {
        if (!mounted) return;
        _showPermissionDialog(
          'Storage permission required',
          'Storage permission denied. Please grant access in system settings',
        );
        return;
      } else if (permissionStatus.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionDialog(
          'Storage permission required',
          'Storage permission permanently denied. Please enable it in app settings',
          isPermanent: true,
        );
        return;
      }

      String? directory;
      try {
        directory = await FilePicker.platform.getDirectoryPath();
        directory ??= (await getApplicationDocumentsDirectory()).path;
      } catch (e) {
        if (!mounted) return;
        throw Exception('Unable to access storage directory: $e');
      }

      final service = ExportImportService();
      final jsonString = await service.exportToJson();
      final fileName =
          'ngonnest_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(p.join(directory, fileName));
      await file.writeAsString(jsonString, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.exportSuccess ??
                'Export effectué vers ${file.path}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      print('Export Error: $e');
      print('StackTrace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    if (!mounted) return;

    try {
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppLocalizations.of(context)?.importData ?? 'Importer des données',
          ),
          content: Text(
            AppLocalizations.of(context)?.importDataConfirm ??
                'Cette opération remplacera vos données actuelles. Continuer ?',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      // Start loading
      setState(() => _isImporting = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final service = ExportImportService();
      await service.importFromJson(jsonString);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.importSuccess ?? 'Import réussi',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      print('Import Error: $e');
      print('StackTrace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'import : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showDeleteAllDataConfirmation() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)?.deleteAllDataConfirmation ??
              '⚠️ ATTENTION ⚠️',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Cette action est IRRÉVERSIBLE !',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.deleteAllDataWarning ??
                  'Toutes vos données seront supprimées :\n• Profil du foyer\n• Inventaire complet\n• Historique d\'achats\n• Préférences et paramètres\nL\'application retournera à son état initial.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Annuler',
              style: const TextStyle(color: Colors.blue),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(
              AppLocalizations.of(context)?.deleteAllData ?? 'SUPPRIMER TOUT',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showFinalDeletionConfirmation();
            },
          ),
        ],
      ),
    );
  }

  // Second confirmation step for extra safety
  void _showFinalDeletionConfirmation() {
    String confirmationText = '';
    bool isTextValid = false;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('CONFIRMER LA SUPPRESSION'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Tapez "SUPPRIMER" pour confirmer :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isTextValid
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error ??
                                Colors.red, // Fallback si error n'existe pas
                    ),
                  ),
                  child: TextField(
                    maxLength: 9, // "SUPPRIMER".length
                    onChanged: (value) {
                      confirmationText = value;
                      setState(() {
                        isTextValid = confirmationText == 'SUPPRIMER';
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'SUPPRIMER',
                      hintStyle: TextStyle(
                        // color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: Text(
                'SUPPRIMER DÉFINITIVEMENT',
                style: TextStyle(color: isTextValid ? Colors.red : Colors.grey),
              ),
              onPressed: isTextValid
                  ? () {
                      Navigator.of(context).pop();
                      _performCompleteDataDeletion();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // TODO-SC2: Implement complete data deletion
  // Details: Add proper database cleanup and app state reset functionality
  Future<void> _performCompleteDataDeletion() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'ngonnest.db');
      if (await File(dbPath).exists()) {
        await deleteDatabase(dbPath);
      }
      // Database is already cleared by deleting the file above
      // SettingsService handles its own clearing
      await SettingsService.clearAll();
      if (!mounted) return;
      _showDeletionSuccessDialog();
    } catch (e, stackTrace) {
      print('Deletion Error: $e');
      print('StackTrace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeletionSuccessDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Données supprimées'),
        content: const Text(
          'Toutes vos données ont été supprimées.\n'
          'L\'application va redémarrer.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO-SC2: Implement app restart or navigation to welcome screen
              // Details: Add proper app restart mechanism after data deletion
            },
          ),
        ],
      ),
    );
  }

  /// Afficher un message d'erreur pour le rapport de bug
  void _showBugReportErrorMessage(String errorMessage) {
    if (!mounted) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
        content: Text(
          'Impossible d\'envoyer le rapport:\n$errorMessage\n\n'
          'Vérifiez votre connexion internet et réessayez.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Settings are already saved individually when changed
      // This method can be used for any final validation or batch operations

      if (mounted) {
        _showSuccessMessage(
          AppLocalizations.of(context)?.settingsSaved ??
              'Paramètres sauvegardés avec succès',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur lors de la sauvegarde: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Afficher un dialogue de chargement avec gestion d'état améliorée
  void _showLoadingDialogWithState(String message) {
    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Afficher un message d'erreur pour le feedback
  void _showFeedbackErrorMessage(String errorMessage) {
    if (!mounted) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
        content: Text(
          'Impossible d\'envoyer le feedback:\n$errorMessage\n\n'
          'Vérifiez votre connexion internet et réessayez.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
