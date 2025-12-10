import 'package:const_calc/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../pages/login/login_page.dart';
import '../services/http_service.dart';

class AuthManager {
  static Future<void> logout(BuildContext context) async {
    HttpService.clearToken();
    await AuthService().logout();

    await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
