import 'dart:convert';

class FoodVariant {
  final String name;
  final double price;

  const FoodVariant({
    required this.name,
    required this.price,
  });

  factory FoodVariant.fromJson(Map<String, dynamic> json) {
    return FoodVariant(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int sortOrder;
  final List<FoodVariant> variants;

  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  String get heroTag => 'food_$id';

  FoodItem copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    int? sortOrder,
    List<FoodVariant>? variants,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      variants: variants ?? this.variants,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    List<FoodVariant> parsedVariants = [];
    var rawVariants = json['variants'];
    if (rawVariants is String && rawVariants.trim().isNotEmpty) {
      try {
        rawVariants = jsonDecode(rawVariants);
      } catch (_) {}
    }
    if (rawVariants is List) {
      for (var v in rawVariants) {
        if (v is String && v.trim().isNotEmpty) {
          try {
            v = jsonDecode(v);
          } catch (_) {}
        }
        if (v is Map) {
          try {
            parsedVariants.add(
              FoodVariant.fromJson(Map<String, dynamic>.from(v)),
            );
          } catch (_) {}
        }
      }
    }

    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'بدون اسم',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isAvailable: _parseBool(json['is_available'] ?? json['isAvailable']),
      sortOrder: (json['sort_order'] is num)
          ? (json['sort_order'] as num).toInt()
          : (int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0),
      variants: parsedVariants,
    );
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return true;
    if (val is bool) return val;
    if (val is num) return val != 0;
    final str = val.toString().trim().toLowerCase();
    return str == 'true' || str == '1' || str == 'yes' || str == 't';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable,
      'sort_order': sortOrder,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}
