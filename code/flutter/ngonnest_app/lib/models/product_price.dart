class ProductPrice {
  final int? id;
  final String name;
  final String category;
  final double priceFcfa;
  final double priceEuro;
  final String unit; // 'piece', 'kg', 'litre', 'paquet'
  final String? brand;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPrice({
    this.id,
    required this.name,
    required this.category,
    required this.priceFcfa,
    required this.priceEuro,
    required this.unit,
    this.brand,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price_fcfa': priceFcfa,
      'price_euro': priceEuro,
      'unit': unit,
      'brand': brand,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductPrice.fromMap(Map<String, dynamic> map) {
    return ProductPrice(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      priceFcfa: map['price_fcfa']?.toDouble() ?? 0.0,
      priceEuro: map['price_euro']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'piece',
      brand: map['brand'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  ProductPrice copyWith({
    int? id,
    String? name,
    String? category,
    double? priceFcfa,
    double? priceEuro,
    String? unit,
    String? brand,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priceFcfa: priceFcfa ?? this.priceFcfa,
      priceEuro: priceEuro ?? this.priceEuro,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductPrice(id: $id, name: $name, category: $category, priceFcfa: $priceFcfa, priceEuro: $priceEuro, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductPrice &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.priceFcfa == priceFcfa &&
        other.priceEuro == priceEuro &&
        other.unit == unit &&
        other.brand == brand &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        category.hashCode ^
        priceFcfa.hashCode ^
        priceEuro.hashCode ^
        unit.hashCode ^
        brand.hashCode ^
        description.hashCode;
  }
}
