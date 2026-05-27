import 'package:const_calc/dto/user.dart';
import 'package:const_calc/dto/bigk/bigk_auth.dart';

import '../dto/login_user.dart';
import 'http_service.dart';

class UserService {
  static User? _cachedUser;
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Future<User?> getUserInfo() async {
    if (_cachedUser != null) return _cachedUser;

    final thisUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );
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

  Future<User?> refreshUserInfo() async {
    final thisUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );
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

  Future<MallBinding> syncMallBinding({
    required String kccUserId,
    required String mallEmail,
    required String mallHandle,
    required String mallDisplayName,
    required String mallClientId,
    required String mallWalletId,
    String? mallPassword,
  }) async {
    final thisUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );
    if (thisUser?.userid == null) {
      throw Exception('当前未登录 App 账号');
    }

    final token = await HttpService.getToken();
    final res = await HttpService.post<MallBinding>(
      '/apis/bindMallAccount',
      {
        'token': token,
        'userid': thisUser?.userid,
        'kcc_user_id': kccUserId,
        'mall_email': mallEmail,
        'mall_handle': mallHandle,
        'mall_display_name': mallDisplayName,
        'mall_client_id': mallClientId,
        'mall_wallet_id': mallWalletId,
        if (mallPassword != null && mallPassword.isNotEmpty)
          'mall_password': mallPassword,
      },
      fromData: (json) =>
          MallBinding.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (_cachedUser != null && res.data != null) {
      final userJson = _cachedUser!.toJson();
      userJson['mall_binding'] = res.data!.toJson();
      _cachedUser = User.fromJson(userJson);
    }

    return res.data ?? const MallBinding();
  }

  Future<BigKLoginResponse> issueMallSession() async {
    final thisUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );
    if (thisUser?.userid == null) {
      throw Exception('当前未登录 App 账号');
    }

    final token = await HttpService.getToken();
    final res = await HttpService.post<BigKLoginResponse>(
      '/apis/issueMallSession',
      {
        'token': token,
        'userid': thisUser?.userid,
      },
      fromData: (json) =>
          BigKLoginResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (res.data == null) {
      throw Exception('商城会话创建失败');
    }

    return res.data!;
  }

  static User? getCachedUser() {
    return _cachedUser;
  }

  static void clearCache() {
    _cachedUser = null;
  }
}
