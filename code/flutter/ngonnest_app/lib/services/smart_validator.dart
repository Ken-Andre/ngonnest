
/// Sévérité des erreurs de validation
enum ValidationSeverity {
  info, // Information seulement (aide UX)
  warning, // Avertissement (peut continuer)
  error, // Erreur (doit corriger avant soumission)
  critical, // Erreur critique (bloque complètement)
}

/// Résultat d'une validation intelligente
class ValidationResult {
  final bool isValid;
  final String errorCode;
  final String userMessage;
  final String technicalMessage;
  final ValidationSeverity severity;
  final String field;
  final List<String> suggestions;
  final Map<String, dynamic>? metadata;

  ValidationResult({
    required this.isValid,
    required this.errorCode,
    required this.userMessage,
    required this.technicalMessage,
    required this.severity,
    required this.field,
    this.suggestions = const [],
    this.metadata,
  });

  /// Résultat valide (pas d'erreur)
  static ValidationResult valid() {
    return ValidationResult(
      isValid: true,
      errorCode: 'VAL_000',
      userMessage: '',
      technicalMessage: 'Validation successful',
      severity: ValidationSeverity.info,
      field: '',
      suggestions: [],
    );
  }

  /// Erreur de validation
  static ValidationResult error({
    required String errorCode,
    required String userMessage,
    required String technicalMessage,
    required String field,
    ValidationSeverity severity = ValidationSeverity.error,
    List<String> suggestions = const [],
    Map<String, dynamic>? metadata,
  }) {
    return ValidationResult(
      isValid: false,
      errorCode: errorCode,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      severity: severity,
      field: field,
      suggestions: suggestions,
      metadata: metadata,
    );
  }
}

/// Validateur intelligent pour les formulaires
/// Fournit des messages d'erreur contextuels et des suggestions intelligentes
class SmartValidator {
  // Regex patterns pour validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  static final RegExp _specialCharsRegex = RegExp(r'[<>"/\\|?*\x00-\x1f]');
  static final RegExp _sqlInjectionRegex = RegExp(
    r'(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b)',
    caseSensitive: false,
  );

  /// Valide le nom d'un produit
  static ValidationResult validateProductName(
    String value, {
    String context = '',
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_001',
        userMessage: 'Le nom du produit est requis',
        technicalMessage: 'Empty product name in add_product_screen',
        field: 'product_name',
        severity: ValidationSeverity.error,
        suggestions: [
          'Utilisez un nom descriptif',
          'Évitez les caractères spéciaux',
        ],
        metadata: {'input_length': value.length},
      );
    }

    if (value.trim().length < 2) {
      return ValidationResult.error(
        errorCode: 'VAL_002',
        userMessage: 'Le nom doit contenir au moins 2 caractères',
        technicalMessage: 'Product name too short: ${value.length} chars',
        field: 'product_name',
        severity: ValidationSeverity.error,
        suggestions: ['Ajoutez plus de détails au nom'],
        metadata: {'actual_length': value.length, 'minimum_required': 2},
      );
    }

    if (value.length > 100) {
      return ValidationResult.error(
        errorCode: 'VAL_003',
        userMessage: 'Le nom ne peut pas dépasser 100 caractères',
        technicalMessage: 'Product name too long: ${value.length} chars',
        field: 'product_name',
        severity: ValidationSeverity.error,
        suggestions: ['Raccourcissez le nom du produit'],
        metadata: {'actual_length': value.length, 'maximum_allowed': 100},
      );
    }

    if (_specialCharsRegex.hasMatch(value)) {
      return ValidationResult.error(
        errorCode: 'VAL_004',
        userMessage: 'Supprimez les caractères spéciaux du nom',
        technicalMessage: 'Product name contains special characters',
        field: 'product_name',
        severity: ValidationSeverity.warning,
        suggestions: [
          'Remplacez < > " / \\ | ? * par des caractères normaux',
          'Utilisez des lettres, chiffres et espaces uniquement',
        ],
        metadata: {'special_chars_found': true},
      );
    }

    if (_sqlInjectionRegex.hasMatch(value)) {
      return ValidationResult.error(
        errorCode: 'VAL_005',
        userMessage: 'Nom invalide détecté',
        technicalMessage: 'Potential SQL injection attempt in product name',
        field: 'product_name',
        severity: ValidationSeverity.critical,
        suggestions: ['Contactez le support si c\'est une erreur'],
        metadata: {'security_alert': true, 'injection_detected': true},
      );
    }

    // Note: On ne log pas les validations réussies pour éviter le bruit
    // Seules les erreurs sont loggées avec ErrorLoggerService.logError

    return ValidationResult.valid();
  }

  /// Valide la quantité d'un produit
  static ValidationResult validateProductQuantity(
    String value, {
    String context = '',
    double maxAllowed = 10000,
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_011',
        userMessage: 'La quantité est requise',
        technicalMessage: 'Empty quantity field',
        field: 'quantity',
        severity: ValidationSeverity.error,
        suggestions: ['Entrez un nombre comme 5 ou 10.5'],
        metadata: {'field_empty': true},
      );
    }

    final quantity = double.tryParse(value.replaceAll(',', '.'));
    if (quantity == null) {
      return ValidationResult.error(
        errorCode: 'VAL_012',
        userMessage: 'Entrez un nombre valide',
        technicalMessage: 'Invalid number format: $value',
        field: 'quantity',
        severity: ValidationSeverity.error,
        suggestions: [
          'Utilisez uniquement des chiffres (ex: 5)',
          'Utilisez un point pour les décimales (ex: 5.5)',
        ],
        metadata: {'invalid_format': true, 'input_value': value},
      );
    }

    if (quantity <= 0) {
      return ValidationResult.error(
        errorCode: 'VAL_013',
        userMessage: 'La quantité doit être supérieure à 0',
        technicalMessage: 'Non-positive quantity: $quantity',
        field: 'quantity',
        severity: ValidationSeverity.error,
        suggestions: ['Entrez une quantité positive comme 1 ou 2.5'],
        metadata: {'quantity_value': quantity, 'zero_or_negative': true},
      );
    }

    if (quantity > maxAllowed) {
      return ValidationResult.error(
        errorCode: 'VAL_014',
        userMessage: 'Quantité trop importante',
        technicalMessage:
            'Quantity exceeds maximum allowed: $quantity > $maxAllowed',
        field: 'quantity',
        severity: ValidationSeverity.warning,
        suggestions: [
          'Réduisez la quantité',
          'Contactez le support pour de gros volumes',
        ],
        metadata: {'quantity_value': quantity, 'max_allowed': maxAllowed},
      );
    }

    // Pour les durables, on veut des nombres entiers
    if (context == 'durable' && quantity != quantity.roundToDouble()) {
      return ValidationResult.error(
        errorCode: 'VAL_015',
        userMessage: 'Pour un bien durable, utilisez un nombre entier',
        technicalMessage: 'Non-integer quantity for durable: $quantity',
        field: 'quantity',
        severity: ValidationSeverity.warning,
        suggestions: ['Utilisez 1, 2, 3... au lieu de 1.5, 2.3...'],
        metadata: {'decimal_quantity': true, 'context': context},
      );
    }

    return ValidationResult.valid();
  }

  /// Valide la fréquence d'achat pour les consommables
  static ValidationResult validateFrequency(
    String value, {
    String context = '',
    int maxDays = 365,
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_021',
        userMessage: 'La fréquence est requise pour les consommables',
        technicalMessage: 'Empty frequency field',
        field: 'frequency',
        severity: ValidationSeverity.error,
        suggestions: ['Exemple: 30 jours pour du savon'],
        metadata: {'field_empty': true},
      );
    }

    final frequency = int.tryParse(value);
    if (frequency == null) {
      return ValidationResult.error(
        errorCode: 'VAL_022',
        userMessage: 'Entrez un nombre entier pour la fréquence',
        technicalMessage: 'Invalid integer format: $value',
        field: 'frequency',
        severity: ValidationSeverity.error,
        suggestions: ['Utilisez des nombres entiers (ex: 7, 15, 30)'],
        metadata: {'invalid_format': true, 'input_value': value},
      );
    }

    if (frequency <= 0) {
      return ValidationResult.error(
        errorCode: 'VAL_023',
        userMessage: 'La fréquence doit être supérieure à 0',
        technicalMessage: 'Non-positive frequency: $frequency',
        field: 'frequency',
        severity: ValidationSeverity.error,
        suggestions: ['Entrez au moins 1 jour'],
        metadata: {'frequency_value': frequency, 'zero_or_negative': true},
      );
    }

    if (frequency > maxDays) {
      return ValidationResult.error(
        errorCode: 'VAL_024',
        userMessage: 'Fréquence trop longue (maximum $maxDays jours)',
        technicalMessage: 'Frequency exceeds maximum: $frequency > $maxDays',
        field: 'frequency',
        severity: ValidationSeverity.warning,
        suggestions: [
          'Réduisez la fréquence',
          'Pour les produits très rares, divisez en achats plus petits',
        ],
        metadata: {'frequency_value': frequency, 'max_allowed': maxDays},
      );
    }

    // Suggestions intelligentes pour les fréquences courantes
    if (frequency < 7) {
      return ValidationResult.error(
        errorCode: 'VAL_025',
        userMessage: 'Fréquence très courte (${frequency}j) - êtes-vous sûr ?',
        technicalMessage: 'Very short frequency: $frequency days',
        field: 'frequency',
        severity: ValidationSeverity.warning,
        suggestions: [
          'Fréquences typiques: 30j (savon), 7j (pain), 90j (dentifrice)',
          'Augmentez si c\'est trop fréquent',
        ],
        metadata: {'very_short_frequency': true, 'frequency_value': frequency},
      );
    }

    return ValidationResult.valid();
  }

  /// Valide une adresse email
  static ValidationResult validateEmail(String value, {String context = ''}) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_031',
        userMessage: 'L\'adresse email est requise',
        technicalMessage: 'Empty email field',
        field: 'email',
        severity: ValidationSeverity.error,
        suggestions: ['exemple@email.com'],
        metadata: {'field_empty': true},
      );
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return ValidationResult.error(
        errorCode: 'VAL_032',
        userMessage: 'Format d\'email invalide',
        technicalMessage: 'Invalid email format: $value',
        field: 'email',
        severity: ValidationSeverity.error,
        suggestions: [
          'Vérifiez que l\'email contient @',
          'Vérifiez le domaine (ex: gmail.com)',
        ],
        metadata: {'invalid_format': true, 'input_value': value},
      );
    }

    return ValidationResult.valid();
  }

  /// Valide un champ de texte avec longueur maximale
  static ValidationResult validateTextLength(
    String value, {
    required String field,
    required int maxLength,
    int minLength = 1,
    String fieldDisplayName = '',
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_041',
        userMessage:
            'Le champ ${fieldDisplayName.isNotEmpty ? fieldDisplayName : field} est requis',
        technicalMessage: 'Empty field: $field',
        field: field,
        severity: ValidationSeverity.error,
        suggestions: ['Saisissez du texte dans ce champ'],
        metadata: {'field_name': field, 'field_empty': true},
      );
    }

    if (value.trim().length < minLength) {
      return ValidationResult.error(
        errorCode: 'VAL_042',
        userMessage:
            '${fieldDisplayName.isNotEmpty ? fieldDisplayName : 'Le champ'} doit contenir au moins $minLength caractères',
        technicalMessage: 'Field too short: ${value.length} < $minLength',
        field: field,
        severity: ValidationSeverity.error,
        suggestions: ['Ajoutez plus de texte'],
        metadata: {
          'actual_length': value.length,
          'minimum_required': minLength,
          'field_name': field,
        },
      );
    }

    if (value.length > maxLength) {
      return ValidationResult.error(
        errorCode: 'VAL_043',
        userMessage:
            '${fieldDisplayName.isNotEmpty ? fieldDisplayName : 'Le champ'} ne peut pas dépasser $maxLength caractères',
        technicalMessage: 'Field too long: ${value.length} > $maxLength',
        field: field,
        severity: ValidationSeverity.error,
        suggestions: ['Raccourcissez le texte'],
        metadata: {
          'actual_length': value.length,
          'maximum_allowed': maxLength,
          'field_name': field,
        },
      );
    }

    return ValidationResult.valid();
  }

  /// Valide une date (pas dans le futur, pas trop ancienne)
  static ValidationResult validateDate(
    DateTime? value, {
    required String field,
    DateTime? maxDate,
    DateTime? minDate,
    String fieldDisplayName = 'date',
  }) {
    if (value == null) {
      return ValidationResult.error(
        errorCode: 'VAL_051',
        userMessage: 'La $fieldDisplayName est requise',
        technicalMessage: 'Null date field: $field',
        field: field,
        severity: ValidationSeverity.error,
        suggestions: ['Sélectionnez une date'],
        metadata: {'date_null': true, 'field_name': field},
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (maxDate != null && value.isAfter(maxDate)) {
      return ValidationResult.error(
        errorCode: 'VAL_052',
        userMessage: 'La $fieldDisplayName ne peut pas être dans le futur',
        technicalMessage: 'Date in future: $value > $maxDate',
        field: field,
        severity: ValidationSeverity.error,
        suggestions: ['Choisissez une date passée ou aujourd\'hui'],
        metadata: {
          'date_value': value.toIso8601String(),
          'max_allowed': maxDate.toIso8601String(),
          'in_future': true,
        },
      );
    }

    if (minDate != null && value.isBefore(minDate)) {
      return ValidationResult.error(
        errorCode: 'VAL_053',
        userMessage: 'La $fieldDisplayName est trop ancienne',
        technicalMessage: 'Date too old: $value < $minDate',
        field: field,
        severity: ValidationSeverity.warning,
        suggestions: ['Choisissez une date plus récente'],
        metadata: {
          'date_value': value.toIso8601String(),
          'min_allowed': minDate.toIso8601String(),
          'too_old': true,
        },
      );
    }

    return ValidationResult.valid();
  }

  /// Valide la taille du conditionnement
  static ValidationResult validatePackagingSize(
    String value, {
    String context = '',
    double maxAllowed = 100000,
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_061',
        userMessage: 'La taille du conditionnement est requise',
        technicalMessage: 'Empty packaging size field',
        field: 'packaging_size',
        severity: ValidationSeverity.error,
        suggestions: ['Exemple: 1.5 pour 1,5 kg'],
        metadata: {'field_empty': true},
      );
    }

    final size = double.tryParse(value.replaceAll(',', '.'));
    if (size == null) {
      return ValidationResult.error(
        errorCode: 'VAL_062',
        userMessage: 'Entrez un nombre valide',
        technicalMessage: 'Invalid number format: $value',
        field: 'packaging_size',
        severity: ValidationSeverity.error,
        suggestions: ['Utilisez un point pour les décimales (ex: 1.5)'],
        metadata: {'invalid_format': true, 'input_value': value},
      );
    }

    if (size <= 0) {
      return ValidationResult.error(
        errorCode: 'VAL_063',
        userMessage: 'La taille doit être supérieure à 0',
        technicalMessage: 'Non-positive packaging size: $size',
        field: 'packaging_size',
        severity: ValidationSeverity.error,
        suggestions: ['Entrez une taille positive'],
        metadata: {'size_value': size, 'zero_or_negative': true},
      );
    }

    if (size > maxAllowed) {
      return ValidationResult.error(
        errorCode: 'VAL_064',
        userMessage: 'Valeur trop grande (max $maxAllowed)',
        technicalMessage: 'Packaging size exceeds maximum: $size > $maxAllowed',
        field: 'packaging_size',
        severity: ValidationSeverity.warning,
        suggestions: ['Réduisez la valeur'],
        metadata: {'size_value': size, 'max_allowed': maxAllowed},
      );
    }

    return ValidationResult.valid();
  }

  /// Valide le prix unitaire
  static ValidationResult validateUnitPrice(
    String value, {
    String context = '',
    double maxAllowed = 100000,
  }) {
    if (value.trim().isEmpty) {
      return ValidationResult.error(
        errorCode: 'VAL_071',
        userMessage: 'Le prix unitaire est requis',
        technicalMessage: 'Empty unit price field',
        field: 'unit_price',
        severity: ValidationSeverity.error,
        suggestions: ['Exemple: 2.99'],
        metadata: {'field_empty': true},
      );
    }

    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null) {
      return ValidationResult.error(
        errorCode: 'VAL_072',
        userMessage: 'Entrez un nombre valide',
        technicalMessage: 'Invalid price format: $value',
        field: 'unit_price',
        severity: ValidationSeverity.error,
        suggestions: ['Utilisez un point pour les décimales (ex: 2.5)'],
        metadata: {'invalid_format': true, 'input_value': value},
      );
    }

    if (price <= 0) {
      return ValidationResult.error(
        errorCode: 'VAL_073',
        userMessage: 'Le prix doit être supérieur à 0',
        technicalMessage: 'Non-positive unit price: $price',
        field: 'unit_price',
        severity: ValidationSeverity.error,
        suggestions: ['Entrez un prix positif'],
        metadata: {'price_value': price, 'zero_or_negative': true},
      );
    }

    if (price > maxAllowed) {
      return ValidationResult.error(
        errorCode: 'VAL_074',
        userMessage: 'Prix trop élevé (max $maxAllowed)',
        technicalMessage: 'Unit price exceeds maximum: $price > $maxAllowed',
        field: 'unit_price',
        severity: ValidationSeverity.warning,
        suggestions: ['Vérifiez le montant'],
        metadata: {'price_value': price, 'max_allowed': maxAllowed},
      );
    }

    return ValidationResult.valid();
  }
}
