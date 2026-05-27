/// BigK 商品分类
class BigKCategory {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final int productCount;

  BigKCategory({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.productCount = 0,
  });

  factory BigKCategory.fromJson(Map<String, dynamic> json) {
    return BigKCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['image_url'] ?? json['image'],
      parentId: json['parent_id'] ?? json['parent'],
      productCount: json['product_count'] ?? json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'parent_id': parentId,
      'product_count': productCount,
    };
  }

  bool get isTopLevel => parentId == null || parentId == 0;
}
