class Avatar {
  final int id;
  final String name;
  final String imageUrl;
  final int isDefault;
  final int status;
  final int addTime;

  Avatar({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isDefault,
    required this.status,
    required this.addTime,
  });

  /// 从 JSON 创建对象（带空值安全处理）
  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      isDefault: json['is_default'] is int
          ? json['is_default']
          : int.tryParse(json['is_default']?.toString() ?? '0') ?? 0,
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      addTime: json['add_time'] is int
          ? json['add_time']
          : int.tryParse(json['add_time']?.toString() ?? '0') ?? 0,
    );
  }

  /// 转成 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'is_default': isDefault,
      'status': status,
      'add_time': addTime,
    };
  }
}
