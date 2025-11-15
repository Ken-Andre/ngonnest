/// Utility class for handling ID operations
/// Note: UUID conversion utilities have been removed after UUID migration completion
class IdUtils {
  /// Convert any ID type to string for consistent handling
  static String? toStringId(dynamic id) {
    if (id == null) return null;
    if (id is String) return id;
    if (id is int) return id.toString();
    return id.toString();
  }

  /// Convert string ID to int if possible, otherwise return null
  static int? toIntId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) {
      return int.tryParse(id);
    }
    return null;
  }

  /// Safely convert numeric values from database (handles both int and double)
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely convert to int from various types
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely convert to bool from various types
  static bool? toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }
}
