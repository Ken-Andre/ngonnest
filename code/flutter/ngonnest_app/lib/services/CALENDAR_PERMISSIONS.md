# Gestion des permissions calendrier - CalendarSyncService

## Vue d'ensemble

Le `CalendarSyncService` gère les permissions calendrier de manière robuste et multi-plateforme avec une gestion complète des erreurs.

## Support des plateformes

### ✅ Android 13+ (API 33+)
- **Permissions**: `READ_CALENDAR` et `WRITE_CALENDAR` (runtime permissions)
- **Gestion**: Via `permission_handler` package
- **États supportés**:
  - `granted`: Permission accordée
  - `denied`: Permission refusée (peut redemander)
  - `permanentlyDenied`: Refus permanent (doit ouvrir les paramètres système)

### ✅ iOS
- **Permissions**: Calendrier natif iOS
- **Gestion**: Via `calendar_events` plugin
- **États supportés**:
  - `allowed`: Permission accordée
  - `denied`: Permission refusée
- **Restrictions**: Peut échouer si restrictions parentales activées

### ❌ Web
- **Support**: Non supporté
- **Comportement**: Retourne `false` immédiatement
- **Raison**: Les navigateurs n'ont pas d'API calendrier standard

### ❌ Desktop (Windows/Linux/macOS)
- **Support**: Non supporté dans le MVP
- **Comportement**: Retourne `false` immédiatement
- **Raison**: Intégration calendrier système complexe et hors scope MVP

## Flux de permissions

### 1. Vérification initiale
```dart
final status = await calendarService.getPermissionStatus();
```

États possibles:
- `granted` → Utiliser directement
- `denied` → Demander permission
- `permanentlyDenied` → Rediriger vers paramètres
- `unsupported` → Désactiver fonctionnalité
- `error` → Logger et désactiver

### 2. Demande de permission
```dart
final result = await calendarService.requestPermissionsWithFeedback();
```

Résultats:
- `granted` → Continuer
- `denied` → Afficher message explicatif
- `permanentlyDenied` → Proposer ouverture paramètres
- `unsupported` → Masquer option calendrier
- `error` → Afficher erreur générique

### 3. Ajout d'événement
```dart
await calendarService.addEvent(
  title: 'Réacheter du savon',
  description: 'Stock faible',
  start: DateTime.now().add(Duration(days: 3)),
);
```

## Gestion des erreurs

### Permission refusée
```
[CalendarSyncService] Cannot add event: permission not granted or unsupported platform
```
**Action**: Afficher message utilisateur expliquant pourquoi le calendrier est nécessaire

### Compte calendrier absent
```
[CalendarSyncService] Cannot add event: no calendar accounts available
```
**Action**: Guider l'utilisateur pour configurer un compte Google/iCloud

### Plateforme non supportée
```
[CalendarSyncService] Web platform detected - calendar not supported
```
**Action**: Masquer l'option calendrier dans l'UI

### Permission permanentement refusée (Android)
```
[CalendarSyncService] Android calendar permission permanently denied
```
**Action**: Proposer un bouton "Ouvrir les paramètres" avec `openAppSettings()`

## Exemple d'intégration UI

### Écran de paramètres
```dart
class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _calendarService = CalendarSyncService();
  CalendarPermissionStatus _status = CalendarPermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await _calendarService.getPermissionStatus();
    setState(() => _status = status);
  }

  Future<void> _requestPermission() async {
    final result = await _calendarService.requestPermissionsWithFeedback();
    
    switch (result) {
      case CalendarPermissionResult.granted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Calendrier activé')),
        );
        break;
        
      case CalendarPermissionResult.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Permission calendrier refusée'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _requestPermission,
            ),
          ),
        );
        break;
        
      case CalendarPermissionResult.permanentlyDenied:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permission requise'),
            content: Text(
              'Pour utiliser le calendrier, vous devez activer la permission '
              'dans les paramètres de l\'application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.pop(context);
                },
                child: Text('Ouvrir paramètres'),
              ),
            ],
          ),
        );
        break;
        
      case CalendarPermissionResult.unsupported:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Calendrier non supporté sur cette plateforme'),
          ),
        );
        break;
        
      case CalendarPermissionResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la vérification des permissions'),
          ),
        );
        break;
    }
    
    await _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    // Masquer l'option si non supporté
    if (_status == CalendarPermissionStatus.unsupported) {
      return SizedBox.shrink();
    }

    return SwitchListTile(
      title: Text('Synchronisation calendrier'),
      subtitle: Text(_getSubtitle()),
      value: _status == CalendarPermissionStatus.granted,
      onChanged: (_) => _requestPermission(),
    );
  }

  String _getSubtitle() {
    switch (_status) {
      case CalendarPermissionStatus.granted:
        return 'Activé - Les alertes apparaîtront dans votre calendrier';
      case CalendarPermissionStatus.denied:
        return 'Désactivé - Touchez pour activer';
      case CalendarPermissionStatus.permanentlyDenied:
        return 'Bloqué - Ouvrir les paramètres pour activer';
      case CalendarPermissionStatus.error:
        return 'Erreur - Réessayez plus tard';
      default:
        return '';
    }
  }
}
```

## Logs et debugging

### Logs de succès
```
[CalendarSyncService] Android calendar permission granted
[CalendarSyncService] Event added successfully: Réacheter du savon
```

### Logs d'avertissement
```
[CalendarSyncService] iOS calendar permission denied: denied
[CalendarSyncService] Cannot add event: no calendar accounts available
```

### Logs d'erreur
```
[CalendarSyncService] Failed to request calendar permissions
Error: PlatformException(...)
```

## Tests

### Test manuel Android
1. Désinstaller l'app
2. Réinstaller
3. Tenter d'activer le calendrier → Dialog de permission
4. Refuser → Vérifier message d'erreur
5. Réessayer → Dialog de permission à nouveau
6. Refuser et cocher "Ne plus demander" → `permanentlyDenied`
7. Ouvrir paramètres système → Activer manuellement
8. Retour à l'app → `granted`

### Test manuel iOS
1. Désinstaller l'app
2. Réinstaller
3. Tenter d'activer le calendrier → Dialog natif iOS
4. Refuser → Vérifier message d'erreur
5. Réessayer → Pas de nouveau dialog (iOS ne redemande pas)
6. Ouvrir Réglages > NgonNest > Calendrier → Activer
7. Retour à l'app → `granted`

### Test Web
1. Ouvrir l'app sur navigateur
2. Vérifier que l'option calendrier est masquée
3. Vérifier logs: "Web platform detected - calendar not supported"

## Notes de dépréciation

⚠️ **Warning**: `Permission.calendar` est déprécié dans `permission_handler` 11.x

### Solution actuelle
Le code utilise encore `Permission.calendar` car:
1. Les permissions granulaires (`calendarFullAccess`, `calendarWriteOnly`) nécessitent Android 14+ (API 34)
2. Le MVP cible Android 13+ (API 33)
3. La migration sera faite dans une version future

### Migration future (Android 14+)
```dart
// Android 14+ (API 34)
final readStatus = await Permission.calendarFullAccess.status;
final writeStatus = await Permission.calendarWriteOnly.status;
```

Pour l'instant, les warnings de dépréciation sont acceptables car le code fonctionne correctement sur Android 13.

## Checklist de validation

- [x] Android 13+ : Permissions runtime fonctionnelles
- [x] iOS : Dialog natif fonctionnel
- [x] Web : Désactivation gracieuse
- [x] Desktop : Désactivation gracieuse
- [x] Permission refusée : Message clair
- [x] Permission permanente : Redirection paramètres
- [x] Compte absent : Message explicatif
- [x] Erreurs : Logging complet
- [x] Tests manuels : Android et iOS validés

## Références

- [permission_handler documentation](https://pub.dev/packages/permission_handler)
- [calendar_events documentation](https://pub.dev/packages/calendar_events)
- [Android Calendar Permissions](https://developer.android.com/reference/android/Manifest.permission#READ_CALENDAR)
- [iOS Calendar Permissions](https://developer.apple.com/documentation/eventkit)
