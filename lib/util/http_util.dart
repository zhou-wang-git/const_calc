import 'package:flutter/material.dart';

import '../handler/api_exception.dart';
import '../services/auth_service.dart';
import 'auth_manager.dart';
import 'dialog_util.dart';
import 'loading_util.dart';
import 'message_util.dart';

class HttpUtil {
  static Future<T?> request<T>(
    Future<T> Function() handler,
    BuildContext context, [
    bool Function()? isMounted,
  ]) async {
    try {
      LoadingUtil.openLoading(context);
      final result = await handler();
      return result;
    } on ApiException catch (e) {
      final lowerMessage = e.message.toLowerCase();
      final shouldForceLogout = e.code == 401 &&
          AuthService().isLoggedIn &&
          (e.message.contains('过期') ||
              lowerMessage.contains('expired') ||
              lowerMessage.contains('session') ||
              lowerMessage.contains('token'));

      if (shouldForceLogout) {
        if (isMounted?.call() ?? true) {
          LoadingUtil.closeLoading();
          await DialogUtil.alert(
            context,
            title: '登录已过期',
            content: '请重新登录',
            buttonText: '确定',
          );
          AuthManager.logout(context);
        }
      } else {
        if (isMounted?.call() ?? true) {
          MessageUtil.info(context, e.message);
        }
      }
      rethrow;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      if (isMounted?.call() ?? true) {
        MessageUtil.info(context, '网络请求失败');
      }
      rethrow;
    } finally {
      if (isMounted?.call() ?? true) {
        LoadingUtil.closeLoading();
      }
    }
  }
}
