class KccTokenSet {
  final String accessToken;
  final String refreshToken;
  final String idToken;
  final String tokenType;
  final String scope;
  final DateTime expiresAt;

  KccTokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.tokenType,
    required this.scope,
    required this.expiresAt,
  });

  factory KccTokenSet.fromJson(Map<String, dynamic> json) {
    return KccTokenSet(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      idToken: json['id_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      scope: json['scope']?.toString() ?? 'openid profile email',
      expiresAt: _parseExpiry(
        expiresAt: json['expires_at']?.toString(),
        expiresIn: json['expires_in'],
        fallback: const Duration(hours: 1),
      ),
    );
  }
}

class KccUserInfo {
  final String sub;
  final String name;
  final String preferredUsername;
  final String email;
  final bool emailVerified;
  final String picture;
  final String walletId;

  KccUserInfo({
    required this.sub,
    required this.name,
    required this.preferredUsername,
    required this.email,
    required this.emailVerified,
    required this.picture,
    required this.walletId,
  });

  factory KccUserInfo.fromJson(Map<String, dynamic> json) {
    return KccUserInfo(
      sub: json['sub']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      preferredUsername: json['preferred_username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVerified:
          json['email_verified'] == true || json['email_verified'] == 1,
      picture: json['picture']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': sub,
      'name': name,
      'preferred_username': preferredUsername,
      'email': email,
      'email_verified': emailVerified,
      'picture': picture,
      'wallet_id': walletId,
    };
  }
}

class KccAuthSession {
  final KccTokenSet tokens;
  final KccUserInfo userInfo;
  final String clientId;

  KccAuthSession({
    required this.tokens,
    required this.userInfo,
    required this.clientId,
  });
}

class KccOtpSession {
  final String sessionId;
  final DateTime? expiresAt;
  final String message;

  KccOtpSession({
    required this.sessionId,
    required this.expiresAt,
    required this.message,
  });

  factory KccOtpSession.fromJson(Map<String, dynamic> json) {
    return KccOtpSession(
      sessionId: json['session_id']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      message: json['message']?.toString() ?? '',
    );
  }
}

class KccOtpVerificationResult {
  final bool verified;
  final String message;

  KccOtpVerificationResult({
    required this.verified,
    required this.message,
  });

  factory KccOtpVerificationResult.fromJson(Map<String, dynamic> json) {
    final message = json['message']?.toString() ?? '';
    final verifiedValue = json['verified'];
    final verified = verifiedValue == true ||
        verifiedValue == 1 ||
        (verifiedValue == null &&
            message.toLowerCase().contains('verified successfully'));

    return KccOtpVerificationResult(
      verified: verified,
      message: message,
    );
  }
}

class KccRegistrationResponse {
  final String message;
  final String kccUserId;

  KccRegistrationResponse({
    required this.message,
    required this.kccUserId,
  });

  factory KccRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return KccRegistrationResponse(
      message: json['message']?.toString() ?? '',
      kccUserId: json['kcc_user_id']?.toString() ?? '',
    );
  }
}

class KccForgotPasswordSession {
  final String message;
  final String sessionId;

  KccForgotPasswordSession({
    required this.message,
    required this.sessionId,
  });

  factory KccForgotPasswordSession.fromJson(Map<String, dynamic> json) {
    return KccForgotPasswordSession(
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
    );
  }
}

class KccResetOtpVerificationResult {
  final String message;
  final String resetToken;

  KccResetOtpVerificationResult({
    required this.message,
    required this.resetToken,
  });

  factory KccResetOtpVerificationResult.fromJson(Map<String, dynamic> json) {
    return KccResetOtpVerificationResult(
      message: json['message']?.toString() ?? '',
      resetToken: json['reset_token']?.toString() ?? '',
    );
  }
}

class KccPasswordResetResponse {
  final String message;

  KccPasswordResetResponse({
    required this.message,
  });

  factory KccPasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return KccPasswordResetResponse(
      message: json['message']?.toString() ?? '',
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
