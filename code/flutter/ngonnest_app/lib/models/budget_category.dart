class BudgetCategory {
  final int? id;
  final String name;
  final double limit;
  final double spent;
  final String month; // Format: YYYY-MM
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetCategory({
    this.id,
    required this.name,
    required this.limit,
    this.spent = 0.0,
    required this.month,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate spending percentage
  double get spendingPercentage => limit > 0 ? (spent / limit) : 0.0;

  /// Check if budget is exceeded
  bool get isOverBudget => spent > limit;

  /// Check if budget is close to limit (>80%)
  bool get isNearLimit => spendingPercentage >= 0.8;

  /// Get remaining budget
  double get remainingBudget => limit - spent;

  /// Create a copy with updated values
  BudgetCategory copyWith({
    int? id,
    String? name,
    double? limit,
    double? spent,
    String? month,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'limit_amount': limit,
      'spent_amount': spent,
      'month': month,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (database)
  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      limit: (map['limit_amount'] ?? 0.0).toDouble(),
      spent: (map['spent_amount'] ?? 0.0).toDouble(),
      month: map['month'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'BudgetCategory{id: $id, name: $name, limit: $limit, spent: $spent, month: $month}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetCategory &&
        other.id == id &&
        other.name == name &&
        other.limit == limit &&
        other.spent == spent &&
        other.month == month;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        limit.hashCode ^
        spent.hashCode ^
        month.hashCode;
  }
}