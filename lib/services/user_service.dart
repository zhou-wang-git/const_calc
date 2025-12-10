import 'package:const_calc/dto/user.dart';

import '../dto/login_user.dart';
import 'http_service.dart';

class UserService {
  static User? _cachedUser;
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// 获取用户信息（优先返回缓存）
  Future<User?> getUserInfo() async {
    if (_cachedUser != null) return _cachedUser;

    final thisUser = await HttpService.getPreferences<LoginUser>("login_user", (map) => LoginUser.fromJson(map));
    if (thisUser?.userid == null) {
      return null;
    }

    final token = await HttpService.getToken();
    final res = await HttpService.post<User>(
      '/apis/getUserInfo',
      {
        'token': token,
        'userid': thisUser?.userid,
      },
      fromData: (json) => User.fromJson(json),
    );

    _cachedUser = res.data;
    return _cachedUser;
  }

  /// 强制从服务器刷新用户信息（忽略缓存）
  Future<User?> refreshUserInfo() async {
    final thisUser = await HttpService.getPreferences<LoginUser>("login_user", (map) => LoginUser.fromJson(map));
    if (thisUser?.userid == null) {
      return null;
    }

    final token = await HttpService.getToken();
    final res = await HttpService.post<User>(
      '/apis/getUserInfo',
      {
        'token': token,
        'userid': thisUser?.userid,
      },
      fromData: (json) => User.fromJson(json),
    );

    _cachedUser = res.data;
    return _cachedUser;
  }

  /// 获取当前缓存的用户（不请求网络）
  static User? getCachedUser() {
    return _cachedUser;
  }

  static void clearCache() {
    _cachedUser = null;
  }
}
