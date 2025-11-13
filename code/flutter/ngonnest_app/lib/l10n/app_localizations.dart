import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'NgonNest'**
  String get appTitle;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Inventory screen title
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// Budget screen title
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Enable notifications setting
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnabled;

  /// Disable notifications setting
  ///
  /// In en, this message translates to:
  /// **'Disable notifications'**
  String get notificationsDisabled;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme mode
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// Dark theme mode
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// System theme mode
  ///
  /// In en, this message translates to:
  /// **'System mode'**
  String get systemMode;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Settings saved confirmation message
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// Message when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. You can enable it in system settings.'**
  String get notificationPermissionDenied;

  /// Button to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open System Settings'**
  String get openSystemSettings;

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'Intelligent household management'**
  String get intelligentHouseholdManagement;

  /// No description provided for @languageOfApp.
  ///
  /// In en, this message translates to:
  /// **'Application language'**
  String get languageOfApp;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choosePreferredLanguage;

  /// No description provided for @selectToChangeInterface.
  ///
  /// In en, this message translates to:
  /// **'Select to change the interface'**
  String get selectToChangeInterface;

  /// No description provided for @receiveAppAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive app alerts'**
  String get receiveAppAlerts;

  /// No description provided for @enableRemindersForLowStock.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders for low stock'**
  String get enableRemindersForLowStock;

  /// No description provided for @notificationFrequency.
  ///
  /// In en, this message translates to:
  /// **'Notification frequency'**
  String get notificationFrequency;

  /// No description provided for @chooseReminderFrequency.
  ///
  /// In en, this message translates to:
  /// **'Choose reminder frequency'**
  String get chooseReminderFrequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @localDataOnly.
  ///
  /// In en, this message translates to:
  /// **'Local data only'**
  String get localDataOnly;

  /// No description provided for @noSyncWithoutExplicitConsent.
  ///
  /// In en, this message translates to:
  /// **'No sync without explicit consent'**
  String get noSyncWithoutExplicitConsent;

  /// No description provided for @changeAppAppearance.
  ///
  /// In en, this message translates to:
  /// **'Change app appearance'**
  String get changeAppAppearance;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @shareYourSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Share your suggestions'**
  String get shareYourSuggestions;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report bug'**
  String get reportBug;

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get describeProblem;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @backupDataLocally.
  ///
  /// In en, this message translates to:
  /// **'Backup data locally'**
  String get backupDataLocally;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @restoreFromBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file'**
  String get restoreFromBackupFile;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @cloudImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud data found'**
  String get cloudImportTitle;

  /// No description provided for @cloudImportMessage.
  ///
  /// In en, this message translates to:
  /// **'We found existing data in your cloud account. What would you like to do?'**
  String get cloudImportMessage;

  /// No description provided for @importOption.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importOption;

  /// No description provided for @importOptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Replace local data with cloud data'**
  String get importOptionDescription;

  /// No description provided for @mergeOption.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeOption;

  /// No description provided for @mergeOptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine local and cloud data'**
  String get mergeOptionDescription;

  /// No description provided for @skipOption.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipOption;

  /// No description provided for @skipOptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep only local data'**
  String get skipOptionDescription;

  /// No description provided for @importInProgress.
  ///
  /// In en, this message translates to:
  /// **'Import in progress...'**
  String get importInProgress;

  /// No description provided for @importingHouseholds.
  ///
  /// In en, this message translates to:
  /// **'Importing households...'**
  String get importingHouseholds;

  /// No description provided for @importingProducts.
  ///
  /// In en, this message translates to:
  /// **'Importing products...'**
  String get importingProducts;

  /// No description provided for @importingBudgets.
  ///
  /// In en, this message translates to:
  /// **'Importing budgets...'**
  String get importingBudgets;

  /// No description provided for @importingPurchases.
  ///
  /// In en, this message translates to:
  /// **'Importing purchases...'**
  String get importingPurchases;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccess;

  /// No description provided for @importSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data has been imported successfully'**
  String get importSuccessMessage;

  /// No description provided for @importPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import partially successful'**
  String get importPartialSuccess;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @entitiesImported.
  ///
  /// In en, this message translates to:
  /// **'{count} items imported'**
  String entitiesImported(Object count);

  /// No description provided for @householdsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} households'**
  String householdsImported(Object count);

  /// No description provided for @productsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsImported(Object count);

  /// No description provided for @budgetsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} budgets'**
  String budgetsImported(Object count);

  /// No description provided for @purchasesImported.
  ///
  /// In en, this message translates to:
  /// **'{count} purchases'**
  String purchasesImported(Object count);

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @completeResetIrreversible.
  ///
  /// In en, this message translates to:
  /// **'Complete reset - Irreversible action'**
  String get completeResetIrreversible;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @languageChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedSuccessfully;

  /// No description provided for @errorActivatingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error activating notifications'**
  String get errorActivatingNotifications;

  /// No description provided for @cloudSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization'**
  String get cloudSynchronization;

  /// No description provided for @cloudSyncAllowsOnlineBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud synchronization allows backing up your data online. Do you accept this functionality?'**
  String get cloudSyncAllowsOnlineBackup;

  /// No description provided for @acceptCloudSync.
  ///
  /// In en, this message translates to:
  /// **'I accept cloud synchronization'**
  String get acceptCloudSync;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @syncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Synchronization enabled'**
  String get syncEnabled;

  /// No description provided for @cloudSyncActivated.
  ///
  /// In en, this message translates to:
  /// **'Cloud synchronization has been activated. Your data will be automatically backed up.'**
  String get cloudSyncActivated;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedbackTitle;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'We would like to know your opinion about the application.'**
  String get feedbackMessage;

  /// No description provided for @typeMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Type your message here...'**
  String get typeMessageHere;

  /// No description provided for @reportBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Report bug'**
  String get reportBugTitle;

  /// No description provided for @bugReportWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'Your report will be sent to our development team.'**
  String get bugReportWillBeSent;

  /// No description provided for @continueContactTelegram.
  ///
  /// In en, this message translates to:
  /// **'To continue contacting us, join our Telegram bot:'**
  String get continueContactTelegram;

  /// No description provided for @telegramLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Telegram link copied!'**
  String get telegramLinkCopied;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent'**
  String get feedbackSent;

  /// No description provided for @feedbackSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been sent successfully.'**
  String get feedbackSentSuccessfully;

  /// No description provided for @bugReportSent.
  ///
  /// In en, this message translates to:
  /// **'Bug report sent'**
  String get bugReportSent;

  /// No description provided for @bugReportSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your bug report has been sent successfully.'**
  String get bugReportSentSuccessfully;

  /// No description provided for @deleteAllDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataConfirmation;

  /// No description provided for @deleteAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all your inventory, budget and settings data. This action cannot be undone.'**
  String get deleteAllDataWarning;

  /// No description provided for @dataDeleted.
  ///
  /// In en, this message translates to:
  /// **'Data deleted'**
  String get dataDeleted;

  /// No description provided for @allDataDeletedRestart.
  ///
  /// In en, this message translates to:
  /// **'All your data has been deleted.\\nThe application will restart.'**
  String get allDataDeletedRestart;

  /// No description provided for @exportDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Export all your data to a JSON file?'**
  String get exportDataConfirm;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get exportSuccess;

  /// No description provided for @importDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This operation will replace your current data. Continue?'**
  String get importDataConfirm;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to export data'**
  String get storagePermissionRequired;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied. Please grant access in system settings'**
  String get storagePermissionDenied;

  /// No description provided for @storagePermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission permanently denied. Please enable it in app settings'**
  String get storagePermissionPermanentlyDenied;

  /// No description provided for @grantStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Storage Permission'**
  String get grantStoragePermission;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get requestTimedOut;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please verify your internet connection.'**
  String get networkError;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @useYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Use your email'**
  String get useYourEmail;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Create account'**
  String get noAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short (min 8 characters)'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @pleaseEnterFirstAndLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first and last name'**
  String get pleaseEnterFirstAndLastName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccessfully;

  /// No description provided for @pleaseCheckEmailToConfirmAccount.
  ///
  /// In en, this message translates to:
  /// **'Please check your email to confirm your account.'**
  String get pleaseCheckEmailToConfirmAccount;

  /// No description provided for @signInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Sign in successful!'**
  String get signInSuccessful;

  /// No description provided for @googleSignInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Google sign in successful!'**
  String get googleSignInSuccessful;

  /// No description provided for @appleSignInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Apple sign in successful!'**
  String get appleSignInSuccessful;

  /// No description provided for @checkYourEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account.'**
  String get checkYourEmailToConfirm;

  /// No description provided for @emailConfirmedYouCanSignIn.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed. You can now sign in.'**
  String get emailConfirmedYouCanSignIn;

  /// No description provided for @resendConfirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get resendConfirmationEmail;

  /// No description provided for @confirmationEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email resent.'**
  String get confirmationEmailResent;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @connectQuicklyWithExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect quickly with your existing account'**
  String get connectQuicklyWithExistingAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @socialNetworks.
  ///
  /// In en, this message translates to:
  /// **'Social networks'**
  String get socialNetworks;

  /// No description provided for @syncDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to synchronize your data?'**
  String get syncDataQuestion;

  /// No description provided for @syncDataExplanation.
  ///
  /// In en, this message translates to:
  /// **'Cloud synchronization allows you to backup your data online and access it from all your devices.'**
  String get syncDataExplanation;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @noLater.
  ///
  /// In en, this message translates to:
  /// **'No, later'**
  String get noLater;

  /// No description provided for @syncLaterMessage.
  ///
  /// In en, this message translates to:
  /// **'You can enable synchronization later in settings'**
  String get syncLaterMessage;

  /// No description provided for @synchronization.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get synchronization;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;

  /// No description provided for @syncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get syncDisabled;

  /// No description provided for @syncEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get syncEnabledStatus;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'✓ Synchronized'**
  String get syncUpToDate;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'⏳ Pending ({count} operations)'**
  String syncPending(Object count);

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'🔄 Synchronizing...'**
  String get syncInProgress;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Sync error'**
  String get syncError;

  /// No description provided for @lastSyncTime.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncTime(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synchronized'**
  String get neverSynced;

  /// No description provided for @tapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get tapForDetails;

  /// No description provided for @connectToEnableSync.
  ///
  /// In en, this message translates to:
  /// **'Connect to enable synchronization'**
  String get connectToEnableSync;

  /// No description provided for @syncStatusDetails.
  ///
  /// In en, this message translates to:
  /// **'Synchronization details'**
  String get syncStatusDetails;

  /// No description provided for @pendingOperations.
  ///
  /// In en, this message translates to:
  /// **'Pending operations'**
  String get pendingOperations;

  /// No description provided for @failedOperations.
  ///
  /// In en, this message translates to:
  /// **'Failed operations'**
  String get failedOperations;

  /// No description provided for @syncHistory.
  ///
  /// In en, this message translates to:
  /// **'Sync history'**
  String get syncHistory;

  /// No description provided for @enableCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Enable cloud sync'**
  String get enableCloudSync;

  /// No description provided for @disableCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Disable cloud sync'**
  String get disableCloudSync;

  /// No description provided for @keepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep local'**
  String get keepLocal;

  /// No description provided for @keepLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload local data to cloud'**
  String get keepLocalDescription;

  /// No description provided for @importFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Import from cloud'**
  String get importFromCloud;

  /// No description provided for @importFromCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Download data from cloud'**
  String get importFromCloudDescription;

  /// No description provided for @mergeData.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeData;

  /// No description provided for @mergeDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine local and cloud data'**
  String get mergeDataDescription;

  /// No description provided for @syncSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Synchronization enabled successfully'**
  String get syncSuccessMessage;

  /// No description provided for @importOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import options'**
  String get importOptionsTitle;

  /// No description provided for @chooseImportOption.
  ///
  /// In en, this message translates to:
  /// **'Choose how to handle your existing data'**
  String get chooseImportOption;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
