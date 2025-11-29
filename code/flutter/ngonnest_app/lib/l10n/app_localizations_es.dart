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
  String get welcome => '¡Bienvenido!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Crear cuenta';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get useYourEmail => 'Usa tu email';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get noAccount => '¿No tienes cuenta? Crear cuenta';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get passwordTooShort =>
      'Contraseña demasiado corta (mín 8 caracteres)';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get pleaseEnterFullName => 'Por favor ingresa tu nombre completo';

  @override
  String get pleaseEnterFirstAndLastName =>
      'Por favor ingresa tu nombre y apellido';

  @override
  String get pleaseEnterEmail => 'Por favor ingresa tu email';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get pleaseConfirmPassword => 'Por favor confirma tu contraseña';

  @override
  String get accountCreatedSuccessfully => '¡Cuenta creada exitosamente!';

  @override
  String get pleaseCheckEmailToConfirmAccount =>
      'Por favor verifica tu email para confirmar tu cuenta.';

  @override
  String get signInSuccessful => '¡Inicio de sesión exitoso!';

  @override
  String get googleSignInSuccessful => '¡Inicio de sesión con Google exitoso!';

  @override
  String get appleSignInSuccessful => '¡Inicio de sesión con Apple exitoso!';

  @override
  String get checkYourEmailToConfirm =>
      'Verifica tu email para confirmar tu cuenta.';

  @override
  String get emailConfirmedYouCanSignIn =>
      'Email confirmado. Ya puedes iniciar sesión.';

  @override
  String get resendConfirmationEmail => 'Reenviar email de confirmación';

  @override
  String get confirmationEmailResent => 'Email de confirmación reenviado.';

  @override
  String resendInSeconds(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get connectQuicklyWithExistingAccount =>
      'Conéctate rápidamente con tu cuenta existente';

  @override
  String get or => 'o';

  @override
  String get socialNetworks => 'Redes sociales';

  @override
  String get syncDataQuestion => '¿Quieres sincronizar tus datos?';

  @override
  String get syncDataExplanation =>
      'La sincronización en la nube te permite respaldar tus datos en línea y accederlos desde todos tus dispositivos.';

  @override
  String get yes => 'Sí';

  @override
  String get noLater => 'No, más tarde';

  @override
  String get syncLaterMessage =>
      'Puedes activar la sincronización más tarde en configuración';

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

  @override
  String get monthlyBudget => 'Presupuesto mensual';

  @override
  String get editMonthlyBudget => 'Editar presupuesto mensual';

  @override
  String get enterBudgetAmount => 'Ingresa el monto de tu presupuesto mensual';

  @override
  String get notSet => 'No definido';

  @override
  String get edit => 'Editar';

  @override
  String get invalidAmount => 'Monto inválido';

  @override
  String get budgetOutOfRange => 'El presupuesto debe estar entre €50 y €2000';

  @override
  String get budgetUpdatedSuccessfully =>
      'Presupuesto actualizado exitosamente';

  @override
  String get errorUpdatingBudget => 'Error al actualizar el presupuesto';

  @override
  String get errorDatabaseConnection =>
      'No se puede conectar a la base de datos. Por favor, inténtelo de nuevo.';

  @override
  String get errorBudgetCalculation =>
      'Error al calcular el presupuesto. Usando valores predeterminados.';

  @override
  String get errorSyncFailed =>
      'La sincronización falló. Sus datos están guardados localmente.';

  @override
  String get errorNotificationPermission =>
      'Permiso de notificación denegado. Actívelo en la configuración.';

  @override
  String get errorMigrationFailed =>
      'Error al actualizar la base de datos. La aplicación continúa con la versión anterior.';

  @override
  String get errorValidationBudgetAmount =>
      'El monto del presupuesto debe ser un número positivo.';

  @override
  String get errorNetworkUnavailable =>
      'Sin conexión a internet. Funcionando en modo sin conexión.';

  @override
  String get errorLoadingBudgetCategories =>
      'No se pueden cargar las categorías de presupuesto.';

  @override
  String get errorSavingBudgetCategory => 'Error al guardar la categoría.';

  @override
  String get errorDeletingBudgetCategory => 'Error al eliminar la categoría.';

  @override
  String get errorRecalculatingBudgets =>
      'Error al recalcular los presupuestos.';

  @override
  String get errorInvalidMonthFormat => 'Formato de mes inválido. Use AAAA-MM.';

  @override
  String get errorMissingFoyerData =>
      'Faltan datos del hogar. Por favor, complete su perfil.';

  @override
  String get errorBudgetNotificationFailed =>
      'No se puede mostrar la notificación de presupuesto.';

  @override
  String get errorSyncRetryExhausted =>
      'Sincronización fallida después de varios intentos.';

  @override
  String get warningBudgetCalculationFallback =>
      'Cálculo de presupuesto fallido. Usando valores predeterminados.';

  @override
  String get warningInvalidPercentage =>
      'Porcentaje inválido detectado. Usando valor predeterminado.';

  @override
  String get budgetNotSet => 'Presupuesto mensual no establecido';

  @override
  String get budgetNotSetMessage =>
      'Por favor, establezca su presupuesto mensual en la configuración para comenzar a rastrear sus gastos.';

  @override
  String get goToSettings => 'Ir a configuración';

  @override
  String get updateMonthlyBudget => 'Actualizar presupuesto mensual';

  @override
  String get budgetWillBeRecalculated =>
      'Los límites de sus categorías de presupuesto se recalcularán proporcionalmente.';

  @override
  String get enterAmount => 'Ingrese el monto';

  @override
  String get pleaseEnterValidAmount => 'Por favor, ingrese un monto válido';

  @override
  String get errorLoadingHouseholdData => 'Error al cargar los datos del hogar';

  @override
  String get setBudgetInSettings => 'Establezca su presupuesto mensual';

  @override
  String get modify => 'Modificar';

  @override
  String get budgetLoadError =>
      'No se pueden cargar los datos del presupuesto. Verifique su conexión.';

  @override
  String get budgetRetry => 'Reintentar';

  @override
  String get budgetUpdateError => 'Error al actualizar el presupuesto';

  @override
  String get budgetDeleteError => 'Error al eliminar la categoría';

  @override
  String get introTitle1 => 'Bienvenido a NgoNest';

  @override
  String get introDesc1 =>
      'La aplicación que simplifica la gestión de tu hogar.';

  @override
  String get introTitle2 => 'Gestiona tu inventario';

  @override
  String get introDesc2 =>
      'Rastrea tu stock y evita el desperdicio fácilmente.';

  @override
  String get introTitle3 => 'Rastrea tu presupuesto';

  @override
  String get introDesc3 => 'Domina tus gastos mensuales y ahorra dinero.';

  @override
  String get introTitle4 => 'Alertas Inteligentes';

  @override
  String get introDesc4 =>
      'Recibe notificaciones antes de que se agoten tus productos.';

  @override
  String get introSkip => 'Omitir';

  @override
  String get introNext => 'Siguiente';

  @override
  String get introStart => 'Comenzar';

  @override
  String get dashboardAddProductHint => '¡Empieza aquí!';
}
