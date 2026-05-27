import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../dto/kcc/kcc_auth.dart';
import '../../handler/api_exception.dart';
import '../bigk/bigk_http_service.dart';

class KccAuthService {
  static const String unifiedClientId = 'shuyi';
  static const String walletClientId = 'bigk_wallet';
  static const String scope = 'openid profile email';
  static const String _codeChallengeMethod = 'S256';
  static const String _registerCookieKey = 'kcc_register_cookie_header';
  static const String _resetCookieKey = 'kcc_reset_cookie_header';

  static bool isInvalidCredentialsMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('provided credentials are invalid') ||
        lower.contains('provide credentials are invaild') ||
        lower.contains('credentials are invalid') ||
        lower.contains('invalid credentials') ||
        message.contains(
            '\u7edf\u4e00\u8eab\u4efd\u8d26\u53f7\u6216\u5bc6\u7801\u9519\u8bef') ||
        message.contains('KCC ID \u8d26\u53f7\u6216\u5bc6\u7801\u9519\u8bef');
  }

  Future<KccAuthSession> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim();
    try {
      return await _loginWithAuthorizationCodeFlow(
        identifier: normalizedIdentifier,
        password: password,
        clientId: unifiedClientId,
      );
    } on ApiException catch (e) {
      if (!_shouldFallbackToWalletClient(e.message)) {
        rethrow;
      }
    }

    return _loginWithAuthorizationCodeFlow(
      identifier: normalizedIdentifier,
      password: password,
      clientId: walletClientId,
    );
  }

  Future<KccAuthSession> _loginWithAuthorizationCodeFlow({
    required String identifier,
    required String password,
    required String clientId,
  }) async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _buildCodeChallenge(codeVerifier);

    final authorizeJson = await _postJson(
      BigKHttpService.authPath('/authorize'),
      {
        'identifier': identifier,
        'password': password,
        'client_id': clientId,
        'code_challenge': codeChallenge,
        'code_challenge_method': _codeChallengeMethod,
        'scope': scope,
      },
      fallbackMessage: 'KCC ID authorize failed',
    );
    _throwIfTwoFactorChallenge(authorizeJson);

    final authorizationCode = authorizeJson['code']?.toString() ?? '';
    if (authorizationCode.isEmpty) {
      throw ApiException(
          -1, 'KCC ID authorize failed: missing authorization code');
    }

    final tokenJson = await _postJson(
      BigKHttpService.authPath('/token'),
      {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': authorizationCode,
        'code_verifier': codeVerifier,
      },
      fallbackMessage: 'KCC ID token exchange failed',
    );
    _throwIfTwoFactorChallenge(tokenJson);

    final tokens = KccTokenSet.fromJson(tokenJson);
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      throw ApiException(
        -1,
        'KCC ID login failed: token payload is incomplete',
      );
    }

    final userInfoJson = await _getJson(
      BigKHttpService.authPath('/userinfo'),
      accessToken: tokens.accessToken,
      fallbackMessage: 'KCC ID userinfo request failed',
    );
    final userInfo = KccUserInfo.fromJson(userInfoJson);
    if (userInfo.sub.isEmpty) {
      throw ApiException(-1, 'KCC ID login failed: userinfo is missing sub');
    }

    return KccAuthSession(
      tokens: tokens,
      userInfo: userInfo,
      clientId: clientId,
    );
  }

  Future<KccOtpSession> requestOtp({
    required String channel,
    required String target,
    required String purpose,
  }) async {
    final body = <String, dynamic>{
      'channel': channel,
      'target': target,
      'purpose': purpose,
      if (purpose == 'registration') 'client_id': walletClientId,
    };

    final json = await _postJson(
      BigKHttpService.authPath('/otp/request'),
      body,
      fallbackMessage: 'KCC ID OTP request failed',
      cookieStoreKey: purpose == 'registration' ? _registerCookieKey : null,
      resetCookieStore: purpose == 'registration',
    );
    final session = KccOtpSession.fromJson(json);
    if (session.sessionId.isEmpty) {
      throw ApiException(-1, 'KCC ID OTP request failed: missing session_id');
    }
    return session;
  }

  Future<KccOtpVerificationResult> verifyOtp({
    required String sessionId,
    required String code,
  }) async {
    final json = await _postJson(
      BigKHttpService.authPath('/otp/verify'),
      {
        'session_id': sessionId,
        'code': code,
      },
      fallbackMessage: 'KCC ID OTP verification failed',
      cookieStoreKey: _registerCookieKey,
    );
    final result = KccOtpVerificationResult.fromJson(json);
    if (!result.verified) {
      throw ApiException(
        -1,
        result.message.isEmpty
            ? 'KCC ID OTP verification failed'
            : result.message,
      );
    }
    return result;
  }

  Future<KccRegistrationResponse> register({
    required String otpSessionId,
    required String password,
    required String passwordConfirmation,
    required String displayName,
  }) async {
    final json = await _postJson(
      BigKHttpService.authPath('/register'),
      {
        'otp_session_id': otpSessionId,
        'client_id': walletClientId,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'display_name': displayName,
      },
      fallbackMessage: 'KCC ID registration failed',
      cookieStoreKey: _registerCookieKey,
      clearCookieStoreOnSuccess: true,
    );
    return KccRegistrationResponse.fromJson(json);
  }

  Future<KccForgotPasswordSession> forgotPassword({
    required String email,
  }) async {
    final json = await _postJson(
      BigKHttpService.authPath('/forgot-password'),
      {
        'email': email.trim(),
      },
      fallbackMessage: 'KCC ID forgot password request failed',
      cookieStoreKey: _resetCookieKey,
      resetCookieStore: true,
    );
    final session = KccForgotPasswordSession.fromJson(json);
    if (session.sessionId.isEmpty) {
      throw ApiException(
        -1,
        'KCC ID forgot password request failed: missing session_id',
      );
    }
    return session;
  }

  Future<KccResetOtpVerificationResult> verifyResetOtp({
    required String email,
    required String sessionId,
    required String otp,
  }) async {
    final json = await _postJson(
      BigKHttpService.authPath('/verify-reset-otp'),
      {
        'email': email.trim(),
        'session_id': sessionId,
        'otp': otp.trim(),
      },
      fallbackMessage: 'KCC ID reset OTP verification failed',
      cookieStoreKey: _resetCookieKey,
    );
    final result = KccResetOtpVerificationResult.fromJson(json);
    if (result.resetToken.isEmpty) {
      throw ApiException(
        -1,
        result.message.isEmpty
            ? 'KCC ID reset OTP verification failed: missing reset_token'
            : result.message,
      );
    }
    return result;
  }

  Future<KccPasswordResetResponse> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final json = await _postJson(
      BigKHttpService.authPath('/reset-password'),
      {
        'email': email.trim(),
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fallbackMessage: 'KCC ID password reset failed',
      cookieStoreKey: _resetCookieKey,
      clearCookieStoreOnSuccess: true,
    );
    return KccPasswordResetResponse.fromJson(json);
  }

  Future<KccPasswordResetResponse> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return BigKHttpService.postAuth<KccPasswordResetResponse>(
      BigKHttpService.authPath('/change-password'),
      {
        'current_password': currentPassword,
        'new_password': password,
        'new_password_confirmation': passwordConfirmation,
      },
      (data) => KccPasswordResetResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    required String fallbackMessage,
    String? accessToken,
    String? cookieStoreKey,
    bool resetCookieStore = false,
    bool clearCookieStoreOnSuccess = false,
  }) async {
    try {
      if (cookieStoreKey != null) {
        final prefs = await SharedPreferences.getInstance();
        if (resetCookieStore) {
          await prefs.remove(cookieStoreKey);
        }

        final storedCookieHeader = prefs.getString(cookieStoreKey);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
          if (storedCookieHeader != null && storedCookieHeader.isNotEmpty)
            'Cookie': storedCookieHeader,
        };

        final dio = Dio(BaseOptions(
          validateStatus: (_) => true,
          responseType: ResponseType.plain,
        ));
        final response = await dio.postUri(
          _buildUri(path),
          data: jsonEncode(body),
          options: Options(headers: headers),
        );

        final mergedCookieHeader = _mergeCookieHeaders(
          storedCookieHeader,
          response.headers.map['set-cookie'],
        );
        if (mergedCookieHeader != null && mergedCookieHeader.isNotEmpty) {
          await prefs.setString(cookieStoreKey, mergedCookieHeader);
        }

        final json = _decodeJsonPayload(
          response.statusCode ?? 0,
          response.data?.toString() ?? '',
          fallbackMessage,
        );
        if (clearCookieStoreOnSuccess) {
          await prefs.remove(cookieStoreKey);
        }
        return json;
      }

      final response = await http.post(
        _buildUri(path),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );
      return _decodeJsonPayload(
        response.statusCode,
        response.body,
        fallbackMessage,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(-1, '$fallbackMessage: $e');
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String accessToken,
    required String fallbackMessage,
  }) async {
    try {
      final response = await http.get(
        _buildUri(path),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      return _decodeJsonPayload(
        response.statusCode,
        response.body,
        fallbackMessage,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(-1, '$fallbackMessage: $e');
    }
  }

  Map<String, dynamic> _decodeJsonPayload(
    int statusCode,
    String body,
    String fallbackMessage,
  ) {
    Map<String, dynamic> json = <String, dynamic>{};
    if (body.trim().isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      } else {
        json = {'data': decoded};
      }
    }

    if (statusCode < 200 || statusCode >= 300) {
      final rawMessage = _extractErrorMessage(json) ??
          json['error_description']?.toString() ??
          json['error']?.toString() ??
          fallbackMessage;
      throw ApiException(statusCode, _normalizeErrorMessage(rawMessage));
    }

    return json;
  }

  String? _extractErrorMessage(Map<String, dynamic> json) {
    final message = json['message']?.toString();
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final details = <String>[];
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          details.add(value.first.toString());
        } else if (value != null) {
          details.add(value.toString());
        }
      }
      if (details.isNotEmpty) {
        return message == null || message.isEmpty
            ? details.join('；')
            : '$message: ${details.join('；')}';
      }
    }
    return message;
  }

  String? _mergeCookieHeaders(
    String? existingCookieHeader,
    List<String>? setCookieHeaders,
  ) {
    final jar = <String, String>{};

    void addCookiePair(String pair) {
      final trimmed = pair.trim();
      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex <= 0) return;

      final name = trimmed.substring(0, separatorIndex).trim();
      final value = trimmed.substring(separatorIndex + 1).trim();
      if (name.isEmpty || value.isEmpty) return;
      jar[name] = value;
    }

    if (existingCookieHeader != null && existingCookieHeader.isNotEmpty) {
      for (final pair in existingCookieHeader.split(';')) {
        addCookiePair(pair);
      }
    }

    if (setCookieHeaders != null) {
      for (final header in setCookieHeaders) {
        final firstPair = header.split(';').first;
        addCookiePair(firstPair);
      }
    }

    if (jar.isEmpty) {
      return null;
    }

    return jar.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  String _normalizeErrorMessage(String message) {
    if (isInvalidCredentialsMessage(message)) {
      return 'KCC ID 账号或密码错误';
    }

    final lower = message.toLowerCase();
    if (lower.contains('invalid client') ||
        lower.contains('unauthorized client')) {
      return 'KCC ID 客户端未授权，请联系管理员开通 shuyi client。';
    }

    return message;
  }

  void _throwIfTwoFactorChallenge(Map<String, dynamic> json) {
    final challengeToken = json['challenge_token']?.toString() ?? '';
    final requiresTwoFactor = json['requires_2fa'] == true ||
        json['2fa_required'] == true ||
        json['2fa_enrollment_required'] == true ||
        challengeToken.isNotEmpty;
    if (!requiresTwoFactor) {
      return;
    }

    throw ApiException(
      403,
      'KCC ID two-factor authentication is required, but this app does not support the 2FA flow yet.',
    );
  }

  bool _shouldFallbackToWalletClient(String message) {
    final lower = message.toLowerCase();
    return lower.contains('access_denied') ||
        lower.contains('no authorization is configured for this client');
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${BigKHttpService.authBaseUrl}$normalizedPath');
  }

  String _generateCodeVerifier([int length = 64]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _buildCodeChallenge(String verifier) {
    final digest = sha256.convert(verifier.codeUnits);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
