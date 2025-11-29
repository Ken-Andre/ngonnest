// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'NgonNest';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get inventory => 'Inventaire';

  @override
  String get budget => 'Budget';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Activerles notifications';

  @override
  String get notificationsDisabled => 'Désactiver les notifications';

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemMode => 'Mode système';

  @override
  String get save => 'Sauvegarder';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get settingsSaved => 'Paramètres sauvegardés avec succès';

  @override
  String get notificationPermissionDenied =>
      'Permission de notification refusée. Vous pouvez l\'activerdans les paramètres système.';

  @override
  String get openSystemSettings => 'Ouvrir les paramètres système';

  @override
  String get intelligentHouseholdManagement =>
      'Gestion intelligente de votre foyer';

  @override
  String get languageOfApp => 'Langue de l\'application';

  @override
  String get choosePreferredLanguage => 'Choisissez votre langue préférée';

  @override
  String get selectToChangeInterface =>
      'Sélectionnez pour changer l\'interface';

  @override
  String get receiveAppAlerts => 'Recevoir des alertes sur l\'app';

  @override
  String get enableRemindersForLowStock => 'Activer rappels pour stocks bas';

  @override
  String get notificationFrequency => 'Fréquence des notifications';

  @override
  String get chooseReminderFrequency => 'Choisissez la fréquence des rappels';

  @override
  String get daily => 'Quotidienne';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get localDataOnly => 'Données locales uniquement';

  @override
  String get noSyncWithoutExplicitConsent =>
      'Pas de sync sans accord explicite';

  @override
  String get changeAppAppearance => 'Changer l\'apparence de l\'application';

  @override
  String get support => 'Support';

  @override
  String get sendFeedback => 'Envoyer un feedback';

  @override
  String get shareYourSuggestions => 'Partagez vossuggestions';

  @override
  String get send => 'Envoyer';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String get describeProblem => 'Décrivez le problème';

  @override
  String get report => 'Signaler';

  @override
  String get data => 'Données';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get backupDataLocally => 'Sauvegarder vos données localement';

  @override
  String get export => 'Exporter';

  @override
  String get importData => 'Importer des données';

  @override
  String get restoreFromBackupFile => 'Restaurer depuis un fichier sauvegardé';

  @override
  String get import => 'Importer';

  @override
  String get cloudImportTitle => 'Données cloudtrouvées';

  @override
  String get cloudImportMessage =>
      'Nous avons trouvé des données existantes dans votre compte cloud. Que souhaitez-vous faire ?';

  @override
  String get importOption => 'Importer';

  @override
  String get importOptionDescription =>
      'Remplacer les données locales par les données cloud';

  @override
  String get mergeOption => 'Fusionner';

  @override
  String get mergeOptionDescription => 'Combiner les données locales et cloud';

  @override
  String get skipOption => 'Ignorer';

  @override
  String get skipOptionDescription =>
      'Conserver uniquement les données locales';

  @override
  String get importInProgress => 'Import en cours...';

  @override
  String get importingHouseholds => 'Importation des ménages...';

  @override
  String get importingProducts => 'Importation des produits...';

  @override
  String get importingBudgets => 'Importation des budgets...';

  @override
  String get importingPurchases => 'Importation des achats...';

  @override
  String get importSuccess => 'Import réussi';

  @override
  String get importSuccessMessage =>
      'Vos données ont été importées avec succès';

  @override
  String get importPartialSuccess => 'Import partiellement réussi';

  @override
  String get importError => 'Erreur d\'importation';

  @override
  String get retry => 'Réessayer';

  @override
  String entitiesImported(Object count) {
    return '$count éléments importés';
  }

  @override
  String householdsImported(Object count) {
    return '$count ménages';
  }

  @override
  String productsImported(Object count) {
    return '$count produits';
  }

  @override
  String budgetsImported(Object count) {
    return '$count budgets';
  }

  @override
  String purchasesImported(Object count) {
    return '$count achats';
  }

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get completeResetIrreversible => 'Reset complet - Action irréversible';

  @override
  String get delete => 'Supprimer';

  @override
  String get languageChangedSuccessfully => 'Langue modifiée avec succès';

  @override
  String get errorActivatingNotifications =>
      'Erreur lors de l\'activation des notifications';

  @override
  String get cloudSynchronization => 'Synchronisation Cloud';

  @override
  String get cloudSyncAllowsOnlineBackup =>
      'La synchronisation cloud permet de sauvegarder vos données en ligne. Acceptez-vous cette fonctionnalité ?';

  @override
  String get acceptCloudSync => 'J\'accepte la synchronisation cloud';

  @override
  String get accept => 'Accepter';

  @override
  String get syncEnabled => 'Synchronisation activée';

  @override
  String get cloudSyncActivated =>
      'La synchronisation cloud a été activée. Vos données seront automatiquement sauvegardées.';

  @override
  String get sendFeedbackTitle => 'Envoyer un feedback';

  @override
  String get feedbackMessage =>
      'Nous aimerions connaître votre avis sur l\'application.';

  @override
  String get typeMessageHere => 'Tapez votre message ici...';

  @override
  String get reportBugTitle => 'Signaler un bug';

  @override
  String get bugReportWillBeSent =>
      'Votre signalement sera envoyé à notre équipe de développement.';

  @override
  String get continueContactTelegram =>
      'Pour continuer à nous contacter, rejoignez notre bot Telegram :';

  @override
  String get telegramLinkCopied => 'Lien Telegram copié !';

  @override
  String get feedbackSent => 'Feedback envoyé';

  @override
  String get feedbackSentSuccessfully =>
      'Votre feedback a été envoyé avec succès.';

  @override
  String get bugReportSent => 'Signalement envoyé';

  @override
  String get bugReportSentSuccessfully =>
      'Votre signalement a été envoyé avec succès.';

  @override
  String get deleteAllDataConfirmation => 'Supprimer toutes les données ?';

  @override
  String get deleteAllDataWarning =>
      'Cette action supprimera définitivement toutes vos données d\'inventaire, de budget et de paramètres. Cette action ne peut pas être annulée.';

  @override
  String get dataDeleted => 'Données supprimées';

  @override
  String get allDataDeletedRestart =>
      'Toutes vos données ont été supprimées.\\nL\'application va redémarrer.';

  @override
  String get exportDataConfirm =>
      'Exporter toutes vos données vers un fichier JSON ?';

  @override
  String get exportSuccess => 'Export effectué avec succès';

  @override
  String get importDataConfirm =>
      'Cette opération remplacera vos données actuelles. Continuer ?';

  @override
  String get storagePermissionRequired =>
      'L\'autorisation de stockage est requise pour exporter les données';

  @override
  String get storagePermissionDenied =>
      'Autorisation de stockage refusée. Veuillez accorder l\'accès dans les paramètres système';

  @override
  String get storagePermissionPermanentlyDenied =>
      'Autorisation de stockage définitivement refusée. Veuillez l\'activer dans les paramètres de l\'application';

  @override
  String get grantStoragePermission => 'Accorder l\'autorisation de stockage';

  @override
  String get requestTimedOut => 'Requête expirée';

  @override
  String get networkError =>
      'Erreur réseau. Veuillez vérifier votre connexion internet.';

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get useYourEmail => 'Utiliser votre email';

  @override
  String get alreadyHaveAccount => 'Déjà un compte? Se connecter';

  @override
  String get noAccount => 'Pas de compte ? Créer un compte';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get passwordTooShort => 'Mot de passe trop court (min 8 caractères)';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pleaseEnterFullName => 'Veuillez saisir votre nom complet';

  @override
  String get pleaseEnterFirstAndLastName =>
      'Veuillez saisir votre prénom et nom';

  @override
  String get pleaseEnterEmail => 'Veuillez saisir votre email';

  @override
  String get pleaseEnterPassword => 'Veuillez saisir votre mot de passe';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get accountCreatedSuccessfully => 'Compte créé avec succès !';

  @override
  String get pleaseCheckEmailToConfirmAccount =>
      'Veuillez vérifier votre email pour confirmer votre compte.';

  @override
  String get signInSuccessful => 'Connexion réussie !';

  @override
  String get googleSignInSuccessful => 'Connexion Google réussie !';

  @override
  String get appleSignInSuccessful => 'Connexion Apple réussie !';

  @override
  String get checkYourEmailToConfirm =>
      'Vérifiez votre email pour confirmer votre compte.';

  @override
  String get emailConfirmedYouCanSignIn =>
      'Email confirmé. Vous pouvez maintenant vous connecter.';

  @override
  String get resendConfirmationEmail => 'Renvoyer l\'email de confirmation';

  @override
  String get confirmationEmailResent => 'Email de confirmation renvoyé.';

  @override
  String resendInSeconds(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get connectQuicklyWithExistingAccount =>
      'Connectez-vous rapidement avec votre compte existant';

  @override
  String get or => 'ou';

  @override
  String get socialNetworks => 'Réseaux sociaux';

  @override
  String get syncDataQuestion => 'Voulez-vous synchroniser vos données?';

  @override
  String get syncDataExplanation =>
      'La synchronisation cloud permet de sauvegarder vos données en ligne et de les retrouver sur tous vos appareils.';

  @override
  String get yes => 'Oui';

  @override
  String get noLater => 'Non, plus tard';

  @override
  String get syncLaterMessage =>
      'Vous pouvez activer la synchronisation plus tard dansles paramètres';

  @override
  String get synchronization => 'Synchronisation';

  @override
  String get syncStatus => 'État de la synchronisation';

  @override
  String get syncDisabled => 'Désactivée';

  @override
  String get syncEnabledStatus => 'Activée';

  @override
  String get syncUpToDate => '✓ Synchronisé';

  @override
  String syncPending(Object count) {
    return '⏳ En attente ($count opérations)';
  }

  @override
  String get syncInProgress => '🔄 Synchronisation...';

  @override
  String get syncError => '⚠️ Erreur de sync';

  @override
  String lastSyncTime(String time) {
    return 'Dernière sync: $time';
  }

  @override
  String get neverSynced => 'Jamais synchronisé';

  @override
  String get tapForDetails => 'Appuyez pour plus de détails';

  @override
  String get connectToEnableSync =>
      'Connectez-vous pour activer la synchronisation';

  @override
  String get syncStatusDetails => 'Détails de synchronisation';

  @override
  String get pendingOperations => 'Opérations en attente';

  @override
  String get failedOperations => 'Opérations échouées';

  @override
  String get syncHistory => 'Historique de synchronisation';

  @override
  String get enableCloudSync => 'Activer la synchronisation cloud';

  @override
  String get disableCloudSync => 'Désactiver la synchronisation cloud';

  @override
  String get keepLocal => 'Conserver local';

  @override
  String get keepLocalDescription => 'Envoyer les donnéeslocales vers le cloud';

  @override
  String get importFromCloud => 'Importer du cloud';

  @override
  String get importFromCloudDescription => 'Télécharger les données du cloud';

  @override
  String get mergeData => 'Fusionner';

  @override
  String get mergeDataDescription => 'Combiner les données locales et cloud';

  @override
  String get syncSuccessMessage => 'Synchronisation activée avec succès';

  @override
  String get importOptionsTitle => 'Options d\'importation';

  @override
  String get chooseImportOption =>
      'Choisissez comment gérer vos données existantes';

  @override
  String get monthlyBudget => 'Budget mensuel';

  @override
  String get editMonthlyBudget => 'Modifier le budget mensuel';

  @override
  String get enterBudgetAmount => 'Entrez le montant de votre budget mensuel';

  @override
  String get notSet => 'Non défini';

  @override
  String get edit => 'Modifier';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get budgetOutOfRange => 'Le budget doit être entre 50€ et 2000€';

  @override
  String get budgetUpdatedSuccessfully => 'Budget mis à jour avec succès';

  @override
  String get errorUpdatingBudget => 'Erreur lors de la mise à jour du budget';

  @override
  String get errorDatabaseConnection =>
      'Impossible de se connecter à la base de données. Veuillez réessayer.';

  @override
  String get errorBudgetCalculation =>
      'Erreur lors du calcul du budget. Utilisation des valeurs par défaut.';

  @override
  String get errorSyncFailed =>
      'La synchronisation a échoué. Vos données sont sauvegardées localement.';

  @override
  String get errorNotificationPermission =>
      'Permission de notification refusée. Activez-la dans les paramètres.';

  @override
  String get errorMigrationFailed =>
      'Échec de la mise à jour de la base de données. L\'application continue avec l\'ancienne version.';

  @override
  String get errorValidationBudgetAmount =>
      'Le montant du budget doit être un nombre positif.';

  @override
  String get errorNetworkUnavailable =>
      'Pas de connexion internet. Fonctionnement en mode hors ligne.';

  @override
  String get errorLoadingBudgetCategories =>
      'Impossible de charger les catégories budgétaires.';

  @override
  String get errorSavingBudgetCategory =>
      'Erreur lors de la sauvegarde de la catégorie.';

  @override
  String get errorDeletingBudgetCategory =>
      'Erreur lors de la suppression de la catégorie.';

  @override
  String get errorRecalculatingBudgets =>
      'Erreur lors du recalcul des budgets.';

  @override
  String get errorInvalidMonthFormat =>
      'Format de mois invalide. Utilisez AAAA-MM.';

  @override
  String get errorMissingFoyerData =>
      'Données du foyer manquantes. Veuillez compléter votre profil.';

  @override
  String get errorBudgetNotificationFailed =>
      'Impossible d\'afficher la notification de budget.';

  @override
  String get errorSyncRetryExhausted =>
      'Échec de la synchronisation après plusieurs tentatives.';

  @override
  String get warningBudgetCalculationFallback =>
      'Calcul du budget échoué. Utilisation des valeurs par défaut.';

  @override
  String get warningInvalidPercentage =>
      'Pourcentage invalide détecté. Utilisation de la valeur par défaut.';

  @override
  String get budgetNotSet => 'Budget mensuel non défini';

  @override
  String get budgetNotSetMessage =>
      'Veuillez définir votre budget mensuel dans les paramètres pour commencer à suivre vos dépenses.';

  @override
  String get goToSettings => 'Aller aux paramètres';

  @override
  String get updateMonthlyBudget => 'Mettre à jour le budget mensuel';

  @override
  String get budgetWillBeRecalculated =>
      'Les limites de vos catégories budgétaires seront recalculées proportionnellement.';

  @override
  String get enterAmount => 'Entrez le montant';

  @override
  String get pleaseEnterValidAmount => 'Veuillez entrer un montant valide';

  @override
  String get errorLoadingHouseholdData =>
      'Erreur lors du chargement des données du foyer';

  @override
  String get setBudgetInSettings => 'Définissez votre budget mensuel';

  @override
  String get modify => 'Modifier';

  @override
  String get budgetLoadError =>
      'Impossible de charger les données budgétaires. Vérifiez votre connexion.';

  @override
  String get budgetRetry => 'Réessayer';

  @override
  String get budgetUpdateError => 'Erreur lors de la mise à jour du budget';

  @override
  String get budgetDeleteError =>
      'Erreur lors de la suppression de la catégorie';

  @override
  String get introTitle1 => 'Bienvenue sur NgoNest';

  @override
  String get introDesc1 =>
      'L\'application qui simplifie la gestion de votre foyer.';

  @override
  String get introTitle2 => 'Gérez votre inventaire';

  @override
  String get introDesc2 =>
      'Suivez vos stocks et évitez le gaspillage facilement.';

  @override
  String get introTitle3 => 'Suivez votre budget';

  @override
  String get introDesc3 =>
      'Maîtrisez vos dépenses mensuelles et faites des économies.';

  @override
  String get introTitle4 => 'Alertes Intelligentes';

  @override
  String get introDesc4 =>
      'Soyez notifié avant la rupture de stock de vos produits.';

  @override
  String get introSkip => 'Passer';

  @override
  String get introNext => 'Suivant';

  @override
  String get introStart => 'Commencer';

  @override
  String get dashboardAddProductHint => 'Commencez ici !';
}
