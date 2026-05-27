/// 商品分类数据模型（完整版）
/// 对应 WooCommerce Product Category 实体
class Category {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final String description;
  final String? image;
  final int count;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.parent,
    required this.description,
    this.image,
    required this.count,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image'] != null && json['image'] is Map) {
      imageUrl = json['image']['src'];
    }

    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parent: json['parent'] ?? 0,
      description: json['description'] ?? '',
      image: imageUrl,
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent': parent,
      'description': description,
      'image': image != null ? {'src': image} : null,
      'count': count,
    };
  }

  /// 是否为顶级分类
  bool get isTopLevel => parent == 0;

  /// 是否有商品
  bool get hasProducts => count > 0;
}
