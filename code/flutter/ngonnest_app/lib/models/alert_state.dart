/// Model representing the state of an alert (read/resolved status)
class AlertState {
  final int alertId;
  final bool isRead;
  final bool isResolved;
  final DateTime updatedAt;

  const AlertState({
    required this.alertId,
    required this.isRead,
    required this.isResolved,
    required this.updatedAt,
  });

  /// Create a copy of this AlertState with specified attributes overridden
  AlertState copyWith({
    int? alertId,
    bool? isRead,
    bool? isResolved,
    DateTime? updatedAt,
  }) {
    return AlertState(
      alertId: alertId ?? this.alertId,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert AlertState to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'alert_id': alertId,
      'is_read': isRead ? 1 : 0,
      'is_resolved': isResolved ? 1 : 0,
      'last_updated': updatedAt.toIso8601String(),
    };
  }

  /// Create AlertState from a database map
  factory AlertState.fromMap(Map<String, dynamic> map) {
    return AlertState(
      alertId: map['alert_id'],
      isRead: map['is_read'] == 1,
      isResolved: map['is_resolved'] == 1,
      updatedAt: DateTime.parse(map['last_updated']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertState &&
        other.alertId == alertId &&
        other.isRead == isRead &&
        other.isResolved == isResolved &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(alertId, isRead, isResolved, updatedAt);
  }

  @override
  String toString() {
    return 'AlertState(alertId: $alertId, isRead: $isRead, isResolved: $isResolved, updatedAt: $updatedAt)';
  }
}