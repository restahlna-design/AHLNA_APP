class CategoryModel {
  final int id;
  final String nameEn;
  final String nameAr;
  final int? parentId;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.parentId,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] is num)
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      parentId: (json['parent_id'] is num)
          ? (json['parent_id'] as num).toInt()
          : (int.tryParse(json['parent_id']?.toString() ?? '')),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_en': nameEn,
      'name_ar': nameAr,
      'parent_id': parentId,
      'image_url': imageUrl,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? nameEn,
    String? nameAr,
    int? parentId,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
