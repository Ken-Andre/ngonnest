import 'package:flutter/foundation.dart';

/// Logger simple comme en Python/Java - affiche directement dans la console Flutter
class ConsoleLogger {
  static LogMode _logMode = LogMode.debug;

  static void init(LogMode mode) {
    ConsoleLogger._logMode = mode;
  }

  static void log(dynamic data, {StackTrace? stackTrace}) {
    if (_logMode == LogMode.debug) {
      if (stackTrace != null) {
        print("🔴 Error: $data\n$stackTrace");
      } else {
        print("🔴 Error: $data");
      }
    }
  }

  static void info(dynamic data) {
    if (_logMode == LogMode.debug) {
      print("ℹ️  Info: $data");
    }
  }

  static void success(dynamic data) {
    if (_logMode == LogMode.debug) {
      print("✅ Success: $data");
    }
  }

  static void warning(dynamic data) {
    if (_logMode == LogMode.debug) {
      print("⚠️  Warning: $data");
    }
  }

  // Pour les erreurs avec contexte
  static void error(String component, String operation, dynamic error, {StackTrace? stackTrace}) {
    if (_logMode == LogMode.debug) {
      print("🔴 [$component] $operation | Error: $error");
      if (stackTrace != null) {
        print("$stackTrace");
      }
    }
  }

  // Mode actuel
  static LogMode get mode => _logMode;

  // Helper pour les tests
  static void setMode(LogMode mode) {
    _logMode = mode;
  }
}

enum LogMode { debug, production }
