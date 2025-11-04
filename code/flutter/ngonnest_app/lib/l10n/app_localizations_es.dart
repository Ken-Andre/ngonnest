// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NgonNest';

  @override
  String get dashboard => 'Panel de control';

  @override
  String get inventory => 'Inventario';

  @override
  String get budget => 'Presupuesto';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsEnabled => 'Activar notificaciones';

  @override
  String get notificationsDisabled => 'Desactivar notificaciones';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get systemMode => 'Modo del sistema';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get settingsSaved => 'Configuración guardada con éxito';

  @override
  String get notificationPermissionDenied =>
      'Permiso de notificación denegado. Puedes activarlo en la configuración del sistema.';

  @override
  String get openSystemSettings => 'Abrir configuración del sistema';

  @override
  String get intelligentHouseholdManagement => 'Gestión inteligente del hogar';

  @override
  String get languageOfApp => 'Idioma de la aplicación';

  @override
  String get choosePreferredLanguage => 'Elige tu idioma preferido';

  @override
  String get selectToChangeInterface => 'Selecciona para cambiar la interfaz';

  @override
  String get receiveAppAlerts => 'Recibir alertas en la app';

  @override
  String get enableRemindersForLowStock =>
      'Activar recordatorios para stock bajo';

  @override
  String get notificationFrequency => 'Frecuencia de notificaciones';

  @override
  String get chooseReminderFrequency =>
      'Elige la frecuencia de los recordatorios';

  @override
  String get daily => 'Diaria';

  @override
  String get weekly => 'Semanal';

  @override
  String get privacy => 'Privacidad';

  @override
  String get localDataOnly => 'Solo datos locales';

  @override
  String get noSyncWithoutExplicitConsent =>
      'Sin sincronización sin consentimiento explícito';

  @override
  String get changeAppAppearance => 'Cambiar la apariencia de la aplicación';

  @override
  String get support => 'Soporte';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get shareYourSuggestions => 'Comparte tus sugerencias';

  @override
  String get send => 'Enviar';

  @override
  String get reportBug => 'Reportar error';

  @override
  String get describeProblem => 'Describe el problema';

  @override
  String get report => 'Reportar';

  @override
  String get data => 'Datos';

  @override
  String get exportData => 'Exportar datos';

  @override
  String get backupDataLocally => 'Respaldar datos localmente';

  @override
  String get export => 'Exportar';

  @override
  String get importData => 'Importar datos';

  @override
  String get restoreFromBackupFile => 'Restaurar desde archivo de respaldo';

  @override
  String get import => 'Importar';

  @override
  String get cloudImportTitle => 'Datos encontrados en la nube';

  @override
  String get cloudImportMessage =>
      'Encontramos datos existentes en tu cuenta de la nube. ¿Qué te gustaría hacer?';

  @override
  String get importOption => 'Importar';

  @override
  String get importOptionDescription =>
      'Reemplazar datos locales con datos de la nube';

  @override
  String get mergeOption => 'Fusionar';

  @override
  String get mergeOptionDescription => 'Combinar datos locales y de la nube';

  @override
  String get skipOption => 'Omitir';

  @override
  String get skipOptionDescription => 'Mantener solo datos locales';

  @override
  String get importInProgress => 'Importación en progreso...';

  @override
  String get importingHouseholds => 'Importando hogares...';

  @override
  String get importingProducts => 'Importando productos...';

  @override
  String get importingBudgets => 'Importando presupuestos...';

  @override
  String get importingPurchases => 'Importando compras...';

  @override
  String get importSuccess => 'Importación exitosa';

  @override
  String get importSuccessMessage =>
      'Tus datos han sido importados exitosamente';

  @override
  String get importPartialSuccess => 'Importación parcialmente exitosa';

  @override
  String get importError => 'Error de importación';

  @override
  String get retry => 'Reintentar';

  @override
  String entitiesImported(Object count) {
    return '$count elementos importados';
  }

  @override
  String householdsImported(Object count) {
    return '$count hogares';
  }

  @override
  String productsImported(Object count) {
    return '$count productos';
  }

  @override
  String budgetsImported(Object count) {
    return '$count presupuestos';
  }

  @override
  String purchasesImported(Object count) {
    return '$count compras';
  }

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get completeResetIrreversible =>
      'Reinicio completo - Acción irreversible';

  @override
  String get delete => 'Eliminar';

  @override
  String get languageChangedSuccessfully => 'Idioma cambiado con éxito';

  @override
  String get errorActivatingNotifications =>
      'Error al activar las notificaciones';

  @override
  String get cloudSynchronization => 'Sincronización en la nube';

  @override
  String get cloudSyncAllowsOnlineBackup =>
      'La sincronización en la nube permite respaldar tus datos en línea. ¿Aceptas esta funcionalidad?';

  @override
  String get acceptCloudSync => 'Acepto la sincronización en la nube';

  @override
  String get accept => 'Aceptar';

  @override
  String get syncEnabled => 'Sincronización activada';

  @override
  String get cloudSyncActivated =>
      'La sincronización en la nube ha sido activada. Tus datos se respaldarán automáticamente.';

  @override
  String get sendFeedbackTitle => 'Enviar comentarios';

  @override
  String get feedbackMessage =>
      'Nos gustaría conocer tu opinión sobre la aplicación.';

  @override
  String get typeMessageHere => 'Escribe tu mensaje aquí...';

  @override
  String get reportBugTitle => 'Reportar error';

  @override
  String get bugReportWillBeSent =>
      'Tu reporte será enviado a nuestro equipo de desarrollo.';

  @override
  String get continueContactTelegram =>
      'Para continuar contactándonos, únete a nuestro bot de Telegram:';

  @override
  String get telegramLinkCopied => '¡Enlace de Telegram copiado!';

  @override
  String get feedbackSent => 'Comentarios enviados';

  @override
  String get feedbackSentSuccessfully =>
      'Tus comentarios han sido enviados con éxito.';

  @override
  String get bugReportSent => 'Reporte de error enviado';

  @override
  String get bugReportSentSuccessfully =>
      'Tu reporte de error ha sido enviado con éxito.';

  @override
  String get deleteAllDataConfirmation => '¿Eliminar todos los datos?';

  @override
  String get deleteAllDataWarning =>
      'Esta acción eliminará permanentemente todos tus datos de inventario, presupuesto y configuración. Esta acción no se puede deshacer.';

  @override
  String get dataDeleted => 'Datos eliminados';

  @override
  String get allDataDeletedRestart =>
      'Todos tus datos han sido eliminados.\\nLa aplicación se reiniciará.';

  @override
  String get exportDataConfirm =>
      '¿Exportar todos tus datos a un archivo JSON?';

  @override
  String get exportSuccess => 'Datos exportados con éxito';

  @override
  String get importDataConfirm =>
      'Esta operación reemplazará tus datos actuales. ¿Continuar?';

  @override
  String get storagePermissionRequired =>
      'Se requiere permiso de almacenamiento para exportar datos';

  @override
  String get storagePermissionDenied =>
      'Permiso de almacenamiento denegado. Por favor concede acceso en configuración del sistema';

  @override
  String get storagePermissionPermanentlyDenied =>
      'Permiso de almacenamiento permanentemente denegado. Por favor actívalo en configuración de la aplicación';

  @override
  String get grantStoragePermission => 'Conceder permiso de almacenamiento';

  @override
  String get requestTimedOut => 'Tiempo de espera agotado';

  @override
  String get networkError =>
      'Error de red. Por favor verifica tu conexión a internet.';

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
  String get passwordTooShort => 'Password too short (min 6 characters)';

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
  String get signInSuccessful => 'Sign in successful!';

  @override
  String get googleSignInSuccessful => 'Google sign in successful!';

  @override
  String get appleSignInSuccessful => 'Apple sign in successful!';

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
  String get synchronization => 'Sincronización';

  @override
  String get syncStatus => 'Estado de sincronización';

  @override
  String get syncDisabled => 'Desactivada';

  @override
  String get syncEnabledStatus => 'Activada';

  @override
  String get syncUpToDate => '✓ Sincronizado';

  @override
  String syncPending(Object count) {
    return '⏳ Pendiente ($count operaciones)';
  }

  @override
  String get syncInProgress => '🔄 Sincronizando...';

  @override
  String get syncError => '⚠️ Error de sincronización';

  @override
  String lastSyncTime(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get neverSynced => 'Nunca sincronizado';

  @override
  String get tapForDetails => 'Toca para detalles';

  @override
  String get connectToEnableSync => 'Conéctate para activar la sincronización';

  @override
  String get syncStatusDetails => 'Detalles de sincronización';

  @override
  String get pendingOperations => 'Operaciones pendientes';

  @override
  String get failedOperations => 'Operaciones fallidas';

  @override
  String get syncHistory => 'Historial de sincronización';

  @override
  String get enableCloudSync => 'Activar sincronización en la nube';

  @override
  String get disableCloudSync => 'Desactivar sincronización en la nube';

  @override
  String get keepLocal => 'Mantener local';

  @override
  String get keepLocalDescription => 'Subir datos locales a la nube';

  @override
  String get importFromCloud => 'Importar de la nube';

  @override
  String get importFromCloudDescription => 'Descargar datos de la nube';

  @override
  String get mergeData => 'Fusionar';

  @override
  String get mergeDataDescription => 'Combinar datos locales y de la nube';

  @override
  String get syncSuccessMessage => 'Sincronización activada exitosamente';

  @override
  String get importOptionsTitle => 'Opciones de importación';

  @override
  String get chooseImportOption => 'Elige cómo manejar tus datos existentes';
}
