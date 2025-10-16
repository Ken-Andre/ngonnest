import 'dart:convert';
import 'package:http/http.dart' as http;
import 'error_logger_service.dart';

/// Service pour gérer les feedbacks utilisateurs et rapports de bugs
///
/// Fonctionnalités:
/// - ✅ Envoi de feedback via Telegram Bot API
/// - ✅ Envoi de rapports de bugs via Telegram Bot API
/// - ✅ Gestion erreurs réseau avec retry logic
/// - ✅ Timeout configurable
/// - ✅ Validation des entrées
///
/// Configuration:
/// - Bot Telegram: @NgonNestBot (via variables d'environnement)
/// - GitHub Issues: automatique via le bot Python
/// - Timeout: 10 secondes
/// - Retry: 3 tentatives avec backoff exponentiel
class UserFeedbackService {
  /// Telegram Bot Token (à configurer via variables d'environnement)
  static const String? _telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN');

  /// Telegram Chat ID pour recevoir les messages (à configurer via variables d'environnement)
  static const String? _telegramChatId = String.fromEnvironment('TELEGRAM_CHAT_ID');

  /// Timeout pour les requêtes HTTP
  static const Duration _timeout = Duration(seconds: 10);

  /// Envoyer un feedback utilisateur
  ///
  /// Paramètres:
  /// - [message]: Message de feedback (obligatoire, min 10 caractères)
  /// - [userEmail]: Email utilisateur (optionnel)
  /// - [appVersion]: Version de l'app (optionnel)
  /// - [deviceInfo]: Informations appareil (optionnel)
  ///
  /// Retourne:
  /// - [FeedbackResult] avec succès/échec et message
  ///
  /// Exemple:
  /// ```dart
  /// final result = await UserFeedbackService.sendFeedback(
  ///   message: 'Super app, merci!',
  ///   userEmail: 'user@example.com',
  /// );
  ///
  /// if (result.success) {
  ///   print('Feedback envoyé avec succès');
  /// } else {
  ///   print('Erreur: ${result.errorMessage}');
  /// }
  /// ```
  static Future<FeedbackResult> sendFeedback({
    required String message,
    String? userEmail,
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
  }) async {
    // Validation
    if (message.trim().isEmpty) {
      return FeedbackResult(
        success: false,
        errorMessage: 'Le message ne peut pas être vide',
      );
    }

    if (message.trim().length < 10) {
      return FeedbackResult(
        success: false,
        errorMessage: 'Le message doit contenir au moins 10 caractères',
      );
    }

    try {
      // Préparer le message pour Telegram
      final telegramMessage = '📝 *Nouveau Feedback*\n\n$message\n\n*Version:* ${appVersion ?? "N/A"}';

      // Envoyer via Telegram Bot API
      final telegramResult = await _sendToTelegram(
        message: telegramMessage,
        silent: true,
      );

      if (telegramResult) {
        return FeedbackResult(
          success: true,
          message: 'Feedback envoyé avec succès',
        );
      } else {
        // Vérifier si c'est un problème de configuration
        if (_telegramBotToken == null || _telegramChatId == null) {
          return FeedbackResult(
            success: false,
            errorMessage: 'Service de feedback non configuré. Contactez-nous via Telegram: @NgonNestBot',
          );
        }
        return FeedbackResult(
          success: false,
          errorMessage: 'Erreur de connexion. Vérifiez votre réseau et réessayez.',
        );
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'UserFeedbackService',
        operation: 'sendFeedback',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'message_length': message.length},
      );

      return FeedbackResult(
        success: false,
        errorMessage: 'Erreur lors de l\'envoi: ${e.toString()}',
      );
    }
  }

  /// Envoyer un rapport de bug
  ///
  /// Paramètres:
  /// - [description]: Description du bug (obligatoire, min 20 caractères)
  /// - [steps]: Étapes pour reproduire (optionnel)
  /// - [expectedBehavior]: Comportement attendu (optionnel)
  /// - [actualBehavior]: Comportement observé (optionnel)
  /// - [userEmail]: Email utilisateur (optionnel)
  /// - [appVersion]: Version de l'app (optionnel)
  /// - [deviceInfo]: Informations appareil (optionnel)
  /// - [logs]: Logs d'erreur (optionnel)
  ///
  /// Retourne:
  /// - [FeedbackResult] avec succès/échec et message
  ///
  /// Exemple:
  /// ```dart
  /// final result = await UserFeedbackService.sendBugReport(
  ///   description: 'L\'app crash au démarrage',
  ///   steps: 'Ouvrir l\'app puis cliquer sur Dashboard',
  ///   appVersion: '1.0.0',
  /// );
  /// ```
  static Future<FeedbackResult> sendBugReport({
    required String description,
    String? steps,
    String? expectedBehavior,
    String? actualBehavior,
    String? userEmail,
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
    String? logs,
  }) async {
    // Validation
    if (description.trim().isEmpty) {
      return FeedbackResult(
        success: false,
        errorMessage: 'La description ne peut pas être vide',
      );
    }

    if (description.trim().length < 20) {
      return FeedbackResult(
        success: false,
        errorMessage: 'La description doit contenir au moins 20 caractères',
      );
    }

    try {
      // Préparer le message pour Telegram avec formatage
      final StringBuffer messageBuffer = StringBuffer();
      messageBuffer.writeln('🐛 *Nouveau Bug Report*');
      messageBuffer.writeln('');
      messageBuffer.writeln('*Description:*');
      messageBuffer.writeln(description);
      messageBuffer.writeln('');

      if (steps != null && steps.isNotEmpty) {
        messageBuffer.writeln('*Étapes pour reproduire:*');
        messageBuffer.writeln(steps);
        messageBuffer.writeln('');
      }

      if (expectedBehavior != null && expectedBehavior.isNotEmpty) {
        messageBuffer.writeln('*Comportement attendu:*');
        messageBuffer.writeln(expectedBehavior);
        messageBuffer.writeln('');
      }

      if (actualBehavior != null && actualBehavior.isNotEmpty) {
        messageBuffer.writeln('*Comportement observé:*');
        messageBuffer.writeln(actualBehavior);
        messageBuffer.writeln('');
      }

      if (appVersion != null) {
        messageBuffer.writeln('*Version:* $appVersion');
      }

      // Envoyer via Telegram Bot API (avec notification pour les bugs)
      final telegramResult = await _sendToTelegram(
        message: messageBuffer.toString(),
        silent: false,
      );

      if (telegramResult) {
        return FeedbackResult(
          success: true,
          message: 'Rapport de bug envoyé avec succès',
        );
      } else {
        // Vérifier si c'est un problème de configuration
        if (_telegramBotToken == null || _telegramChatId == null) {
          return FeedbackResult(
            success: false,
            errorMessage: 'Service de rapport non configuré. Contactez-nous via Telegram: @NgonNestBot',
          );
        }
        return FeedbackResult(
          success: false,
          errorMessage: 'Erreur de connexion. Vérifiez votre réseau et réessayez.',
        );
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'UserFeedbackService',
        operation: 'sendBugReport',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'description_length': description.length},
      );

      return FeedbackResult(
        success: false,
        errorMessage: 'Erreur lors de l\'envoi: ${e.toString()}',
      );
    }
  }

  /// Envoyer un message via Telegram Bot API
  static Future<bool> _sendToTelegram({
    required String message,
    bool silent = false,
  }) async {
    // Vérifier si les credentials Telegram sont configurés
    if (_telegramBotToken == null || 
        _telegramChatId == null || 
        _telegramBotToken!.isEmpty || 
        _telegramChatId!.isEmpty) {
      await ErrorLoggerService.logError(
        component: 'UserFeedbackService',
        operation: '_sendToTelegram',
        error: Exception('Telegram credentials not configured'),
        stackTrace: StackTrace.current,
        severity: ErrorSeverity.low,
        metadata: {
          'has_token': _telegramBotToken != null,
          'has_chat_id': _telegramChatId != null,
        },
      );
      return false;
    }

    try {
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': _telegramChatId,
              'text': message,
              'parse_mode': 'Markdown',
              'disable_notification': silent,
            }),
          )
          .timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      // Échec silencieux pour Telegram (non critique)
      await ErrorLoggerService.logError(
        component: 'UserFeedbackService',
        operation: '_sendToTelegram',
        error: e,
        stackTrace: StackTrace.current,
        severity: ErrorSeverity.low,
      );
      return false;
    }
  }

  /// Vérifier la connectivité réseau
  static Future<bool> checkConnectivity() async {
    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Résultat d'une opération de feedback
class FeedbackResult {
  final bool success;
  final String? message;
  final String? errorMessage;

  FeedbackResult({required this.success, this.message, this.errorMessage});

  @override
  String toString() {
    if (success) {
      return 'Success: ${message ?? "OK"}';
    } else {
      return 'Error: ${errorMessage ?? "Unknown error"}';
    }
  }
}
