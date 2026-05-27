class BigKWallet {
  final int id;
  final String? externalId;
  final String? handle;
  final String? displayName;
  final String? email;
  final String? phone;
  final double balance;
  final String? displayCurrency;
  final int totalXp;
  final int redeemableXp;
  final int weeklyXp;
  final int xpRedemptionRate;
  final int level;
  final double xpProgress;
  final int xpToNextLevel;
  final String state;
  final String tier;
  final String? referralCode;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;

  BigKWallet({
    required this.id,
    this.externalId,
    this.handle,
    this.displayName,
    this.email,
    this.phone,
    required this.balance,
    this.displayCurrency,
    this.totalXp = 0,
    this.redeemableXp = 0,
    this.weeklyXp = 0,
    this.xpRedemptionRate = 0,
    this.level = 1,
    this.xpProgress = 0.0,
    this.xpToNextLevel = 0,
    required this.state,
    required this.tier,
    this.referralCode,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
  });

  factory BigKWallet.fromJson(Map<String, dynamic> json) {
    final walletData = json['wallet'] is Map<String, dynamic>
        ? json['wallet'] as Map<String, dynamic>
        : json['wallet'] is Map
            ? Map<String, dynamic>.from(json['wallet'] as Map)
            : json;

    return BigKWallet(
      id: _parseInt(walletData['id']),
      externalId: walletData['external_id']?.toString(),
      handle: walletData['handle']?.toString(),
      displayName: walletData['display_name']?.toString(),
      email: walletData['email']?.toString(),
      phone: walletData['phone']?.toString(),
      balance: _parseDouble(walletData['balance']),
      displayCurrency: walletData['display_currency']?.toString(),
      totalXp: _parseInt(walletData['total_xp']),
      redeemableXp: _parseInt(walletData['redeemable_xp']),
      weeklyXp: _parseInt(walletData['weekly_xp']),
      xpRedemptionRate: _parseInt(walletData['xp_redemption_rate']),
      level: _parseInt(walletData['level'], fallback: 1),
      xpProgress: _parseDouble(walletData['xp_progress']),
      xpToNextLevel: _parseInt(walletData['xp_to_next_level']),
      state: walletData['state']?.toString() ?? 'active',
      tier: walletData['tier']?.toString() ??
          walletData['league']?.toString() ??
          'bronze',
      referralCode: walletData['referral_code']?.toString(),
      avatarUrl: walletData['avatar_url']?.toString(),
      createdAt: walletData['created_at'] != null
          ? DateTime.tryParse(walletData['created_at'].toString())
          : null,
      updatedAt: walletData['updated_at'] != null
          ? DateTime.tryParse(walletData['updated_at'].toString())
          : null,
      lastActiveAt: walletData['last_active_at'] != null
          ? DateTime.tryParse(walletData['last_active_at'].toString())
          : null,
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'handle': handle,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'balance': balance,
      'display_currency': displayCurrency,
      'total_xp': totalXp,
      'redeemable_xp': redeemableXp,
      'weekly_xp': weeklyXp,
      'xp_redemption_rate': xpRedemptionRate,
      'level': level,
      'xp_progress': xpProgress,
      'xp_to_next_level': xpToNextLevel,
      'state': state,
      'tier': tier,
      'referral_code': referralCode,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  String get balanceFormatted => balance.toStringAsFixed(2);

  bool get isActive => state == 'active';

  bool get isFrozen => state == 'frozen';

  bool get isSuspended => state == 'suspended';

  String get tierName {
    switch (tier) {
      case 'bronze':
        return '\u9752\u94dc\u4f1a\u5458';
      case 'silver':
        return '\u767d\u94f6\u4f1a\u5458';
      case 'gold':
        return '\u9ec4\u91d1\u4f1a\u5458';
      case 'platinum':
        return '\u94c2\u91d1\u4f1a\u5458';
      default:
        return '\u666e\u901a\u4f1a\u5458';
    }
  }
}
