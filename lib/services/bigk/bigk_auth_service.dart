import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dto/bigk/bigk_auth.dart';
import '../../dto/bigk/bigk_profile.dart';
import '../../handler/api_exception.dart';
import '../kcc/kcc_auth_service.dart';
import 'bigk_http_service.dart';

/// Manages KCC ID login state used by PlenorHub commerce APIs.
class BigKAuthService {
  static final BigKAuthService _instance = BigKAuthService._internal();
  factory BigKAuthService() => _instance;
  BigKAuthService._internal();

  static const String walletClientId = 'shuyi';
  static const String _walletIdKey = 'bigk_wallet_id';
  static const String _walletHandleKey = 'bigk_wallet_handle';
  static const String _walletEmailKey = 'bigk_wallet_email';
  static const String _displayNameKey = 'bigk_display_name';
  static const String _kccUserIdKey = 'bigk_kcc_user_id';

  String? _walletId;
  String? _walletHandle;
  String? _walletEmail;
  String? _displayName;
  String? _kccUserId;

  String? get walletId => _walletId;
  String? get walletHandle => _walletHandle;
  String? get walletEmail => _walletEmail;
  String? get displayName => _displayName;
  String? get kccUserId => _kccUserId;
  String get clientId => BigKHttpService.authClientId;

  bool get isLinked => BigKHttpService.hasValidToken;
  bool get hasWalletLink => _walletId != null && _walletId!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _walletId = prefs.getString(_walletIdKey);
    _walletHandle = prefs.getString(_walletHandleKey);
    _walletEmail = prefs.getString(_walletEmailKey);
    _displayName = prefs.getString(_displayNameKey);
    _kccUserId = prefs.getString(_kccUserIdKey);

    debugPrint(
      'BigKAuthService initialized, isLinked: $isLinked, walletId: $_walletId',
    );
  }

  Future<BigKLoginResponse> login(String identifier, String password) async {
    debugPrint(
      'BigK: Attempting KCC ID PKCE login with identifier: $identifier',
    );

    final session = await KccAuthService().loginWithPassword(
      identifier: identifier,
      password: password,
    );

    await restoreUnifiedSession(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
      expiresAt: session.tokens.expiresAt,
      clientId: session.clientId,
      profile: session.userInfo.toJson(),
    );
    await syncProfile();

    debugPrint('BigK: KCC ID login successful, kccUserId: $_kccUserId');

    return BigKLoginResponse(
      token: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
      expiresAt: session.tokens.expiresAt,
      refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<BigKLoginResponse> restoreSession(BigKLoginResponse response) async {
    await BigKHttpService.saveTokens(
      accessToken: response.token,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      clientId: walletClientId,
    );

    await syncProfile();
    return response;
  }

  Future<void> restoreUnifiedSession({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required String clientId,
    Map<String, dynamic>? profile,
  }) async {
    await BigKHttpService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      clientId: clientId,
    );

    if (profile != null) {
      await _saveProfileInfo(profile);
      return;
    }

    await syncProfile();
  }

  Future<Map<String, dynamic>> syncProfile() async {
    final profile = await BigKHttpService.getAuth<Map<String, dynamic>>(
      BigKHttpService.authPath('/userinfo'),
      (data) => Map<String, dynamic>.from(data as Map),
    );

    try {
      final walletProfile = await getWalletLink();

      final walletId = walletProfile.walletId;
      if (walletId.isNotEmpty) {
        profile['wallet_id'] = walletId;
      }
      if (walletProfile.handle.isNotEmpty) {
        profile['preferred_username'] = walletProfile.handle;
      }
      if (walletProfile.email.isNotEmpty) {
        profile['email'] = walletProfile.email;
      }
    } catch (e) {
      if (e is ApiException) {
        final lower = e.message.toLowerCase();
        final walletNotReady =
            (e.code == 401 || e.code == 404) &&
            (lower.contains('no wallet profile linked') ||
                lower.contains('wallet not found') ||
                lower.contains('/wallet/provision'));
        if (!walletNotReady) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    await _saveProfileInfo(profile);
    return profile;
  }

  Future<void> _saveProfileInfo(Map<String, dynamic> profile) async {
    _kccUserId = profile['sub']?.toString();
    _walletId = profile['wallet_id']?.toString();
    _walletHandle = profile['preferred_username']?.toString();
    _walletEmail = profile['email']?.toString();
    _displayName = profile['name']?.toString();

    final prefs = await SharedPreferences.getInstance();

    if (_walletId != null && _walletId!.isNotEmpty) {
      await prefs.setString(_walletIdKey, _walletId!);
    } else {
      await prefs.remove(_walletIdKey);
    }

    if (_walletHandle != null && _walletHandle!.isNotEmpty) {
      await prefs.setString(_walletHandleKey, _walletHandle!);
    } else {
      await prefs.remove(_walletHandleKey);
    }

    if (_walletEmail != null && _walletEmail!.isNotEmpty) {
      await prefs.setString(_walletEmailKey, _walletEmail!);
    } else {
      await prefs.remove(_walletEmailKey);
    }

    if (_displayName != null && _displayName!.isNotEmpty) {
      await prefs.setString(_displayNameKey, _displayName!);
    } else {
      await prefs.remove(_displayNameKey);
    }

    if (_kccUserId != null && _kccUserId!.isNotEmpty) {
      await prefs.setString(_kccUserIdKey, _kccUserId!);
    } else {
      await prefs.remove(_kccUserIdKey);
    }
  }

  Future<String?> provisionWallet() async {
    final response = await BigKHttpService.postWallet<Map<String, dynamic>>(
      '/wallet/provision',
      const {},
      (data) => Map<String, dynamic>.from(data as Map),
    );

    final wallet = response['wallet'];
    final walletId = wallet is Map<String, dynamic>
        ? wallet['external_id']?.toString() ??
              wallet['wallet_id']?.toString() ??
              wallet['id']?.toString()
        : wallet is Map
        ? Map<String, dynamic>.from(wallet)['external_id']?.toString() ??
              Map<String, dynamic>.from(wallet)['wallet_id']?.toString() ??
              Map<String, dynamic>.from(wallet)['id']?.toString()
        : null;

    if (walletId != null && walletId.isNotEmpty) {
      _walletId = walletId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_walletIdKey, _walletId!);
    }

    return _walletId;
  }

  Future<BigKWalletLink> getWalletLink() async {
    debugPrint('BigK: Fetching wallet link state...');

    return BigKHttpService.getWallet<BigKWalletLink>(
      '/wallet/me',
      BigKWalletLink.fromJson,
    );
  }

  Future<List<BigKSessionInfo>> getSessions() async {
    debugPrint('BigK: Fetching active sessions...');

    return BigKHttpService.getWallet<List<BigKSessionInfo>>('/auth/sessions', (
      data,
    ) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      final sessions = payload['sessions'] is List
          ? payload['sessions'] as List
          : payload['data'] is List
          ? payload['data'] as List
          : data['sessions'] is List
          ? data['sessions'] as List
          : const [];
      return sessions.map(BigKSessionInfo.fromJson).toList();
    });
  }

  Future<void> revokeSession(String sessionId) async {
    debugPrint('BigK: Revoking session $sessionId...');

    await BigKHttpService.deleteWallet<Map<String, dynamic>>(
      '/auth/sessions/$sessionId',
      (data) => data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map),
    );
  }

  Future<void> revokeAllSessions() async {
    debugPrint('BigK: Revoking all active sessions...');

    await BigKHttpService.deleteWallet<Map<String, dynamic>>(
      '/auth/sessions',
      (data) => data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map),
    );
  }

  Future<void> logout({bool remote = true}) async {
    if (remote && BigKHttpService.hasValidToken) {
      try {
        await BigKHttpService.postWallet<Map<String, dynamic>>(
          '/auth/logout',
          const <String, dynamic>{},
          (data) => data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data as Map),
        );
      } catch (e) {
        debugPrint('BigK: Remote logout failed: $e');
      }
    }

    _walletId = null;
    _walletHandle = null;
    _walletEmail = null;
    _displayName = null;
    _kccUserId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletIdKey);
    await prefs.remove(_walletHandleKey);
    await prefs.remove(_walletEmailKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_kccUserIdKey);

    await BigKHttpService.clearTokens();

    debugPrint('BigK: Logged out');
  }

  Future<BigKRefreshResponse> refreshToken(String refreshToken) async {
    final response = await BigKHttpService.postWithoutAuth<BigKRefreshResponse>(
      BigKHttpService.authPath('/token'),
      {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': BigKHttpService.authClientId,
      },
      (data) => BigKRefreshResponse.fromJson(data),
      useAuthBase: true,
    );

    await BigKHttpService.saveTokens(
      accessToken: response.token,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      clientId: BigKHttpService.authClientId,
    );

    await syncProfile();

    return response;
  }
}
