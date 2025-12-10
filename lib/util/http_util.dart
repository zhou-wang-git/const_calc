import 'package:flutter/material.dart';

import '../handler/api_exception.dart';
import 'auth_manager.dart';
import 'dialog_util.dart';
import 'loading_util.dart';
import 'message_util.dart';

class HttpUtil {
  static Future<T?> request<T>(
      Future<T> Function() handler,
      BuildContext context,
      [bool Function()? isMounted]
      ) async {
    try {
      LoadingUtil.openLoading(context); // ✅ 自动 loading
      final result = await handler();   // ✅ 正常请求
      return result;
    } on ApiException catch (e) {
      if (e.code == 401) {
        if (isMounted?.call() ?? true) {
          // 先关闭 loading，再显示弹窗
          LoadingUtil.closeLoading();
          // ignore: use_build_context_synchronously
          await DialogUtil.alert(
            context,
            title: '登录已过期',
            content: '请重新登录',
            buttonText: '确定',
          );
          // ignore: use_build_context_synchronously
          AuthManager.logout(context);
        }
      } else {
        if (isMounted?.call() ?? true) {
          // ignore: use_build_context_synchronously
          MessageUtil.info(context, e.message);
        }
      }
      rethrow; // ❗继续抛出，阻断调用方执行
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      if (isMounted?.call() ?? true) {
        // ignore: use_build_context_synchronously
        MessageUtil.info(context, '网络请求失败');
      }
      rethrow; // ❗继续抛出，阻断调用方执行
    } finally {
      if (isMounted?.call() ?? true) {
        LoadingUtil.closeLoading(); // ✅ 确保关闭 loading
      }
    }
  }
}
