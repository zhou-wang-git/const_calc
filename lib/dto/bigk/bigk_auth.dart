/// BigK 登录响应
class BigKLoginResponse {
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
  final BigKWalletBasic? wallet;
  final bool requiresTwoFactor;
  final String challengeToken;

  BigKLoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
    this.wallet,
    this.requiresTwoFactor = false,
    this.challengeToken = '',
  });

  factory BigKLoginResponse.fromJson(Map<String, dynamic> json) {
    final challengeToken = json['challenge_token']?.toString() ?? '';
    final requiresTwoFactor = json['requires_2fa'] == true ||
        json['2fa_required'] == true ||
        json['2fa_enrollment_required'] == true ||
        challengeToken.isNotEmpty;

    return BigKLoginResponse(
      token: json['token'] ?? json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresAt: _parseExpiry(
        expiresAt: json['expires_at']?.toString(),
        expiresIn: json['expires_in'],
        fallback: const Duration(hours: 1),
      ),
      refreshExpiresAt: json['refresh_expires_at'] != null
          ? DateTime.parse(json['refresh_expires_at'])
          : DateTime.now().add(const Duration(days: 30)),
      wallet: json['wallet'] != null
          ? BigKWalletBasic.fromJson(json['wallet'])
          : null,
      requiresTwoFactor: requiresTwoFactor,
      challengeToken: challengeToken,
    );
  }
}

/// BigK Token 刷新响应
class BigKRefreshResponse {
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;

  BigKRefreshResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  factory BigKRefreshResponse.fromJson(Map<String, dynamic> json) {
    return BigKRefreshResponse(
      token: json['token'] ?? json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresAt: _parseExpiry(
        expiresAt: json['expires_at']?.toString(),
        expiresIn: json['expires_in'],
        fallback: const Duration(hours: 1),
      ),
      refreshExpiresAt: json['refresh_expires_at'] != null
          ? DateTime.parse(json['refresh_expires_at'])
          : DateTime.now().add(const Duration(days: 30)),
    );
  }
}

DateTime _parseExpiry({
  String? expiresAt,
  dynamic expiresIn,
  required Duration fallback,
}) {
  if (expiresAt != null && expiresAt.isNotEmpty) {
    final parsed = DateTime.tryParse(expiresAt);
    if (parsed != null) {
      return parsed;
    }
  }

  final seconds =
      expiresIn is int ? expiresIn : int.tryParse(expiresIn?.toString() ?? '');
  if (seconds != null) {
    return DateTime.now().add(Duration(seconds: seconds));
  }

  return DateTime.now().add(fallback);
}

/// BigK 钱包基本信息（登录时返回）
class BigKWalletBasic {
  final int id;
  final String? externalId;
  final String? handle;
  final String? displayName;
  final String? email;

  BigKWalletBasic({
    required this.id,
    this.externalId,
    this.handle,
    this.displayName,
    this.email,
  });

  factory BigKWalletBasic.fromJson(Map<String, dynamic> json) {
    return BigKWalletBasic(
      id: json['id'] ?? 0,
      externalId: json['external_id'],
      handle: json['handle'],
      displayName: json['display_name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'handle': handle,
      'display_name': displayName,
      'email': email,
    };
  }
}
