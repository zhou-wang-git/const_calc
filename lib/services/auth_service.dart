import 'package:flutter/foundation.dart';

import 'package:const_calc/dto/kcc/kcc_auth.dart';
import 'package:const_calc/dto/login_user.dart';
import 'package:const_calc/services/bigk/bigk_auth_service.dart';
import 'package:const_calc/services/bigk/bigk_cart_service.dart';
import 'package:const_calc/services/bigk/bigk_shop_service.dart';
import 'package:const_calc/services/bigk/bigk_wallet_service.dart';
import 'package:const_calc/services/bigk/bigk_wishlist_service.dart';
import 'package:const_calc/services/cart_service.dart';
import 'package:const_calc/services/kcc/kcc_auth_service.dart';
import 'package:const_calc/services/user_service.dart';

import 'http_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  bool _isLoggedIn = false;
  LoginUser? _loginUser;

  factory AuthService() => _instance;

  AuthService._internal();

  bool get isLoggedIn => _isLoggedIn;

  LoginUser? get loginUser => _loginUser;

  Future<void> init() async {
    final thisUser = await HttpService.getPreferences<LoginUser>(
      'login_user',
      (map) => LoginUser.fromJson(map),
    );

    if (thisUser != null) {
      _loginUser = thisUser;
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
      _loginUser = null;
    }
  }

  Future<LoginUser> login(String username, String password) async {
    final kccSession = await KccAuthService().loginWithPassword(
      identifier: username.trim(),
      password: password,
    );

    final res = await HttpService.post<LoginUser>('/apis/loginByKcc', {
      'access_token': kccSession.tokens.accessToken,
      'id_token': kccSession.tokens.idToken,
      'client_id': kccSession.clientId,
      'token': '',
      'userid': '',
    }, fromData: (json) => LoginUser.fromJson(json));

    _loginUser = res.data!;
    _isLoggedIn = true;
    await HttpService.savePreferences('login_user', _loginUser!.toJson());

    await Future.wait([
      _syncKccSession(fallbackSession: kccSession),
      CartService.syncCartKeyAfterLogin(),
    ]);

    return _loginUser!;
  }

  Future<void> _syncKccSession({
    required KccAuthSession fallbackSession,
  }) async {
    try {
      await BigKAuthService().restoreUnifiedSession(
        accessToken: fallbackSession.tokens.accessToken,
        refreshToken: fallbackSession.tokens.refreshToken,
        expiresAt: fallbackSession.tokens.expiresAt,
        clientId: fallbackSession.clientId,
        profile: fallbackSession.userInfo.toJson(),
      );
      final mallProfile = await BigKAuthService().syncProfile();

      await UserService().syncMallBinding(
        kccUserId:
            mallProfile['sub']?.toString() ?? fallbackSession.userInfo.sub,
        mallEmail:
            mallProfile['email']?.toString() ?? fallbackSession.userInfo.email,
        mallHandle:
            mallProfile['preferred_username']?.toString() ??
            fallbackSession.userInfo.preferredUsername,
        mallDisplayName:
            mallProfile['name']?.toString() ?? fallbackSession.userInfo.name,
        mallClientId: fallbackSession.clientId,
        mallWalletId:
            mallProfile['wallet_id']?.toString() ??
            fallbackSession.userInfo.walletId,
      );

      debugPrint('BigK wallet client session synced to local mall binding');
    } catch (e) {
      debugPrint('BigK wallet client session sync failed: $e');
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _loginUser = null;
    await HttpService.removePreferences('login_user');
    HttpService.clearToken();
    UserService.clearCache();

    await BigKAuthService().logout();
    BigKCartService.clearCache();
    BigKWishlistService.clearCache();
    BigKShopService.clearCache();
    BigKWalletService.clearCache();
  }
}
