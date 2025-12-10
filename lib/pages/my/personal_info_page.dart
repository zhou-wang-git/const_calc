import 'package:const_calc/dto/user.dart';
import 'package:const_calc/pages/my/select_avatar_page.dart';
import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/services/my_service.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/http_util.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';

import '../login/login_page.dart';
import 'edit_user_info_page.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPage();
}

class _PersonalInfoPage extends State<PersonalInfoPage> {
  static const vipMapper = {1: '基础会员', 2: '精英会员', 3: '至尊会员'};

  User? _userInfo;

  @override
  void initState() {
    super.initState();
    // 页面加载完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initUserInfo();
    });
  }

  Future<void> initUserInfo() async {
    UserService.clearCache();
    final User? user = await UserService().getUserInfo();
    setState(() {
      _userInfo = user;
    });
  }

  Future<void> _onDeleteAccountTap() async {
    final confirmed = await _showDeleteConfirmDialog(context);
    if (confirmed != true) return;

    if (!mounted) return;
    await HttpUtil.request<void>(
      () => MyService.getMemberDelete(),
      context,
      () => mounted,
    );

    if (!mounted) return;
    MessageUtil.info(context, '账户已注销');

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black;
    final contentColor = isDark ? Colors.white70 : Colors.black87;
    final cancelColor = isDark ? Colors.white60 : Colors.grey[600];
    final confirmColor = isDark ? const Color(0xFFFFD54F) : theme.primaryColor;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Center(
          child: Text(
            '提示',
            style: TextStyle(color: titleColor),
          ),
        ),
        content: Text(
          '确认注销此账户吗？注销后无法找回',
          style: TextStyle(color: contentColor),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 17,
                color: cancelColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '确定',
              style: TextStyle(
                fontSize: 17,
                color: confirmColor,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final buttonFgColor = isDark ? Colors.white70 : Colors.black87;
    final buttonBorderColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('个人信息'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部横幅 + 头像/昵称/等级
            Container(
              width: double.infinity,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 头像
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectAvatarPage(),
                        ),
                      ).then((changed) {
                        if (changed == true && mounted) {
                          initUserInfo();
                        }
                      });
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.cardTheme.color,
                      child: ClipOval(
                        child: Image.network(
                          '${HttpService.domain}/${_userInfo?.avatar ?? ''}',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 昵称 + 会员等级
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userInfo?.realName ?? '',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vipMapper[_userInfo?.vipLevelId] ?? '基础会员',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // ⬅️ 新增：把按钮顶到最右
                  const Spacer(),

                  // 右侧"注销账户"按钮
                  OutlinedButton.icon(
                    onPressed: _onDeleteAccountTap,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('注销账户', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonFgColor,
                      side: BorderSide(color: buttonBorderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 统计条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? theme.cardTheme.color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFEDEDED)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCell(
                      value: '${_userInfo?.num ?? '0'}',
                      label: '数字测算次数',
                    ),
                    _StatCell(
                      value: '${_userInfo?.login ?? '0'}',
                      label: '登入次数',
                    ),
                    _StatCell(
                      // ✅ 更稳：按'-'分割取年份，避免空值/长度问题
                      value:
                          _userInfo?.vipSubscriptionStart.split('-').first ??
                          '',
                      label: '会员开始',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 主卡片区域
            Column(
                children: [
                  // 白卡1：两行左右 + 整行邮箱（同一张卡）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _InnerCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _InfoGridTile(
                                iconAsset: 'assets/icons/ic_user.png',
                                text: _userInfo?.realName ?? '',
                                editable: true,
                                onEditTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditUserInfoPage(
                                        fieldKey: EditFieldType.name,
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true && mounted) {
                                      initUserInfo();
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoGridTile(
                                iconAsset: 'assets/icons/share.png',
                                text: _userInfo?.sex == '2' ? '男' : '女',
                                editable: true,
                                onEditTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditUserInfoPage(
                                        fieldKey: EditFieldType.gender,
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true && mounted) {
                                      initUserInfo();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoGridTile(
                                iconAsset: 'assets/icons/document.png',
                                text: _userInfo?.year == null
                                    ? ''
                                    : '${_userInfo?.year}-${_userInfo?.month}-${_userInfo?.day}',
                                editable: true,
                                onEditTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditUserInfoPage(
                                        fieldKey: EditFieldType.birthDate,
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true && mounted) {
                                      initUserInfo();
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoGridTile(
                                iconAsset: 'assets/icons/clock.png',
                                text: _userInfo?.birthTime ?? '',
                                editable: true,
                                onEditTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditUserInfoPage(
                                        fieldKey: EditFieldType.birthTime,
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true && mounted) {
                                      initUserInfo();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoFullTile(
                          iconAsset: 'assets/icons/email.png',
                          text: _userInfo?.email ?? '',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 白卡2：三条整行
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _InnerCard(
                      children: [
                        _InfoFullTile(
                          iconAsset: 'assets/icons/padlock.png',
                          text: vipMapper[_userInfo?.vipLevelId] ?? '基础会员',
                        ),
                        const SizedBox(height: 8),
                        _InfoFullTile(
                          iconAsset: 'assets/icons/clock2.png',
                          text: _userInfo?.vipSubscriptionStart ?? '',
                        ),
                        const SizedBox(height: 8),
                        if (_userInfo != null &&
                            _userInfo?.order != null &&
                            _userInfo?.order?.vipDate != null) ...[
                          const SizedBox(height: 8),
                          _InfoFullTile(
                            iconAsset: 'assets/icons/shield.png',
                            text: _userInfo?.order?.vipDate ?? '', // 这里已经判空，安全
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 小统计格子
class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: secondaryColor),
        ),
      ],
    );
  }
}

/// 内层白卡（无外边距、轻边框，不要阴影）
class _InnerCard extends StatelessWidget {
  final List<Widget> children;

  const _InnerCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final borderColor = isDark ? Colors.white24 : const Color(0xFFEDEDED);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }
}

/// 两列网格项（含编辑铅笔）
class _InfoGridTile extends StatelessWidget {
  final String iconAsset;
  final String text;
  final bool editable;

  /// 点击铅笔图标的回调
  final VoidCallback? onEditTap;

  const _InfoGridTile({
    required this.iconAsset,
    required this.text,
    this.editable = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);
    final borderColor = isDark ? theme.dividerColor : const Color(0xFFEDEDED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _CircleIcon(asset: iconAsset),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (editable)
            GestureDetector(
              onTap: onEditTap, // 点击时调用外部传入的方法
              child: Image.asset(
                'assets/icons/alter.png',
                width: 16,
                height: 16,
                color: isDark ? Colors.white54 : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// 整行信息项（含可选编辑）
class _InfoFullTile extends StatelessWidget {
  final String iconAsset;
  final String text;

  const _InfoFullTile({required this.iconAsset, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);
    final borderColor = isDark ? theme.dividerColor : const Color(0xFFEDEDED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // 更矮
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _CircleIcon(asset: iconAsset),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textColor), // 小字体
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 左侧圆形图标（留出你方图片位）
class _CircleIcon extends StatelessWidget {
  final String asset;

  const _CircleIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          color: isDark ? Colors.white : null,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
