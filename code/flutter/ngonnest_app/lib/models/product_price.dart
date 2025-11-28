class ProductPrice {
  final int? id;
  final String name;
  final String nameNormalized;
  final String category;
  final double priceLocal;
  final String currencyCode;
  final String unit;
  final String countryCode;
  final String? region;
  final String? brand;
  final String? description;
  final String source;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPrice({
    this.id,
    required this.name,
    required this.nameNormalized,
    required this.category,
    required this.priceLocal,
    required this.currencyCode,
    required this.unit,
    this.countryCode = 'CM',
    this.region,
    this.brand,
    this.description,
    this.source = 'static',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_normalized': nameNormalized,
      'category': category,
      'price_local': priceLocal,
      'currency_code': currencyCode,
      'unit': unit,
      'country_code': countryCode,
      'region': region,
      'brand': brand,
      'description': description,
      'source': source,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductPrice.fromMap(Map<String, dynamic> map) {
    return ProductPrice(
      id: (map['id'] as num?)?.toInt(),
      name: map['name'] ?? '',
      nameNormalized: map['name_normalized'] ?? '',
      category: map['category'] ?? '',
      priceLocal: (map['price_local'] as num?)?.toDouble() ?? 0.0,
      currencyCode: map['currency_code'] ?? 'XAF',
      unit: map['unit'] ?? 'piece',
      countryCode: map['country_code'] ?? 'CM',
      region: map['region'],
      brand: map['brand'],
      description: map['description'],
      source: map['source'] ?? 'static',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  ProductPrice copyWith({
    int? id,
    String? name,
    String? nameNormalized,
    String? category,
    double? priceLocal,
    String? currencyCode,
    String? unit,
    String? countryCode,
    String? region,
    String? brand,
    String? description,
    String? source,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      name: name ?? this.name,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      category: category ?? this.category,
      priceLocal: priceLocal ?? this.priceLocal,
      currencyCode: currencyCode ?? this.currencyCode,
      unit: unit ?? this.unit,
      countryCode: countryCode ?? this.countryCode,
      region: region ?? this.region,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductPrice(id: $id, name: $name, category: $category, priceLocal: $priceLocal $currencyCode, unit: $unit, country: $countryCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductPrice &&
        other.id == id &&
        other.name == name &&
        other.nameNormalized == nameNormalized &&
        other.category == category &&
        other.priceLocal == priceLocal &&
        other.currencyCode == currencyCode &&
        other.unit == unit &&
        other.countryCode == countryCode &&
        other.brand == brand &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        nameNormalized.hashCode ^
        category.hashCode ^
        priceLocal.hashCode ^
        currencyCode.hashCode ^
        unit.hashCode ^
        countryCode.hashCode ^
        brand.hashCode ^
        description.hashCode;
  }
}
