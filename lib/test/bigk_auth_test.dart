import 'package:flutter/material.dart';
import '../services/bigk/bigk_auth_service.dart';
import '../services/bigk/bigk_http_service.dart';
import '../services/bigk/bigk_wallet_service.dart';

/// BigK 认证测试工具
/// 用于测试 App 用户账号是否能登录 BigK
class BigKAuthTest {
  /// 测试登录
  ///
  /// 参数：
  /// - identifier: 用户邮箱或用户名
  /// - password: 密码
  ///
  /// 返回测试结果
  static Future<BigKTestResult> testLogin({
    required String identifier,
    required String password,
  }) async {
    final result = BigKTestResult();

    try {
      // 1. 初始化服务
      debugPrint('========================================');
      debugPrint('BigK 登录测试开始');
      debugPrint('========================================');
      debugPrint('测试账号: $identifier');
      debugPrint('');

      await BigKHttpService.init();
      await BigKAuthService().init();

      result.steps.add('✅ 服务初始化成功');

      // 2. 尝试登录
      debugPrint('步骤 1: 调用 BigK 登录接口...');
      final loginResponse = await BigKAuthService().login(identifier, password);

      result.steps.add('✅ 登录成功');
      result.success = true;

      // 3. 检查返回数据
      debugPrint('');
      debugPrint('登录响应:');
      debugPrint('  - Token: ${loginResponse.token.substring(0, 20)}...');
      debugPrint('  - Refresh Token: ${loginResponse.refreshToken.substring(0, 20)}...');
      debugPrint('  - Token 过期时间: ${loginResponse.expiresAt}');
      debugPrint('  - Refresh Token 过期时间: ${loginResponse.refreshExpiresAt}');

      result.steps.add('✅ Token 获取成功');
      result.accessToken = loginResponse.token;
      result.refreshToken = loginResponse.refreshToken;
      result.expiresAt = loginResponse.expiresAt;

      // 4. 检查钱包信息
      if (loginResponse.wallet != null) {
        final wallet = loginResponse.wallet!;
        debugPrint('');
        debugPrint('钱包信息:');
        debugPrint('  - Wallet ID: ${wallet.id}');
        debugPrint('  - Handle: ${wallet.handle ?? "未设置"}');
        debugPrint('  - Display Name: ${wallet.displayName ?? "未设置"}');
        debugPrint('  - Email: ${wallet.email ?? "未设置"}');
        debugPrint('  - External ID: ${wallet.externalId ?? "未设置"}');

        result.steps.add('✅ 钱包信息获取成功');
        result.walletId = wallet.id;
        result.walletHandle = wallet.handle;
        result.walletEmail = wallet.email;
      } else {
        debugPrint('');
        debugPrint('⚠️  警告: 登录响应中没有钱包信息');
        result.steps.add('⚠️  钱包信息缺失');
      }

      // 5. 测试获取钱包详情
      debugPrint('');
      debugPrint('步骤 2: 测试获取钱包详情...');
      try {
        final walletDetail = await BigKWalletService.getWallet();

        debugPrint('');
        debugPrint('钱包详情:');
        debugPrint('  - 余额: ${walletDetail.balanceFormatted} KCC');
        debugPrint('  - 会员等级: ${walletDetail.tierName}');
        debugPrint('  - 状态: ${walletDetail.state}');
        debugPrint('  - 创建时间: ${walletDetail.createdAt}');

        result.steps.add('✅ 钱包详情获取成功');
        result.balance = walletDetail.balance;
        result.tier = walletDetail.tier;
      } catch (e) {
        debugPrint('⚠️  获取钱包详情失败: $e');
        result.steps.add('⚠️  钱包详情获取失败: $e');
      }

      // 6. 检查认证状态
      debugPrint('');
      debugPrint('步骤 3: 检查认证状态...');
      final isLinked = BigKAuthService().isLinked;
      debugPrint('  - isLinked: $isLinked');
      debugPrint('  - 存储的 wallet_id: ${BigKAuthService().walletId}');

      result.steps.add('✅ 认证状态检查完成');

      // 测试总结
      debugPrint('');
      debugPrint('========================================');
      debugPrint('✅ 测试通过！');
      debugPrint('========================================');
      debugPrint('');
      debugPrint('关键信息:');
      debugPrint('  - Wallet ID: ${result.walletId}');
      debugPrint('  - Handle: ${result.walletHandle ?? "未设置"}');
      debugPrint('  - 余额: ${result.balance} KCC');
      debugPrint('  - 会员等级: ${result.tier}');
      debugPrint('');
      debugPrint('后续步骤:');
      debugPrint('  1. 将 wallet_id (${result.walletId}) 存储到你们的后台数据库');
      debugPrint('  2. 在支付成功后，后台调用 BigK Mint API 充值');
      debugPrint('  3. App 刷新余额显示');
      debugPrint('========================================');

    } catch (e, stackTrace) {
      result.success = false;
      result.error = e.toString();
      result.stackTrace = stackTrace.toString();

      debugPrint('');
      debugPrint('========================================');
      debugPrint('❌ 测试失败！');
      debugPrint('========================================');
      debugPrint('错误信息: $e');
      debugPrint('');

      // 分析错误原因
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('可能的原因:');
        debugPrint('  1. 用户账号未在 BigK 系统中注册');
        debugPrint('  2. 密码错误');
        debugPrint('  3. BigK 和你们的系统用户数据未同步');
        debugPrint('');
        debugPrint('解决方案:');
        debugPrint('  - 检查该用户是否已在 BigK 注册');
        debugPrint('  - 确认是否需要先调用 BigK 注册接口');
        result.steps.add('❌ 认证失败 - 用户可能未注册');
      } else if (e.toString().contains('Network') || e.toString().contains('Connection')) {
        debugPrint('可能的原因:');
        debugPrint('  1. 网络连接问题');
        debugPrint('  2. BigK 服务器无法访问');
        debugPrint('  3. API 地址错误');
        result.steps.add('❌ 网络错误');
      } else {
        debugPrint('未知错误，请查看详细日志');
        result.steps.add('❌ 未知错误: $e');
      }

      debugPrint('========================================');
    }

    return result;
  }

  /// 清理测试数据（登出）
  static Future<void> cleanup() async {
    await BigKAuthService().logout();
    debugPrint('✅ 测试数据已清理');
  }
}

/// 测试结果
class BigKTestResult {
  bool success = false;
  List<String> steps = [];
  String? error;
  String? stackTrace;

  // 登录信息
  String? accessToken;
  String? refreshToken;
  DateTime? expiresAt;

  // 钱包信息
  int? walletId;
  String? walletHandle;
  String? walletEmail;
  double? balance;
  String? tier;

  /// 生成测试报告
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('BigK 登录测试报告');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('测试结果: ${success ? "✅ 通过" : "❌ 失败"}');
    buffer.writeln('');

    if (success) {
      buffer.writeln('钱包信息:');
      buffer.writeln('  - Wallet ID: $walletId');
      buffer.writeln('  - Handle: ${walletHandle ?? "未设置"}');
      buffer.writeln('  - Email: ${walletEmail ?? "未设置"}');
      buffer.writeln('  - 余额: ${balance ?? 0} KCC');
      buffer.writeln('  - 会员等级: ${tier ?? "未知"}');
      buffer.writeln('');
      buffer.writeln('Token 信息:');
      buffer.writeln('  - 过期时间: $expiresAt');
    } else {
      buffer.writeln('错误信息:');
      buffer.writeln('  $error');
    }

    buffer.writeln('');
    buffer.writeln('执行步骤:');
    for (var step in steps) {
      buffer.writeln('  $step');
    }

    return buffer.toString();
  }
}
