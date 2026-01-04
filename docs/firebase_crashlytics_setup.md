# Firebase Crashlytics - Guide de Configuration NgonNest

## 📋 Vue d'Ensemble

Ce guide explique comment configurer et utiliser Firebase Crashlytics dans l'application NgonNest pour le monitoring proactif des crashes et la stabilité de l'application.

## 🎯 Objectifs

- **Détection proactive** des problèmes de stabilité
- **Debug efficace** avec contexte complet (breadcrumbs, métadonnées)
- **Métriques de stabilité** pour investisseurs et DevOps
- **Amélioration continue** de l'expérience utilisateur camerounais

## 🏗️ Architecture

### Services Implémentés

1. **CrashAnalyticsService** - Service principal de crash reporting
2. **BreadcrumbService** - Traçage des événements précédant un crash
3. **CrashMetricsService** - Métriques avancées et alertes

### Flux de Données

```
Erreur App → CrashAnalyticsService → Firebase Crashlytics (cloud)
                ↓
         ErrorLoggerService (local offline-first)
                ↓
         BreadcrumbService (contexte)
                ↓
         CrashMetricsService (métriques)
```

## 🚀 Configuration Firebase Console

### Étape 1: Activer Crashlytics

1. Ouvrir [Firebase Console](https://console.firebase.google.com)
2. Sélectionner le projet NgonNest
3. Aller dans **Crashlytics** dans le menu latéral
4. Cliquer sur **Activer Crashlytics**

### Étape 2: Configuration Android

1. Dans Firebase Console → **Project Settings** → **Android**
2. Télécharger le fichier `google-services.json` mis à jour
3. Placer dans `android/app/google-services.json`
4. Vérifier que le package name correspond: `com.example.ngonnest_app`

### Étape 3: Configuration iOS (si applicable)

1. Dans Firebase Console → **Project Settings** → **iOS**
2. Télécharger le fichier `GoogleService-Info.plist` mis à jour
3. Placer dans `ios/Runner/GoogleService-Info.plist`

### Étape 4: Upload des Symboles de Debug

#### Android (ProGuard/R8)

Le fichier `android/app/build.gradle` doit contenir:

```gradle
buildTypes {
    release {
        // Activer ProGuard/R8
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        
        // Firebase Crashlytics mapping file upload
        firebaseCrashlytics {
            mappingFileUploadEnabled true
        }
    }
}
```

#### iOS (dSYM)

Les symboles iOS sont automatiquement uploadés lors du build si configuré correctement dans Xcode.

## 📊 Métriques Disponibles

### MVP Critical (Finance/Investors)

- **Taux de crash global**: Objectif < 1%
- **Taux de crash par version**: Suivi des régressions
- **Taux de crash par plateforme**: Android 8.0+
- **Impact sur rétention**: Corrélation crashes/désinstallations

### High Priority (DevOps)

- **Taux de crash par device model**: Identification des devices problématiques
- **Taux de crash par conditions**: Mémoire faible, batterie faible
- **Stack traces déobfusqués**: Debug efficace
- **Performance mémoire au crash**: Analyse des fuites mémoire

### Product Owner (UX Flow)

- **Taux de crash par fonctionnalité**: Priorisation des fixes
- **Taux de crash pendant flows critiques**: Onboarding, inventaire
- **Corrélation crash/événements analytics**: Contexte utilisateur
- **Breadcrumbs des 10 dernières actions**: Reproduction des bugs

## 🔧 Utilisation dans le Code

### Initialisation (déjà fait dans main.dart)

```dart
// Initialize Crash Analytics Service
await CrashAnalyticsService().initialize(enableInDebug: kDebugMode);

// Initialize Crash Metrics Service
await CrashMetricsService().startSession();
```

### Log d'Erreur Non-Fatale

```dart
try {
  // Code qui peut échouer
  await riskyOperation();
} catch (e, stackTrace) {
  await CrashAnalyticsService().logNonFatalError(
    component: 'MyComponent',
    operation: 'riskyOperation',
    error: e,
    stackTrace: stackTrace,
    severity: ErrorSeverity.high,
    metadata: {
      'user_action': 'button_click',
      'screen': 'dashboard',
    },
  );
}
```

### Ajout de Breadcrumbs

```dart
// Navigation
BreadcrumbService().addNavigation('DashboardScreen');

// Action utilisateur
BreadcrumbService().addUserAction('Tapped add product button');

// Opération DB
BreadcrumbService().addDatabaseOperation('Insert product', data: {'id': productId});

// Requête réseau
BreadcrumbService().addNetworkRequest(
  method: 'POST',
  url: '/api/sync',
  statusCode: 200,
);
```

### Définir l'Utilisateur

```dart
// Après connexion/onboarding
await CrashAnalyticsService().setUserId(userId);
await CrashAnalyticsService().setSessionId(sessionId);
```

### Ajouter des Métadonnées Custom

```dart
await CrashAnalyticsService().setCustomKey('household_size', householdSize.toString());
await CrashAnalyticsService().setCustomKey('budget_enabled', 'true');
```

## 📈 Monitoring et Alertes

### Accéder aux Rapports de Crash

1. Firebase Console → **Crashlytics**
2. Vue d'ensemble: Taux de crash, utilisateurs affectés
3. **Issues**: Liste des crashes groupés par similarité
4. Cliquer sur un crash pour voir:
   - Stack trace
   - Breadcrumbs
   - Métadonnées device/app
   - Logs custom

### Alertes Automatiques

Le `CrashMetricsService` génère des alertes automatiques si:

- **Taux de crash global** > 1%
- **Crashes par jour** > 10
- **Taux de crash fatal** > 0.1%

Les alertes sont loggées et envoyées à Firebase Analytics:

```dart
// Événement analytics 'crash_alert'
{
  'title': 'High Crash Rate',
  'message': 'Crash rate is 2.5% (threshold: 1%)',
  'severity': 'high'
}
```

### Rapport de Stabilité (Debug)

```dart
// En mode debug
await CrashMetricsService().printStabilityReport();
```

Affiche:
- Version app et device
- Total sessions et crashes
- Taux de crash et taux fatal
- Top 5 composants avec le plus de crashes

## 🧪 Testing

### Test de Crash (Debug Uniquement)

```dart
// Force un crash pour tester le reporting
await CrashAnalyticsService().testCrash();
```

⚠️ **Attention**: Ceci va réellement crasher l'app. À utiliser uniquement en debug.

### Vérifier les Rapports Non Envoyés

```dart
final hasUnsent = await CrashAnalyticsService().checkForUnsentReports();
if (hasUnsent) {
  await CrashAnalyticsService().sendUnsentReports();
}
```

## 🌍 Optimisations pour le Marché Camerounais

### Offline-First

- **Logs locaux d'abord**: `ErrorLoggerService` sauvegarde tout localement
- **Sync cloud optionnel**: Crashlytics envoie quand réseau disponible
- **Pas de blocage**: L'app continue même si Firebase échoue

### Performance

- **Taille minimale**: Firebase Crashlytics ~2MB
- **Mémoire optimisée**: Breadcrumbs limités à 100 entrées
- **Batterie**: Envoi en batch, pas de polling continu

### Compatibilité

- **Android 8.0+**: 75% du marché camerounais
- **Devices low-end**: Métriques mémoire spécifiques
- **Réseau faible**: Retry automatique avec exponential backoff

## 🔐 Privacy & Sécurité

### Données Collectées

- Stack traces (code source obfusqué en production)
- Métadonnées device (model, OS, mémoire)
- Breadcrumbs (actions utilisateur anonymisées)
- Métadonnées custom (pas de données sensibles)

### Données NON Collectées

- Données personnelles utilisateur
- Contenu des champs de formulaire
- Données financières
- Localisation GPS

### Consentement Utilisateur

```dart
// Désactiver Crashlytics si l'utilisateur refuse
await CrashAnalyticsService().setCrashlyticsCollectionEnabled(false);
```

## 📚 Ressources

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Flutter Crashlytics Plugin](https://pub.dev/packages/firebase_crashlytics)
- [Best Practices](https://firebase.google.com/docs/crashlytics/best-practices)

## 🆘 Troubleshooting

### Les crashes n'apparaissent pas dans Firebase Console

1. Vérifier que Crashlytics est activé dans Firebase Console
2. Vérifier le package name dans `google-services.json`
3. Attendre 5-10 minutes (délai de traitement Firebase)
4. Vérifier les logs: `[CrashAnalytics] Firebase Crashlytics initialized`

### Symboles de debug manquants (stack traces illisibles)

1. Android: Vérifier `mappingFileUploadEnabled true` dans build.gradle
2. iOS: Vérifier que les dSYM sont uploadés automatiquement
3. Rebuild en mode release et tester

### Erreur d'initialisation Firebase

1. Vérifier que `google-services.json` est présent
2. Vérifier que Firebase Core est initialisé avant Crashlytics
3. Vérifier les logs d'erreur dans la console

## 📞 Support

Pour toute question ou problème:
- Créer une issue GitHub avec le tag `crashlytics`
- Consulter les logs avec `flutter logs`
- Vérifier le rapport de stabilité: `CrashMetricsService().printStabilityReport()`
