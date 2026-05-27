import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../dto/base_response.dart';
import '../handler/api_exception.dart';

class HttpService {
  static const String domain = 'https://app.numforlife.com';
  static const String baseUrl = '$domain/api';
  static const String _tokenKey = 'app_token';
  static String? _token;

  static String? _extractSessionToken(String path, dynamic data) {
    if (data is! Map || data['token'] == null) {
      return null;
    }

    final normalizedPath = path.toLowerCase();
    final isSessionEndpoint = normalizedPath.endsWith('/login') ||
        normalizedPath.endsWith('/loginbykcc') ||
        normalizedPath.endsWith('/refreshtoken');
    if (!isSessionEndpoint) {
      return null;
    }

    final token = data['token'].toString();
    return token.isEmpty ? null : token;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  // 🔹 新增：multipart/form-data 支持文件上传
  static Future<BaseResponse<T>> postMultipart<T>(
      String path, {
        Map<String, String>? fields,      // 任意额外参数
        required Uint8List fileBytes,     // 确保是非空 Uint8List
        required String fileName,
        String fileField = 'file',        // 文件字段名
        T Function(dynamic)? fromData,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      // Token 放 Header（与现有规则一致）
      if (_token != null) {
        request.headers['Token'] = _token!;
      }

      // 额外字段
      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      // 文件（不显式设置 Content-Type，避免额外依赖）
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes as List<int>,          // 如果你的变量是可空，请在调用处加 !
        filename: fileName,
      ));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 401) {
        throw ApiException(401, '登录已过期，请重新登录');
      }
      if (res.statusCode != 200) {
        throw ApiException(res.statusCode, '网络异常：${res.statusCode}');
      }

      final Map<String, dynamic> json = jsonDecode(res.body);
      final baseRes = BaseResponse<T>.fromJson(json, fromData);

      // 若后端返回了新的 token，同步更新（与现有 post/postForm 保持一致）
      final token = _extractSessionToken(path, json['data']);
      if (token != null) {
        _token = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
      }

      _checkCode(baseRes);
      return baseRes;
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Future<BaseResponse<T>> post<T>(
      String path,
      Map<String, dynamic> body, {
        T Function(dynamic)? fromData,
      }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Token': _token!,
        },
        body: jsonEncode(body),
      );

      print('POST $path - Status: ${res.statusCode}');
      print('Response body: ${res.body}');

      if (res.statusCode == 401) {
        throw ApiException(401, '登录已过期，请重新登录');
      }

      // 先解析响应体，即使状态码不是200
      final json = jsonDecode(res.body);

      if (res.statusCode != 200) {
        // 尝试从响应体中获取错误信息
        final errorMsg = json['msg'] ?? json['message'] ?? '网络异常：${res.statusCode}';
        print('HTTP Error: $errorMsg');
        throw ApiException(res.statusCode, errorMsg);
      }

      final baseRes = BaseResponse<T>.fromJson(json, fromData);

      final token = _extractSessionToken(path, json['data']);
      if (token != null) {
        _token = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
      }

      _checkCode(baseRes);
      return baseRes;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      throw _formatError(e);
    }
  }

  static Future<BaseResponse<T>> postForm<T>(
      String path,
      Map<String, String> formData, {
        T Function(dynamic)? fromData,
      }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (_token != null) 'Token': _token!,
      },
      body: formData,
    );

    // 检查响应状态码
    if (res.statusCode == 401) {
      throw ApiException(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, '网络异常：${res.statusCode}');
    }

    // 检查响应体是否为空
    if (res.body.isEmpty) {
      throw ApiException(res.statusCode, '响应体为空');
    }

    // 捕获 JSON 解析异常
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (e) {
      throw ApiException(res.statusCode, 'JSON 解析失败: $e');
    }

    // 解析响应数据
    final baseRes = BaseResponse<T>.fromJson(json, fromData);

    // 处理 token
    final token = _extractSessionToken(path, json['data']);
    if (token != null) {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
    }

    // 检查响应代码
    _checkCode(baseRes);
    return baseRes;
  }


  static Future<BaseResponse<T>> get<T>(
      String path, {
        T Function(dynamic)? fromData,
      }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _token != null ? {'Token': _token!} : {},
      );

      if (res.statusCode == 401) {
        throw ApiException(401, '登录已过期，请重新登录');
      }
      if (res.statusCode != 200) {
        throw ApiException(res.statusCode, '网络异常：${res.statusCode}');
      }

      final json = jsonDecode(res.body);
      final baseRes = BaseResponse<T>.fromJson(json, fromData);
      _checkCode(baseRes);
      return baseRes;
    } catch (e) {
      throw _formatError(e);
    }
  }

  static void _checkCode(BaseResponse res) {
    if (res.code != 1) {
      throw ApiException(res.code, res.msg);
    }
  }

  static ApiException _formatError(dynamic e) {
    if (e is ApiException) return e;
    return ApiException(500, '网络请求失败，请检查您的网络连接');
  }

  static void clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  static Future<void> savePreferences(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(data));
  }

  static Future<T?> getPreferences<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;

    try {
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        return fromJson(map);
      }
    } catch (e) {
      // 可选：打印错误日志
      debugPrint('getPreferences error: $e');
    }

    return null;
  }

  static Future<void> removePreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

}
