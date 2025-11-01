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

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccess;

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
