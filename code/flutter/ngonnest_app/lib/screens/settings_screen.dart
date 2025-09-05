import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_mode_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _localDataOnly = true;
  bool _hasAcceptedCloudSync = false;
  String _selectedLanguage = 'fr';
  String _notificationFrequency = 'quotidienne';
  String _currentTheme = 'clair';
  String _currentProfile = 'adulte';

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Section
            Container(
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.gear,
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuration',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personnalisez votre expérience NgonNest',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      items: _languages.map((lang) =>
                        DropdownMenuItem(
                          value: lang['code'],
                          child: Text(
                            lang['name']!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        )
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedLanguage = value!),
                      isExpanded: true,
                      hint: const Text('Langue', style: TextStyle(fontSize: 16)),
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
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
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
                      items: _notificationFrequencies.map((freq) =>
                        DropdownMenuItem(
                          value: freq['code'],
                          child: Text(
                            freq['name']!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        )
                      ).toList(),
                      onChanged: (value) => setState(() => _notificationFrequency = value!),
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
                  // Text(
                  //   'Données locales uniquement',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme Section
            _buildSectionTitle('Thème'),
            _buildSettingCard(
              title: 'Apparence de l\'application',
              subtitle: 'Choisissez votre thème préféré',
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentTheme = 'clair'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentTheme == 'clair'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: _currentTheme == 'clair'
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clair', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentTheme = 'sombre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentTheme == 'sombre'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: _currentTheme == 'sombre'
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sombre', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      CupertinoIcons.paintbrush,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Choisissez votre thème préféré',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profiles Section
            _buildSectionTitle('Profils'),
            _buildSettingCard(
              title: 'Type de profil',
              subtitle: 'Adaptation selon l\'utilisateur',
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentProfile = 'adulte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentProfile == 'adulte'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: _currentProfile == 'adulte'
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Adulte', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentProfile = 'enfant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentProfile == 'enfant'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: _currentProfile == 'enfant'
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Enfant', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      CupertinoIcons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Sélectionnez profil pour accès adapté',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sauvegarder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
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

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
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
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: enabled,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
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
            CheckboxListTile(
              title: const Text('J\'accepte la synchronisation cloud'),
              value: _hasAcceptedCloudSync,
              onChanged: (value) => setState(() => _hasAcceptedCloudSync = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
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

  void _saveSettings() {
    // Here we would save to database/local storage
    // For now, just show a confirmation
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
