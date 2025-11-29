// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NgonNest';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventory';

  @override
  String get budget => 'Budget';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Enable notifications';

  @override
  String get notificationsDisabled => 'Disable notifications';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemMode => 'System mode';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get notificationPermissionDenied =>
      'Notification permission denied. You can enable it in system settings.';

  @override
  String get openSystemSettings => 'Open System Settings';

  @override
  String get intelligentHouseholdManagement =>
      'Intelligent household management';

  @override
  String get languageOfApp => 'Application language';

  @override
  String get choosePreferredLanguage => 'Choose your preferred language';

  @override
  String get selectToChangeInterface => 'Select to change the interface';

  @override
  String get receiveAppAlerts => 'Receive app alerts';

  @override
  String get enableRemindersForLowStock => 'Enable reminders for low stock';

  @override
  String get notificationFrequency => 'Notification frequency';

  @override
  String get chooseReminderFrequency => 'Choose reminder frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get privacy => 'Privacy';

  @override
  String get localDataOnly => 'Local data only';

  @override
  String get noSyncWithoutExplicitConsent => 'No sync without explicit consent';

  @override
  String get changeAppAppearance => 'Change app appearance';

  @override
  String get support => 'Support';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get shareYourSuggestions => 'Share your suggestions';

  @override
  String get send => 'Send';

  @override
  String get reportBug => 'Report bug';

  @override
  String get describeProblem => 'Describe the problem';

  @override
  String get report => 'Report';

  @override
  String get data => 'Data';

  @override
  String get exportData => 'Export data';

  @override
  String get backupDataLocally => 'Backup data locally';

  @override
  String get export => 'Export';

  @override
  String get importData => 'Import data';

  @override
  String get restoreFromBackupFile => 'Restore from backup file';

  @override
  String get import => 'Import';

  @override
  String get cloudImportTitle => 'Cloud data found';

  @override
  String get cloudImportMessage =>
      'We found existing data in your cloud account. What would you like to do?';

  @override
  String get importOption => 'Import';

  @override
  String get importOptionDescription => 'Replace local data with cloud data';

  @override
  String get mergeOption => 'Merge';

  @override
  String get mergeOptionDescription => 'Combine local and cloud data';

  @override
  String get skipOption => 'Skip';

  @override
  String get skipOptionDescription => 'Keep only local data';

  @override
  String get importInProgress => 'Import in progress...';

  @override
  String get importingHouseholds => 'Importing households...';

  @override
  String get importingProducts => 'Importing products...';

  @override
  String get importingBudgets => 'Importing budgets...';

  @override
  String get importingPurchases => 'Importing purchases...';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get importSuccessMessage => 'Your data has been imported successfully';

  @override
  String get importPartialSuccess => 'Import partially successful';

  @override
  String get importError => 'Import error';

  @override
  String get retry => 'Retry';

  @override
  String entitiesImported(Object count) {
    return '$count items imported';
  }

  @override
  String householdsImported(Object count) {
    return '$count households';
  }

  @override
  String productsImported(Object count) {
    return '$count products';
  }

  @override
  String budgetsImported(Object count) {
    return '$count budgets';
  }

  @override
  String purchasesImported(Object count) {
    return '$count purchases';
  }

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get completeResetIrreversible =>
      'Complete reset - Irreversible action';

  @override
  String get delete => 'Delete';

  @override
  String get languageChangedSuccessfully => 'Language changed successfully';

  @override
  String get errorActivatingNotifications => 'Error activating notifications';

  @override
  String get cloudSynchronization => 'Cloud Synchronization';

  @override
  String get cloudSyncAllowsOnlineBackup =>
      'Cloud synchronization allows backing up your data online. Do you accept this functionality?';

  @override
  String get acceptCloudSync => 'I accept cloud synchronization';

  @override
  String get accept => 'Accept';

  @override
  String get syncEnabled => 'Synchronization enabled';

  @override
  String get cloudSyncActivated =>
      'Cloud synchronization has been activated. Your data will be automatically backed up.';

  @override
  String get sendFeedbackTitle => 'Send feedback';

  @override
  String get feedbackMessage =>
      'We would like to know your opinion about the application.';

  @override
  String get typeMessageHere => 'Type your message here...';

  @override
  String get reportBugTitle => 'Report bug';

  @override
  String get bugReportWillBeSent =>
      'Your report will be sent to our development team.';

  @override
  String get continueContactTelegram =>
      'To continue contacting us, join our Telegram bot:';

  @override
  String get telegramLinkCopied => 'Telegram link copied!';

  @override
  String get feedbackSent => 'Feedback sent';

  @override
  String get feedbackSentSuccessfully =>
      'Your feedback has been sent successfully.';

  @override
  String get bugReportSent => 'Bug report sent';

  @override
  String get bugReportSentSuccessfully =>
      'Your bug report has been sent successfully.';

  @override
  String get deleteAllDataConfirmation => 'Delete all data?';

  @override
  String get deleteAllDataWarning =>
      'This action will permanently delete all your inventory, budget and settings data. This action cannot be undone.';

  @override
  String get dataDeleted => 'Data deleted';

  @override
  String get allDataDeletedRestart =>
      'All your data has been deleted.\\nThe application will restart.';

  @override
  String get exportDataConfirm => 'Export all your data to a JSON file?';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String get importDataConfirm =>
      'This operation will replace your current data. Continue?';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to export data';

  @override
  String get storagePermissionDenied =>
      'Storage permission denied. Please grant access in system settings';

  @override
  String get storagePermissionPermanentlyDenied =>
      'Storage permission permanently denied. Please enable it in app settings';

  @override
  String get grantStoragePermission => 'Grant Storage Permission';

  @override
  String get requestTimedOut => 'Request timed out';

  @override
  String get networkError =>
      'Network error. Please verify your internet connection.';

  @override
  String get welcome => 'Welcome!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get fullName => 'Full name';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get useYourEmail => 'Use your email';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'No account? Create account';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'Password too short (min 8 characters)';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseEnterFullName => 'Please enter your full name';

  @override
  String get pleaseEnterFirstAndLastName =>
      'Please enter your first and last name';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get accountCreatedSuccessfully => 'Account created successfully!';

  @override
  String get pleaseCheckEmailToConfirmAccount =>
      'Please check your email to confirm your account.';

  @override
  String get signInSuccessful => 'Sign in successful!';

  @override
  String get googleSignInSuccessful => 'Google sign in successful!';

  @override
  String get appleSignInSuccessful => 'Apple sign in successful!';

  @override
  String get checkYourEmailToConfirm =>
      'Check your email to confirm your account.';

  @override
  String get emailConfirmedYouCanSignIn =>
      'Email confirmed. You can now sign in.';

  @override
  String get resendConfirmationEmail => 'Resend confirmation email';

  @override
  String get confirmationEmailResent => 'Confirmation email resent.';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get connectQuicklyWithExistingAccount =>
      'Connect quickly with your existing account';

  @override
  String get or => 'or';

  @override
  String get socialNetworks => 'Social networks';

  @override
  String get syncDataQuestion => 'Do you want to synchronize your data?';

  @override
  String get syncDataExplanation =>
      'Cloud synchronization allows you to backup your data online and access it from all your devices.';

  @override
  String get yes => 'Yes';

  @override
  String get noLater => 'No, later';

  @override
  String get syncLaterMessage =>
      'You can enable synchronization later in settings';

  @override
  String get synchronization => 'Synchronization';

  @override
  String get syncStatus => 'Sync status';

  @override
  String get syncDisabled => 'Disabled';

  @override
  String get syncEnabledStatus => 'Enabled';

  @override
  String get syncUpToDate => '✓ Synchronized';

  @override
  String syncPending(Object count) {
    return '⏳ Pending ($count operations)';
  }

  @override
  String get syncInProgress => '🔄 Synchronizing...';

  @override
  String get syncError => '⚠️ Sync error';

  @override
  String lastSyncTime(String time) {
    return 'Last sync: $time';
  }

  @override
  String get neverSynced => 'Never synchronized';

  @override
  String get tapForDetails => 'Tap for details';

  @override
  String get connectToEnableSync => 'Connect to enable synchronization';

  @override
  String get syncStatusDetails => 'Synchronization details';

  @override
  String get pendingOperations => 'Pending operations';

  @override
  String get failedOperations => 'Failed operations';

  @override
  String get syncHistory => 'Sync history';

  @override
  String get enableCloudSync => 'Enable cloud sync';

  @override
  String get disableCloudSync => 'Disable cloud sync';

  @override
  String get keepLocal => 'Keep local';

  @override
  String get keepLocalDescription => 'Upload local data to cloud';

  @override
  String get importFromCloud => 'Import from cloud';

  @override
  String get importFromCloudDescription => 'Download data from cloud';

  @override
  String get mergeData => 'Merge';

  @override
  String get mergeDataDescription => 'Combine local and cloud data';

  @override
  String get syncSuccessMessage => 'Synchronization enabled successfully';

  @override
  String get importOptionsTitle => 'Import options';

  @override
  String get chooseImportOption => 'Choose how to handle your existing data';

  @override
  String get monthlyBudget => 'Monthly budget';

  @override
  String get editMonthlyBudget => 'Edit monthly budget';

  @override
  String get enterBudgetAmount => 'Enter your monthly budget amount';

  @override
  String get notSet => 'Not set';

  @override
  String get edit => 'Edit';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get budgetOutOfRange => 'Budget must be between €50 and €2000';

  @override
  String get budgetUpdatedSuccessfully => 'Budget updated successfully';

  @override
  String get errorUpdatingBudget => 'Error updating budget';

  @override
  String get errorDatabaseConnection =>
      'Unable to connect to database. Please try again.';

  @override
  String get errorBudgetCalculation =>
      'Error calculating budget. Using default values.';

  @override
  String get errorSyncFailed =>
      'Synchronization failed. Your data is saved locally.';

  @override
  String get errorNotificationPermission =>
      'Notification permission denied. Enable it in settings.';

  @override
  String get errorMigrationFailed =>
      'Database update failed. App continues with old version.';

  @override
  String get errorValidationBudgetAmount =>
      'Budget amount must be a positive number.';

  @override
  String get errorNetworkUnavailable =>
      'No internet connection. Operating in offline mode.';

  @override
  String get errorLoadingBudgetCategories =>
      'Unable to load budget categories.';

  @override
  String get errorSavingBudgetCategory => 'Error saving category.';

  @override
  String get errorDeletingBudgetCategory => 'Error deleting category.';

  @override
  String get errorRecalculatingBudgets => 'Error recalculating budgets.';

  @override
  String get errorInvalidMonthFormat => 'Invalid month format. Use YYYY-MM.';

  @override
  String get errorMissingFoyerData =>
      'Missing household data. Please complete your profile.';

  @override
  String get errorBudgetNotificationFailed =>
      'Unable to display budget notification.';

  @override
  String get errorSyncRetryExhausted =>
      'Synchronization failed after multiple attempts.';

  @override
  String get warningBudgetCalculationFallback =>
      'Budget calculation failed. Using default values.';

  @override
  String get warningInvalidPercentage =>
      'Invalid percentage detected. Using default value.';

  @override
  String get budgetNotSet => 'Monthly budget not set';

  @override
  String get budgetNotSetMessage =>
      'Please set your monthly budget in settings to start tracking your expenses.';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get updateMonthlyBudget => 'Update monthly budget';

  @override
  String get budgetWillBeRecalculated =>
      'Your budget category limits will be recalculated proportionally.';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get errorLoadingHouseholdData => 'Error loading household data';

  @override
  String get setBudgetInSettings => 'Set your monthly budget';

  @override
  String get modify => 'Modify';

  @override
  String get budgetLoadError =>
      'Unable to load budget data. Check your connection.';

  @override
  String get budgetRetry => 'Retry';

  @override
  String get budgetUpdateError => 'Error updating budget';

  @override
  String get budgetDeleteError => 'Error deleting category';

  @override
  String get introTitle1 => 'Welcome to NgoNest';

  @override
  String get introDesc1 => 'The app that simplifies your household management.';

  @override
  String get introTitle2 => 'Manage your inventory';

  @override
  String get introDesc2 => 'Track your stock and avoid waste easily.';

  @override
  String get introTitle3 => 'Track your budget';

  @override
  String get introDesc3 => 'Master your monthly expenses and save money.';

  @override
  String get introTitle4 => 'Smart Alerts';

  @override
  String get introDesc4 =>
      'Get notified before your products run out of stock.';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Start';

  @override
  String get dashboardAddProductHint => 'Start here!';
}
