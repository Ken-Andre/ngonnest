import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme_mode_notifier.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../services/navigation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for settings not managed by Provider
  bool _notificationsEnabled = true;
  bool _localDataOnly = true;
  bool _hasAcceptedCloudSync = false;
  String _selectedLanguage = 'fr';
  String _notificationFrequency = 'quotidienne';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // TODO: Implement settings initialization from SharedPreferences
  // Load all saved settings when screen opens
  // This includes: language, notifications, cloud sync preferences, etc.
  Future<void> _loadSettings() async {
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    //   _selectedLanguage = prefs.getString('language') ?? 'fr';
    //   _localDataOnly = prefs.getBool('local_data_only') ?? true;
    // });
  }

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français'},
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
  ];
  final List<Map<String, String>> _notificationFrequencies = [
    {'code': 'quotidienne', 'name': 'Quotidienne'},
    {'code': 'hebdomadaire', 'name': 'Hebdomadaire'},
  ];

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
          onTabChanged: (index) => NavigationService.navigateToTab(context, index),
          // Le contenu spécifique de l'écran Paramètres est passé ici
          body: Builder(
            builder: (BuildContext context) {
              // Utiliser Builder pour accéder au contexte correct
              // si MainNavigationWrapper crée un nouveau Scaffold
              return Scaffold(
                // AppBar est défini ici, à l'intérieur du Scaffold
                // fourni par MainNavigationWrapper (espérons-le)
                appBar: AppBar(
                  title: const Text('Paramètres'),
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                        _buildSectionTitle('Langue'),
                        _buildSettingCard(
                          title: 'Langue de l\'application',
                          subtitle: 'Choisissez votre langue préférée',
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  underline: const SizedBox(),
                                  items: _languages
                                      .map(
                                        (lang) => DropdownMenuItem(
                                          value: lang['code'],
                                          child: Text(
                                            lang['name']!,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedLanguage = value!);
                                    // TODO: Implement language change functionality
                                  },
                                  isExpanded: true,
                                  hint: const Text(
                                    'Langue',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  CupertinoIcons.globe,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                tooltip: 'Sélectionnez pour changer l\'interface',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Notifications Section
                        _buildSectionTitle('Notifications'),
                        _buildSettingCard(
                          title: 'Notifications push',
                          subtitle: 'Recevoir des alertes sur l\'app',
                          child: Row(
                            children: [
                              CupertinoSwitch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _notificationsEnabled = value);
                                  // TODO: Implement notification settings
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  CupertinoIcons.bell,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                tooltip: 'Activer rappels pour stocks bas',
                              ),
                            ],
                          ),
                        ),
                        if (_notificationsEnabled) ...[
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.only(left: 16),
                            child: _buildSettingCard(
                              title: 'Fréquence des notifications',
                              subtitle: 'Choisissez la fréquence des rappels',
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
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _notificationFrequency = value!),
                                  isExpanded: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Privacy Section
                        _buildSectionTitle('Confidentialité'),
                        _buildSettingCard(
                          title: 'Données locales uniquement',
                          subtitle: 'Pas de sync sans accord explicite',
                          child: Row(
                            children: [
                              CupertinoSwitch(
                                value: _localDataOnly,
                                onChanged: (value) {
                                  if (!value) {
                                    _showCloudSyncConsent();
                                  } else {
                                    setState(() => _localDataOnly = value);
                                  }
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Theme Section
                        _buildSectionTitle('Thème'),
                        _buildSettingCard(
                          title:
                              'Mode ${themeModeNotifier.themeMode == ThemeMode.light ? 'clair' : themeModeNotifier.themeMode == ThemeMode.dark ? 'sombre' : 'système'}',
                          subtitle: 'Changer l\'apparence de l\'application',
                          child: CupertinoSwitch(
                            value: themeModeNotifier.themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              themeModeNotifier.toggleTheme();
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Support Section
                        _buildSectionTitle('Support'),
                        _buildSettingCard(
                          title: 'Envoyer un feedback',
                          subtitle: 'Partagez vos suggestions',
                          child: ElevatedButton.icon(
                            onPressed: _showFeedbackDialog,
                            icon: const Icon(CupertinoIcons.mail, size: 18),
                            label: const Text('Envoyer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                          title: 'Signaler un bug',
                          subtitle: 'Décrivez le problème',
                          child: ElevatedButton.icon(
                            onPressed: _showBugReportDialog,
                            icon: const Icon(Icons.bug_report, size: 18),
                            label: const Text('Signaler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                        _buildSectionTitle('Données'),
                        _buildSettingCard(
                          title: 'Exporter les données',
                          subtitle: 'Sauvegarder vos données localement',
                          child: ElevatedButton.icon(
                            onPressed: _exportData,
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Exporter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSettingCard(
                          title: 'Importer des données',
                          subtitle: 'Restaurer depuis un fichier sauvegardé',
                          child: ElevatedButton.icon(
                            onPressed: _importData,
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('Importer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSettingCard(
                          title: 'Supprimer toutes les données',
                          subtitle: 'Reset complet - Action irréversible',
                          child: ElevatedButton.icon(
                            onPressed: _showDeleteAllDataConfirmation,
                            icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                            label: const Text('Supprimer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Sauvegarder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  void _showCloudSyncConsent() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Synchronisation Cloud'),
        content: Column(
          children: [
            const Text(
              'La synchronisation cloud permet de sauvegarder vos données en ligne. '
              'Acceptez-vous cette fonctionnalité ?',
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                title: const Text('J\'accepte la synchronisation cloud'),
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
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Accepter'),
            onPressed: () {
              if (_hasAcceptedCloudSync) {
                // TODO: Implement cloud synchronization
                setState(() => _localDataOnly = false);
                Navigator.of(context).pop();
                _showSyncEnabledMessage();
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
        title: const Text('Synchronisation activée'),
        content: const Text(
          'La synchronisation cloud a été activée. '
          'Vos données seront automatiquement sauvegardées.',
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

  void _showFeedbackDialog() {
    String feedbackMessage = '';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Envoyer un feedback'),
        content: Column(
          children: [
            const Text(
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
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
                child: TextField(
                  maxLines: 4,
                  onChanged: (value) => feedbackMessage = value,
                  decoration: const InputDecoration(
                    hintText: 'Tapez votre message ici...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Envoyer'),
            onPressed: () {
              if (feedbackMessage.trim().isNotEmpty) {
                // TODO: Implement server-side feedback submission
                Navigator.of(context).pop();
                _showFeedbackSentMessage();
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
        title: const Text('Signaler un bug'),
        content: Column(
          children: [
            const Text(
              'Votre signalement sera envoyé à notre équipe de développement.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour continuer à nous contacter, rejoignez notre bot Telegram :',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                const url = 'https://t.me/NgonNestBot';
                await Clipboard.setData(const ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien Telegram copié !'),
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
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
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
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
                child: TextField(
                  maxLines: 4,
                  onChanged: (value) => bugDescription = value,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez le bug en détail...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Signaler'),
            onPressed: () {
              if (bugDescription.trim().isNotEmpty) {
                // TODO: Implement bug report handling with Telegram integration
                Navigator.of(context).pop();
                _showBugReportedMessage();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackSentMessage() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Feedback envoyé'),
        content: const Text(
          'Merci pour votre retour ! Nous l\'utiliserons pour améliorer l\'application.',
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

  void _showBugReportedMessage() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Bug signalé'),
        content: const Text(
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

  // TODO: Implement data export functionality
  Future<void> _exportData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité d\'export en cours de développement'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      print('Export Error: $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: Implement data import functionality with smart data handling
  Future<void> _importData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité d\'import en cours de développement'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      print('Import Error: $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'import : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteAllDataConfirmation() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text(
          '⚠️ ATTENTION ⚠️',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          children: const [
            SizedBox(height: 8),
            Text(
              'Cette action est IRRÉVERSIBLE !',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text(
              'Toutes vos données seront supprimées :\n'
              '• Profil du foyer\n'
              '• Inventaire complet\n'
              '• Historique d\'achats\n'
              '• Préférences et paramètres\n'
              'L\'application retournera à son état initial.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text(
              'SUPPRIMER TOUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: Text(
                'SUPPRIMER DÉFINITIVEMENT',
                style: TextStyle(
                  color: isTextValid ? Colors.red : Colors.grey,
                ),
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

  // TODO: Implement complete data deletion
  Future<void> _performCompleteDataDeletion() async {
    try {
      _showDeletionSuccessDialog();
    } catch (e, stackTrace) {
      print('Deletion Error: $e');
      print('StackTrace: $stackTrace');
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
              // TODO: Implement app restart or navigation to welcome screen
            },
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement comprehensive settings persistence
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Paramètres sauvegardés'),
        content: const Text(
          'Vos préférences ont été sauvegardées avec succès.',
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
}
