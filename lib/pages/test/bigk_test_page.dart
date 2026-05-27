import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../test/bigk_auth_test.dart';

/// BigK 测试页面
/// 用于测试 BigK 登录功能
class BigKTestPage extends StatefulWidget {
  const BigKTestPage({super.key});

  @override
  State<BigKTestPage> createState() => _BigKTestPageState();
}

class _BigKTestPageState extends State<BigKTestPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isTesting = false;
  BigKTestResult? _result;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入账号和密码')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _result = null;
    });

    try {
      final result = await BigKAuthTest.testLogin(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isTesting = false;
        });

        // 显示结果提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? '✅ 测试通过' : '❌ 测试失败'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试异常: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanup() async {
    await BigKAuthTest.cleanup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 测试数据已清理')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BigK 登录测试'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _cleanup,
              tooltip: '清理测试数据',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            _buildInfoCard(isDark),
            SizedBox(height: 16.h),

            // 输入表单
            _buildInputCard(theme, isDark),
            SizedBox(height: 16.h),

            // 测试按钮
            _buildTestButton(theme),
            SizedBox(height: 24.h),

            // 测试结果
            if (_result != null) _buildResultCard(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '测试说明',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '此工具用于测试 App 用户账号是否能登录 BigK 系统。\n\n'
            '测试内容：\n'
            '1. 调用 BigK 登录接口\n'
            '2. 获取 Access Token 和 Refresh Token\n'
            '3. 获取钱包信息（wallet_id, balance 等）\n'
            '4. 验证认证状态\n\n'
            '请使用 App 的真实用户账号进行测试。',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '测试账号',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          // 账号输入
          TextField(
            controller: _identifierController,
            decoration: InputDecoration(
              labelText: '邮箱或用户名',
              hintText: '输入 App 用户的邮箱或用户名',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16.h),

          // 密码输入
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(ThemeData theme) {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isTesting ? null : _runTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isTesting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '测试中...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                '开始测试',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, bool isDark) {
    final result = _result!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: result.success ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                result.success ? '测试通过' : '测试失败',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: result.success ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 成功结果
          if (result.success) ...[
            _buildResultSection('钱包信息', [
              _buildResultItem('Wallet ID', '${result.walletId}', canCopy: true),
              _buildResultItem('Handle', result.walletHandle ?? '未设置'),
              _buildResultItem('Email', result.walletEmail ?? '未设置'),
              _buildResultItem('余额', '${result.balance ?? 0} KCC'),
              _buildResultItem('会员等级', result.tier ?? '未知'),
            ], isDark),
            SizedBox(height: 16.h),
            _buildResultSection('Token 信息', [
              _buildResultItem('过期时间', result.expiresAt?.toString() ?? '未知'),
            ], isDark),
            SizedBox(height: 16.h),
            _buildNextSteps(isDark),
          ],

          // 失败结果
          if (!result.success) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '错误信息:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    result.error ?? '未知错误',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 执行步骤
          SizedBox(height: 16.h),
          Text(
            '执行步骤:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          ...result.steps.map((step) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              )),

          // 复制报告按钮
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.generateReport()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('测试报告已复制到剪贴板')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制完整报告'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }

  Widget _buildResultItem(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canCopy)
            IconButton(
              icon: Icon(Icons.copy, size: 16.w),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已复制: $value')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNextSteps(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ 后续步骤:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '1. 将 wallet_id 存储到后台数据库\n'
            '2. 在支付成功回调中调用 BigK Mint API\n'
            '3. App 刷新余额显示\n'
            '4. 测试完整充值流程',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
