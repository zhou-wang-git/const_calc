import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login/login_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AuthService().isLoggedIn) {
      return child;
    } else {
      return const LoginPage(); // 未登录返回登录页
    }
  }
}
