import 'package:const_calc/dto/login_user.dart';
import 'package:const_calc/services/user_service.dart';
import 'http_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  bool _isLoggedIn = false;
  LoginUser? _loginUser;

  factory AuthService() => _instance;

  AuthService._internal();

  /// 同步获取是否登录
  bool get isLoggedIn => _isLoggedIn;

  /// 同步获取当前登录用户
  LoginUser? get loginUser => _loginUser;

  /// 启动时初始化登录状态（在 main() 中调用）
  Future<void> init() async {
    final thisUser = await HttpService.getPreferences<LoginUser>("login_user", (map) => LoginUser.fromJson(map));

    if (thisUser != null) {
      _loginUser = thisUser;
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
      _loginUser = null;
    }
  }

  /// 登录：更新状态并缓存
  Future<LoginUser> login(String username, String password) async {
    final res = await HttpService.post<LoginUser>(
      '/apis/login',
      {
        'username': username,
        'password': password,
        'token': '',
        'userid': '',
      },
      fromData: (json) => LoginUser.fromJson(json),
    );
    _loginUser = res.data!;
    _isLoggedIn = true;
    await HttpService.savePreferences("login_user", _loginUser!.toJson());
    return _loginUser!;
  }

  /// 登出：清空状态和缓存
  Future<void> logout() async {
    _isLoggedIn = false;
    _loginUser = null;
    await HttpService.removePreferences("login_user");
    HttpService.clearToken();
    UserService.clearCache();
  }
}
