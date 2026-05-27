import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../dto/login_user.dart';
import '../../handler/api_exception.dart';
import '../http_service.dart';

/// HTTP client for KCC ID authentication, BigK wallet APIs, and PlenorHub commerce APIs.
class BigKHttpService {
  static const String authBaseUrl = 'https://auth.bigkpay.com';
  static const String kccApiPrefix = '/kccid/v1';
  static const String walletBaseUrl =
      'https://bigk-admin-production.up.railway.app/api/v1';
  static const String commerceBaseUrl =
      'https://plenorhub-production.up.railway.app/api/v1';
  static const String _defaultClientId = 'bigk_wallet';

  static const String _accessTokenKey = 'bigk_access_token';
  static const String _refreshTokenKey = 'bigk_refresh_token';
  static const String _tokenExpiryKey = 'bigk_token_expiry';
  static const String _clientIdKey = 'bigk_client_id';

  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static String? _authClientId;
  static bool _isRefreshing = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _authClientId = prefs.getString(_clientIdKey);

    final expiryStr = prefs.getString(_tokenExpiryKey);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.tryParse(expiryStr);
    }

    debugPrint(
      'BigKHttpService initialized, hasToken: ${_accessToken != null}',
    );
  }

  static bool get hasValidToken =>
      _accessToken != null && _accessToken!.isNotEmpty;

  static String? get accessToken => _accessToken;
  static String get authClientId => _authClientId ?? _defaultClientId;

  static String authPath(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$kccApiPrefix$normalizedPath';
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    String? clientId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiresAt;
    if (clientId != null && clientId.isNotEmpty) {
      _authClientId = clientId;
    }
    _authClientId ??= _defaultClientId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());
    await prefs.setString(_clientIdKey, _authClientId!);

    debugPrint(
      'BigK tokens saved, clientId: $_authClientId, expires at: $expiresAt',
    );
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _authClientId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_clientIdKey);

    debugPrint('BigK tokens cleared');
  }

  static Future<T> get<T>(
    String path,
    T Function(dynamic) fromData, {
    Map<String, String>? queryParams,
  }) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'GET',
      baseUrl: commerceBaseUrl,
      path: path,
      fromData: fromData,
      queryParams: queryParams,
      includeAuth: true,
    );
  }

  static Future<T> getWallet<T>(
    String path,
    T Function(dynamic) fromData, {
    Map<String, String>? queryParams,
  }) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'GET',
      baseUrl: walletBaseUrl,
      path: path,
      fromData: fromData,
      queryParams: queryParams,
      includeAuth: true,
    );
  }

  static Future<T> getPublic<T>(
    String path,
    T Function(dynamic) fromData, {
    Map<String, String>? queryParams,
  }) {
    return _sendRequest(
      method: 'GET',
      baseUrl: commerceBaseUrl,
      path: path,
      fromData: fromData,
      queryParams: queryParams,
      includeAuth: false,
    );
  }

  static Future<T> getAuth<T>(
    String path,
    T Function(dynamic) fromData, {
    bool includeAuth = true,
    Map<String, String>? queryParams,
  }) async {
    if (includeAuth) {
      await _ensureValidToken();
    }

    return _sendRequest(
      method: 'GET',
      baseUrl: authBaseUrl,
      path: path,
      fromData: fromData,
      queryParams: queryParams,
      includeAuth: includeAuth,
    );
  }

  static Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'POST',
      baseUrl: commerceBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: true,
    );
  }

  static Future<T> postWallet<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'POST',
      baseUrl: walletBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: true,
    );
  }

  static Future<T> putWallet<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'PUT',
      baseUrl: walletBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: true,
    );
  }

  static Future<T> deleteWallet<T>(
    String path,
    T Function(dynamic) fromData, {
    Map<String, String>? queryParams,
  }) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'DELETE',
      baseUrl: walletBaseUrl,
      path: path,
      fromData: fromData,
      queryParams: queryParams,
      includeAuth: true,
    );
  }

  static Future<T> postWalletMultipart<T>(
    String path, {
    Map<String, dynamic>? fields,
    required Uint8List fileBytes,
    required String fileName,
    String fileField = 'file',
    required T Function(dynamic) fromData,
  }) async {
    await _ensureValidToken();

    return _sendMultipartRequest(
      method: 'POST',
      baseUrl: walletBaseUrl,
      path: path,
      fields: fields,
      fileBytes: fileBytes,
      fileName: fileName,
      fileField: fileField,
      fromData: fromData,
      includeAuth: true,
    );
  }

  static Future<T> postAuth<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'POST',
      baseUrl: authBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: true,
    );
  }

  static Future<T> postWithoutAuth<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData, {
    bool useAuthBase = false,
  }) {
    return _sendRequest(
      method: 'POST',
      baseUrl: useAuthBase ? authBaseUrl : commerceBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: false,
    );
  }

  static Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'PUT',
      baseUrl: commerceBaseUrl,
      path: path,
      fromData: fromData,
      body: body,
      includeAuth: true,
    );
  }

  static Future<T> delete<T>(
    String path,
    T Function(dynamic) fromData,
  ) async {
    await _ensureValidToken();

    return _sendRequest(
      method: 'DELETE',
      baseUrl: commerceBaseUrl,
      path: path,
      fromData: fromData,
      includeAuth: true,
    );
  }

  static Future<void> _ensureValidToken() async {
    if (_accessToken == null) return;

    if (_tokenExpiry != null &&
        DateTime.now().isAfter(
          _tokenExpiry!.subtract(const Duration(minutes: 5)),
        )) {
      await _refreshAccessToken();
    }
  }

  static Future<void> _refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw ApiException(401, 'No refresh token available');
    }

    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    _isRefreshing = true;

    try {
      debugPrint('BigK: Refreshing access token...');

      final response = await http.post(
        _buildUri(authBaseUrl, authPath('/token')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': authClientId,
        }),
      );

      if (response.statusCode == 401) {
        await clearTokens();
        throw ApiException(401, 'Session expired, please login again');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _exceptionFromResponse(response, 'Token refresh failed');
      }

      final json = _decodeResponseBody(response);
      final accessToken = json['access_token'] ?? json['token'];
      final refreshToken = json['refresh_token'] ?? _refreshToken;
      if (accessToken == null || refreshToken == null) {
        throw ApiException(500, 'Token refresh response is missing tokens');
      }

      final expiresAt = _parseExpiry(
        expiresAt: json['expires_at']?.toString(),
        expiresIn: json['expires_in'],
        fallback: const Duration(hours: 1),
      );

      await saveTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken.toString(),
        expiresAt: expiresAt,
        clientId: authClientId,
      );

      debugPrint('BigK: Token refreshed successfully');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(-1, 'Token refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<T> _sendRequest<T>({
    required String method,
    required String baseUrl,
    required String path,
    required T Function(dynamic) fromData,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    required bool includeAuth,
  }) async {
    if (_shouldUseWalletProxy(baseUrl)) {
      return _sendWalletProxyRequest(
        method: method,
        path: path,
        fromData: fromData,
        body: body,
        queryParams: queryParams,
      );
    }

    if (_shouldUseCommerceProxy(baseUrl)) {
      return _sendCommerceProxyRequest(
        method: method,
        path: path,
        fromData: fromData,
        body: body,
        queryParams: queryParams,
        includeAuth: includeAuth,
      );
    }

    try {
      final request = http.Request(
        method,
        _buildUri(baseUrl, path, queryParams: queryParams),
      )
        ..headers.addAll(_buildHeaders(includeAuth: includeAuth))
        ..body = body == null ? '' : jsonEncode(body);

      final streamed = await request.send();
      final httpResponse = await http.Response.fromStream(streamed);
      return _handleResponse(httpResponse, fromData);
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Future<T> _sendMultipartRequest<T>({
    required String method,
    required String baseUrl,
    required String path,
    Map<String, dynamic>? fields,
    required Uint8List fileBytes,
    required String fileName,
    required String fileField,
    required T Function(dynamic) fromData,
    required bool includeAuth,
  }) async {
    if (_shouldUseWalletProxy(baseUrl)) {
      return _sendWalletProxyMultipartRequest(
        path: path,
        fields: fields,
        fileBytes: fileBytes,
        fileName: fileName,
        fileField: fileField,
        fromData: fromData,
      );
    }

    try {
      final request = http.MultipartRequest(
        method,
        _buildUri(baseUrl, path),
      );
      request.headers.addAll(_buildHeaders(includeAuth: includeAuth));
      request.headers.remove('Content-Type');

      if (fields != null && fields.isNotEmpty) {
        for (final entry in fields.entries) {
          final value = entry.value;
          if (value == null) continue;
          request.fields[entry.key] = value.toString();
        }
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ),
      );

      final streamed = await request.send();
      final httpResponse = await http.Response.fromStream(streamed);
      return _handleResponse(httpResponse, fromData);
    } catch (e) {
      throw _formatError(e);
    }
  }

  static bool _shouldUseWalletProxy(String baseUrl) =>
      kIsWeb && baseUrl == walletBaseUrl;

  static bool _shouldUseCommerceProxy(String baseUrl) =>
      kIsWeb && baseUrl == commerceBaseUrl;

  static Future<Map<String, String>> _getLocalSessionFields() async {
    final loginUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );
    final appToken = await HttpService.getToken();

    if (loginUser == null ||
        loginUser.userid <= 0 ||
        appToken == null ||
        appToken.isEmpty) {
      throw ApiException(401, 'Please login first.');
    }

    return <String, String>{
      'userid': loginUser.userid.toString(),
      'token': appToken,
    };
  }

  static Uri _buildWalletProxyUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${HttpService.baseUrl}$normalizedPath');
  }

  static Uri _buildCommerceProxyUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${HttpService.baseUrl}$normalizedPath');
  }

  static Future<T> _sendWalletProxyRequest<T>({
    required String method,
    required String path,
    required T Function(dynamic) fromData,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final localSession = await _getLocalSessionFields();

    try {
      final response = await http.post(
        _buildWalletProxyUri('/apis/bigkWalletProxy'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          ...localSession,
          'method': method,
          'path': path,
          if (queryParams != null && queryParams.isNotEmpty)
            'query_params': queryParams,
          if (body != null) 'body': body,
          'bigk_access_token': _accessToken ?? '',
        }),
      );

      return _handleResponse(response, fromData);
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Future<T> _sendCommerceProxyRequest<T>({
    required String method,
    required String path,
    required T Function(dynamic) fromData,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    required bool includeAuth,
  }) async {
    final payload = <String, dynamic>{
      'method': method,
      'path': path,
      'requires_auth': includeAuth,
      if (queryParams != null && queryParams.isNotEmpty)
        'query_params': queryParams,
      if (body != null) 'body': body,
    };

    if (includeAuth) {
      payload.addAll(await _getLocalSessionFields());
      payload['bigk_access_token'] = _accessToken ?? '';
    }

    try {
      final response = await http.post(
        _buildCommerceProxyUri('/apis/bigkCommerceProxy'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      return _handleResponse(response, fromData);
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Future<T> _sendWalletProxyMultipartRequest<T>({
    required String path,
    Map<String, dynamic>? fields,
    required Uint8List fileBytes,
    required String fileName,
    required String fileField,
    required T Function(dynamic) fromData,
  }) async {
    final localSession = await _getLocalSessionFields();

    try {
      final request = http.MultipartRequest(
        'POST',
        _buildWalletProxyUri('/apis/bigkWalletMultipartProxy'),
      );

      request.fields.addAll(localSession);
      request.fields['path'] = path;
      request.fields['file_field'] = fileField;
      request.fields['bigk_access_token'] = _accessToken ?? '';
      if (fields != null && fields.isNotEmpty) {
        request.fields['fields_json'] = jsonEncode(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response, fromData);
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Uri _buildUri(
    String baseUrl,
    String path, {
    Map<String, String>? queryParams,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParams);
  }

  static Map<String, String> _buildHeaders({required bool includeAuth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  static T _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromData,
  ) {
    debugPrint(
      'BigK ${response.request?.method} ${response.request?.url.path} - ${response.statusCode}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromResponse(response, 'Request failed');
    }

    try {
      final json = _decodeResponseBody(response);
      return fromData(json);
    } catch (e) {
      throw ApiException(-1, 'Failed to parse response: $e');
    }
  }

  static Map<String, dynamic> _decodeResponseBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'data': decoded};
  }

  static ApiException _exceptionFromResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    try {
      final errorBody = _decodeResponseBody(response);
      final message = errorBody['message'] ??
          errorBody['error_description'] ??
          errorBody['error'] ??
          fallbackMessage;
      return ApiException(response.statusCode, message.toString());
    } catch (_) {
      return ApiException(response.statusCode, fallbackMessage);
    }
  }

  static DateTime _parseExpiry({
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

    final seconds = expiresIn is int
        ? expiresIn
        : int.tryParse(expiresIn?.toString() ?? '');
    if (seconds != null) {
      return DateTime.now().add(Duration(seconds: seconds));
    }

    return DateTime.now().add(fallback);
  }

  static ApiException _formatError(dynamic error) {
    if (error is ApiException) return error;
    return ApiException(-1, 'Network request failed: $error');
  }
}
