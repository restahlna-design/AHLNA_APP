class FoodItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int sortOrder;

  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

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
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'بدون اسم',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isAvailable: (json['is_available'] as bool?) ?? (json['isAvailable'] as bool?) ?? true,
      sortOrder: (json['sort_order'] is num)
          ? (json['sort_order'] as num).toInt()
          : (int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0),
    );
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
    };
  }
}
