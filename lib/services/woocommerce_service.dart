import 'dart:convert';
import 'package:http/http.dart' as http;
import '../handler/api_exception.dart';

/// WooCommerce REST API 基础服务
/// 处理与 WooCommerce 商城的所有 HTTP 通信
class WooCommerceService {
  // API 配置（从 context 读取）
  static const String baseUrl = 'https://numforlife.com/wp-json/wc/v3';
  static const String _consumerKey = 'ck_a980a851118b1821726c87f9a08042f53bf84d97';
  static const String _consumerSecret = 'cs_bbd6699c0fd90102ca312ff23213a0c07203f9c4';

  /// 生成 Basic Auth 头
  static String _getAuthHeader() {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return 'Basic $credentials';
  }

  /// GET 请求
  static Future<T> get<T>(
    String path,
    T Function(dynamic data) fromData,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': _getAuthHeader(),
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'WooCommerce API 错误';
        throw ApiException(response.statusCode, message);
      }

      final json = jsonDecode(response.body);
      return fromData(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(-1, '网络请求失败: $e');
    }
  }

  /// POST 请求
  static Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic data) fromData,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': _getAuthHeader(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'WooCommerce API 错误';
        throw ApiException(response.statusCode, message);
      }

      final json = jsonDecode(response.body);
      return fromData(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(-1, '网络请求失败: $e');
    }
  }

  /// PUT 请求
  static Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic data) fromData,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': _getAuthHeader(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'WooCommerce API 错误';
        throw ApiException(response.statusCode, message);
      }

      final json = jsonDecode(response.body);
      return fromData(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(-1, '网络请求失败: $e');
    }
  }

  /// DELETE 请求
  static Future<T> delete<T>(
    String path,
    T Function(dynamic data) fromData,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': _getAuthHeader(),
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'WooCommerce API 错误';
        throw ApiException(response.statusCode, message);
      }

      final json = jsonDecode(response.body);
      return fromData(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(-1, '网络请求失败: $e');
    }
  }
}
