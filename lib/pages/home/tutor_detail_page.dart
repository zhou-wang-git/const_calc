import 'package:auto_size_text/auto_size_text.dart';
import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/Tutor.dart';

final Map<int, String> gradeMapper = {1: '启蒙导师', 2: '大宗导师', 3: '传承导师'};

class TutorDetailPage extends StatelessWidget {
  final Tutor tutor;

  const TutorDetailPage({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final subTextColor =
        theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87);
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.appBarTheme.iconTheme?.color ?? textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '导师详情',
          style: theme.appBarTheme.titleTextStyle ??
              TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              // 头像 + 姓名 + 标签 + 地区 + 价格
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: Image.network(
                        '${HttpService.domain}${tutor.avatar}',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/icons/avatar.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.chineseName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 25,
                            child: Transform.translate(
                              offset: const Offset(0, -4),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Image.asset(
                                    'assets/icons/zs.png',
                                    fit: BoxFit.contain,
                                    height: 25,
                                    color: isDark ? Colors.white70 : null,
                                  ),
                                  Positioned(
                                    left: 30,
                                    child: Text(
                                      gradeMapper[tutor.gradeId] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0XFFBF6D1C),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/icons/location.png',
                                    height: 16,
                                    color: isDark ? Colors.white70 : null),
                                const SizedBox(width: 8),
                                Text(
                                  tutor.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '\$ /时',
                        // 金额直接使用 tutor.hourlyConsultationFee
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 服务领域
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Row(
                  children: [
                    Text(
                      '服务领域：',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: AutoSizeText(
                        tutor.tagNames.replaceAll(',', ' | '),
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                        ),
                        maxLines: 1,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 认证模块
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(isDark ? 0.5 : 0.2),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/rzicon.png',
                              height: 20,
                              color: isDark ? Colors.white : null),
                          const SizedBox(width: 6),
                          Text(
                            '认证导师',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AutoSizeText(
                              '平台独家认证，并通过严格考核的高实力咨询师',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              minFontSize: 8,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            'assets/icons/exp.png',
                            '${tutor.experienceYears}',
                            '从业年限',
                            textColor: textColor,
                            subTextColor: subTextColor,
                            iconColor: isDark ? Colors.white70 : null,
                          ),
                          _buildInfoItem(
                            'assets/icons/gender.png',
                            tutor.sex == 2 ? '男' : '女',
                            '性别',
                            textColor: textColor,
                            subTextColor: subTextColor,
                            iconColor: isDark ? Colors.white70 : null,
                          ),
                          _buildInfoItem(
                            'assets/icons/zodiac.png',
                            tutor.levelName,
                            '等级',
                            textColor: textColor,
                            subTextColor: subTextColor,
                            iconColor: isDark ? Colors.white70 : null,
                          ),
                          _buildInfoItem(
                            'assets/icons/tel.png',
                            tutor.contactNum.toString(),
                            '联系次数',
                            textColor: textColor,
                            subTextColor: subTextColor,
                            iconColor: isDark ? Colors.white70 : null,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _BotconItem(label: '平台认证'),
                          _BotconItem(label: '能力评估'),
                          _BotconItem(label: '平台优选'),
                          _BotconItem(label: '优质服务'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 个人介绍模块
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(isDark ? 0.8 : 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/img4.png',
                              height: 18, width: 18, color: isDark ? Colors.white70 : null),
                          const SizedBox(width: 8),
                          Text(
                            '个人介绍',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset('assets/icons/img4.png',
                              height: 18, width: 18, color: isDark ? Colors.white70 : null),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Text(
                        tutor.background,
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ContactDialog(tutor: tutor),
                      );
                    },
                    child: const Text(
                      '点击查看联系方式',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String iconPath, String value, String label,
      {required Color textColor, required Color subTextColor, Color? iconColor}) {
    return Column(
      children: [
        Image.asset(iconPath, height: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
      ],
    );
  }
}

class _BotconItem extends StatelessWidget {
  final String label;
  const _BotconItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black87);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/botcon_icon.png',
          height: 18,
        ),
        const SizedBox(width: 6),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
class ContactDialog extends StatefulWidget {
  final Tutor tutor;
  const ContactDialog({super.key, required this.tutor});

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  final List<String> tabs = ['微信', 'WA', 'Line', '邮件', '电话'];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final subColor =
        theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.grey);
    final primaryColor = theme.colorScheme.primary;

    final Map<String, String> contactMap = {
      '微信': widget.tutor.wx,
      'WA': widget.tutor.wa,
      'Line': widget.tutor.line,
      '邮件': widget.tutor.email,
      '电话': widget.tutor.mobile,
    };

    final String currentType = tabs[currentIndex];
    final String contactValue = (contactMap[currentType] ?? '').trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部 Tab
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final selected = currentIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => currentIndex = index),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected ? primaryColor : subColor,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 展示内容
            Text(
              contactValue.isNotEmpty ? contactValue : '暂无信息',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),

            // 唯一按钮
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: contactValue.isEmpty
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);

                        await Clipboard.setData(ClipboardData(text: contactValue));

                        bool opened = true;
                        if (currentType == '微信') {
                          opened = false;
                        } else {
                          opened = await _openContact(currentType, contactValue);
                        }

                        navigator.pop();

                        if (currentType == '微信') {
                          // ignore: use_build_context_synchronously
                          MessageUtil.info(context, '微信号已复制');
                        } else if (opened) {
                          // ignore: use_build_context_synchronously
                          MessageUtil.info(context, '已复制并尝试打开');
                        } else {
                          // ignore: use_build_context_synchronously
                          MessageUtil.info(context, '内容已复制');
                        }
                      },
                child: Text(
                  currentType == '微信' ? '复制' : '打开',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开对应 App / 客户端，失败返回 false
  Future<bool> _openContact(String type, String value) async {
    try {
      Uri? uri;

      switch (type) {
        case '邮件':
          uri = Uri(scheme: 'mailto', path: value, queryParameters: {'subject': '咨询'});
          break;

        case '电话':
          uri = Uri(scheme: 'tel', path: _normalizePhone(value));
          break;

        case 'WA':
          final phone = _normalizePhone(value);
          final primary = Uri.parse('whatsapp://send?phone=$phone');
          if (await canLaunchUrl(primary)) return await launchUrl(primary);
          uri = Uri.parse('https://wa.me/$phone');
          break;

        case 'Line':
          final id = value.startsWith('@') ? value.substring(1) : value;
          final primary = Uri.parse('line://ti/p/~$id');
          if (await canLaunchUrl(primary)) return await launchUrl(primary);
          uri = Uri.parse('https://line.me/R/ti/p/~$id');
          break;

        default:
          uri = null;
      }

      if (uri == null) return false;
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  String _normalizePhone(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('+')) {
      final digits = trimmed.substring(1).replaceAll(RegExp(r'\D'), '');
      return '+$digits';
    }
    return trimmed.replaceAll(RegExp(r'\D'), '');
  }
}
