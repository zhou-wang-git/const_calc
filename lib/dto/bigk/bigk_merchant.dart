/// BigK 商户
class BigKMerchant {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String status;
  final DateTime? createdAt;

  BigKMerchant({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.status,
    this.createdAt,
  });

  factory BigKMerchant.fromJson(Map<String, dynamic> json) {
    return BigKMerchant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
}
