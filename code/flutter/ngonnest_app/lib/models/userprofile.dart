class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? householdId;
  final int? nbPersonnes;
  final int? nbPieces;
  final String? typeLogement;
  final String? langue;
  final double? budgetMensuelEstime;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    required this.updatedAt,
    this.householdId,
    this.nbPersonnes,
    this.nbPieces,
    this.typeLogement,
    this.langue,
    this.budgetMensuelEstime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'household_id': householdId,
      'nb_personnes': nbPersonnes,
      'nb_pieces': nbPieces,
      'type_logement': typeLogement,
      'langue': langue,
      'budget_mensuel_estime': budgetMensuelEstime,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle the actual database schema where we have full_name instead of first_name/last_name
    final fullName = json['full_name'] as String? ?? 'User';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: firstName,
      lastName: lastName,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      householdId: json['household_id'] as String?,
      nbPersonnes: json['nb_personnes'] as int?,
      nbPieces: json['nb_pieces'] as int?,
      typeLogement: json['type_logement'] as String?,
      langue: json['langue'] as String?,
      budgetMensuelEstime: json['budget_mensuel_estime'] as double?,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? householdId,
    int? nbPersonnes,
    int? nbPieces,
    String? typeLogement,
    String? langue,
    double? budgetMensuelEstime,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      householdId: householdId ?? this.householdId,
      nbPersonnes: nbPersonnes ?? this.nbPersonnes,
      nbPieces: nbPieces ?? this.nbPieces,
      typeLogement: typeLogement ?? this.typeLogement,
      langue: langue ?? this.langue,
      budgetMensuelEstime: budgetMensuelEstime ?? this.budgetMensuelEstime,
    );
  }
}
