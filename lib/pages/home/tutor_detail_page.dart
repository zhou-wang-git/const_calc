import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/Tutor.dart';

final Map<int, String> gradeMapper = {
  1: '启蒙导师',
  2: '大宗导师',
  3: '传承导师',
};

class TutorDetailPage extends StatelessWidget {
  final Tutor tutor;

  const TutorDetailPage({super.key, required this.tutor});

  Future<void> _handleBooking(BuildContext context) async {
    final priorityList =
        tutor.contactPriority.split(',').map((item) => item.trim()).toList();

    final contactMethods = <String, String>{
      'email': tutor.email,
      'website': tutor.website,
      'wa': tutor.wa,
      'line': tutor.line,
      'wx': tutor.wx,
      'mobile': tutor.mobile,
    };

    String? selectedType;
    String? selectedValue;

    for (final type in priorityList) {
      final value = contactMethods[type]?.trim() ?? '';
      if (value.isNotEmpty) {
        selectedType = type;
        selectedValue = value;
        break;
      }
    }

    if (selectedType == null || selectedValue == null) {
      MessageUtil.info(context, '暂无可用联系方式');
      return;
    }

    try {
      await HttpService.postForm<void>(
        '/apis/getContactNum',
        {'id': tutor.id.toString()},
        fromData: (_) {},
      );
    } catch (_) {}

    Uri? uri;
    String? fallbackClipboardText;

    switch (selectedType) {
      case 'email':
        final subject = '预约咨询 - 数易赋能';
        final body = _buildEmailTemplate();
        uri = Uri(
          scheme: 'mailto',
          path: selectedValue,
          queryParameters: {
            'subject': subject,
            'body': body,
          },
        );
        fallbackClipboardText = '收件邮箱：$selectedValue\n主题：$subject\n\n$body';
        break;
      case 'website':
        var url = selectedValue;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        uri = Uri.parse(url);
        break;
      case 'wa':
        final message = _buildWhatsAppTemplate();
        uri = _buildWhatsAppUri(selectedValue, message: message);
        fallbackClipboardText = 'WhatsApp：$selectedValue\n\n$message';
        break;
      case 'line':
        final id = selectedValue.startsWith('@')
            ? selectedValue.substring(1)
            : selectedValue;
        uri = Uri.parse('https://line.me/R/ti/p/~$id');
        break;
      case 'wx':
        await Clipboard.setData(ClipboardData(text: selectedValue));
        if (!context.mounted) return;
        MessageUtil.info(context, '微信号已复制：$selectedValue');
        return;
      case 'mobile':
        uri = Uri(scheme: 'tel', path: selectedValue);
        break;
    }

    if (uri == null) return;

    var opened = false;
    try {
      final mode =
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
      opened = await launchUrl(uri, mode: mode);
    } catch (_) {
      opened = false;
    }

    if (opened) return;

    final clipboardText = fallbackClipboardText ?? selectedValue;
    await Clipboard.setData(ClipboardData(text: clipboardText));
    if (!context.mounted) return;
    MessageUtil.info(
      context,
      selectedType == 'email' ? '已复制邮箱和邮件模板' : '已复制联系方式',
    );
  }

  String _buildEmailTemplate() {
    return '$_displayName导师，您好：\n\n'
        '我在数易赋能看到了您的资料，想进一步了解相关咨询内容。\n\n'
        '咨询主题：\n'
        '期望时间：\n'
        '我的联系方式：\n\n'
        '谢谢。';
  }

  String _buildWhatsAppTemplate() {
    final customTemplate = tutor.waTemplate.trim();
    if (customTemplate.isNotEmpty) {
      return customTemplate;
    }
    return _buildEmailTemplate();
  }

  Uri? _buildWhatsAppUri(String input, {String? message}) {
    final phone = _extractWhatsAppPhone(input);
    if (phone == null || phone.isEmpty) {
      return null;
    }

    final trimmedMessage = message?.trim() ?? '';
    return Uri.https(
      'api.whatsapp.com',
      '/send',
      {
        'phone': phone,
        if (trimmedMessage.isNotEmpty) 'text': trimmedMessage,
      },
    );
  }

  String? _extractWhatsAppPhone(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed != null && parsed.hasScheme) {
        final host = parsed.host.toLowerCase();
        if (host == 'wa.me' || host.endsWith('.wa.me')) {
          for (final segment in parsed.pathSegments) {
            final digits = segment.replaceAll(RegExp(r'\D'), '');
            if (digits.isNotEmpty) {
              return digits;
            }
          }
          final phoneQuery =
              parsed.queryParameters['phone']?.replaceAll(RegExp(r'\D'), '') ??
                  '';
          if (phoneQuery.isNotEmpty) {
            return phoneQuery;
          }
        }
        if (host.contains('whatsapp.com')) {
          final phoneQuery =
              parsed.queryParameters['phone']?.replaceAll(RegExp(r'\D'), '') ??
                  '';
          if (phoneQuery.isNotEmpty) {
            return phoneQuery;
          }
        }
      }
    }

    final normalized = trimmed.replaceAll(RegExp(r'\D'), '');
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white
        : theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark
        ? Colors.white
        : theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final cardColor = theme.cardColor;
    final surfaceColor = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    const sectionSpacing = 12.0;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = _maxContentWidth(constraints.maxWidth);
          final introMinHeight = constraints.maxWidth >= 768 ? 240.0 : 180.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(80),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHeaderInfo(
                              textColor,
                              subTextColor,
                              isDark: isDark,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriceBadge(primaryColor),
                        ],
                      ),
                      ...[
                        const SizedBox(height: 12),
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
                                child: Text(
                                  _serviceTags.join(' | '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: _buildCertificationHeader(
                                primaryColor: primaryColor,
                                subTextColor: subTextColor,
                                isDark: isDark,
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceColor.withValues(
                                  alpha: isDark ? 0.50 : 0.78,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildLegacyInfoItem(
                                    'assets/icons/exp.png',
                                    _displayExperience,
                                    '从业年限',
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    iconColor: isDark ? Colors.white70 : null,
                                  ),
                                  _buildLegacyInfoItem(
                                    'assets/icons/gender.png',
                                    _displayGender,
                                    '性别',
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    iconColor: isDark ? Colors.white70 : null,
                                  ),
                                  _buildLegacyInfoItem(
                                    'assets/icons/zodiac.png',
                                    _displayLevel,
                                    '等级',
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    iconColor: isDark ? Colors.white70 : null,
                                  ),
                                  _buildLegacyInfoItem(
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
                              margin: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                top: 8,
                                bottom: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor.withValues(
                                  alpha: isDark ? 0.50 : 0.78,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
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
                      const SizedBox(height: sectionSpacing),
                      _buildSectionCard(
                        backgroundColor: cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDecoratedSectionTitle(
                              title: '个人介绍',
                              textColor: textColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              constraints:
                                  BoxConstraints(minHeight: introMinHeight),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceColor.withValues(
                                  alpha: isDark ? 0.50 : 0.78,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _displayBackground,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subTextColor,
                                  height: 1.75,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: sectionSpacing),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => _handleBooking(context),
                          child: const Text(
                            '预约',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return ClipOval(
      child: Image.network(
        '${HttpService.domain}${tutor.avatar}',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/icons/avatar.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(
    Color textColor,
    Color subTextColor, {
    required bool isDark,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayName,
          style: TextStyle(
            fontSize: compact ? 16 : 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_displayGrade.isNotEmpty) ...[
          _buildGradeBadge(isDark: isDark),
          const SizedBox(height: 6),
        ],
        _buildLocationInfo(subTextColor),
      ],
    );
  }

  Widget _buildGradeBadge({required bool isDark}) {
    return SizedBox(
      height: 25,
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Image.asset(
              'assets/icons/zs.png',
              fit: BoxFit.contain,
              height: 25,
            ),
            Positioned(
              left: 30,
              child: Text(
                _displayGrade,
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
    );
  }

  Widget _buildLocationInfo(Color subTextColor) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/location.png',
            height: 16,
            color: subTextColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _displayLocation,
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationHeader({
    required Color primaryColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/rzicon.png',
          height: 18,
          color: isDark ? Colors.white : null,
        ),
        const SizedBox(width: 6),
        Text(
          '认证导师',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '平台独家认证，并通过严格考核的高实力咨询师',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratedSectionTitle({
    required String title,
    required Color textColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/img4.png',
          height: 18,
          width: 18,
          color: isDark ? Colors.white70 : null,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/icons/img4.png',
          height: 18,
          width: 18,
          color: isDark ? Colors.white70 : null,
        ),
      ],
    );
  }

  Widget _buildPriceBadge(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _displayPrice,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLegacyInfoItem(
    String iconPath,
    String value,
    String label, {
    required Color textColor,
    required Color subTextColor,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, height: 24, color: iconColor),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 60),
          child: Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(color: subTextColor, fontSize: 11),
        ),
      ],
    );
  }

  double _maxContentWidth(double width) {
    if (width >= 1024) return 920;
    if (width >= 768) return 760;
    return width;
  }

  String get _displayName {
    final chineseName = tutor.chineseName.trim();
    if (chineseName.isNotEmpty) return chineseName;

    final englishName = tutor.englishName.trim();
    if (englishName.isNotEmpty) return englishName;

    return '导师';
  }

  String get _displayGrade => gradeMapper[tutor.gradeId] ?? '';

  String get _displayLocation {
    final parts = <String>[];
    final location = tutor.location.trim();
    final country = tutor.country.trim();

    if (location.isNotEmpty) parts.add(location);
    if (country.isNotEmpty && country != location) parts.add(country);

    return parts.isEmpty ? '地区待补充' : parts.join(' / ');
  }

  String get _displayPrice {
    final fee = tutor.hourlyConsultationFee.trim();
    if (fee.isEmpty || fee == '0' || fee == '0.0' || fee == '0.00') {
      return '咨询费待定';
    }
    return '\$$fee / 时';
  }

  String get _displayExperience {
    if (tutor.experienceYears <= 0) return '待补充';
    return '${tutor.experienceYears}年';
  }

  String get _displayGender {
    if (tutor.sex == 2) return '男';
    if (tutor.sex == 1) return '女';
    return '未填写';
  }

  String get _displayLevel {
    final levelName = tutor.levelName.trim();
    return levelName.isEmpty ? '待补充' : levelName;
  }

  String get _displayBackground {
    final background = tutor.background.trim();
    return background.isEmpty ? '暂无个人介绍' : background;
  }

  List<String> get _serviceTags => tutor.tagNames
      .split(RegExp(r'[,|/]+'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}

class _BotconItem extends StatelessWidget {
  final String label;

  const _BotconItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white
        : theme.textTheme.bodySmall?.color ?? Colors.black87;

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
