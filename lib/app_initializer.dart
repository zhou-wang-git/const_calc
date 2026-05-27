import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:const_calc/services/auth_service.dart';
import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/services/theme_service.dart';
import 'package:const_calc/services/iap_service.dart';
import 'package:const_calc/services/bigk/bigk_http_service.dart';
import 'package:const_calc/services/bigk/bigk_auth_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class AppInitializer {
  static Future<void> init() async {
    // 测试环境密钥
    // Stripe.publishableKey = 'pk_test_51QyePb4YhRSjGdz05NtzFuik8AcBKhpNKt9s1m2NwpM3L9TrErUxolNL83fGhZrfPNOt5hpy2Rt8SsnkPuqaky3u00nwEYwYAF';
    // 生产环境密钥
    Stripe.publishableKey = 'pk_live_51QyePWG3pGJkemVhkbMtoctQykpByqrsqX8bMShmmFRJu6TF5bjAz3qpb1njYJIFkqCGR2YqLEan3Ew330KGD24e00EerGIXba';
    await Stripe.instance.applySettings();

    await HttpService.init();
    await AuthService().init();
    await ThemeService().init();

    // 初始化 BigK 服务
    await BigKHttpService.init();
    await BigKAuthService().init();

    // 初始化 IAP 服务（仅移动端，Web 不支持）
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      await IAPService().initialize();
    }
  }
}
