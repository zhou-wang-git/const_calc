import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lunar/lunar.dart';
import '../../dto/user.dart';
import '../../handler/api_exception.dart';
import '../../models/qimen_result.dart';
import '../../models/default_qimen_data.dart';
import '../../services/qimen_service.dart';
import '../../services/user_service.dart';
import '../../util/dialog_util.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../../util/app_styles.dart';
import '../home/tutor_consult_page.dart';
import '../my/member_privilege_page.dart';

class AuspiciousTimePage extends StatefulWidget {
  const AuspiciousTimePage({super.key});

  @override
  State<AuspiciousTimePage> createState() => _AuspiciousTimePageState();
}

class _AuspiciousTimePageState extends State<AuspiciousTimePage> {
  DateTime _selectedDateTime = DateTime.now();
  QimenResult? _result;
  bool _isLoading = false;
  QuotaInfo? _quotaInfo;
  LiurenResult? _liurenResult; // 六壬结果
  String _lunarDate = ''; // 农历日期
  bool _isExampleData = false; // 是否是示例数据
  DateTime? _resultDateTime; // 结果对应的查询日期时间

  @override
  void initState() {
    super.initState();
    // 页面加载完成后检查配额、加载农历和最近记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQuotaCheck();
      _loadLunarDate();
      _loadLatestRecord();
    });
  }

  /// 加载最近的查询记录
  Future<void> _loadLatestRecord() async {
    try {
      final record = await HttpUtil.request<QimenLatestRecord?>(
        () => QimenService.getLatestRecord(),
        context,
        () => mounted,
      );

      if (!mounted) return;

      if (record != null) {
        // 有历史记录，只使用结果数据，日期时间保持当前时间
        setState(() {
          // _selectedDateTime 保持初始值（当前时间）
          _result = record.qimenResult;
          _liurenResult = record.liurenResult;
          _isExampleData = false; // 标记为历史数据
          _resultDateTime = DateTime(
            record.year,
            record.month,
            record.day,
            record.hour,
            record.minute,
          ); // 保存历史查询的日期时间
        });
      } else {
        // 没有历史记录，使用默认示例数据
        setState(() {
          // _selectedDateTime 保持初始值（当前时间）
          _result = DefaultQimenData.defaultQimenResult;
          _liurenResult = DefaultQimenData.defaultLiurenResult;
          _isExampleData = true; // 标记为示例数据
          _resultDateTime = DateTime(
            DefaultQimenData.defaultYear,
            DefaultQimenData.defaultMonth,
            DefaultQimenData.defaultDay,
            DefaultQimenData.defaultHour,
            DefaultQimenData.defaultMinute,
          ); // 示例数据的日期时间
        });
      }
    } catch (e) {
      // 加载失败（如网络错误），使用默认示例数据
      if (!mounted) return;
      setState(() {
        // _selectedDateTime 保持初始值（当前时间）
        _result = DefaultQimenData.defaultQimenResult;
        _liurenResult = DefaultQimenData.defaultLiurenResult;
        _isExampleData = true; // 标记为示例数据
        _resultDateTime = DateTime(
          DefaultQimenData.defaultYear,
          DefaultQimenData.defaultMonth,
          DefaultQimenData.defaultDay,
          DefaultQimenData.defaultHour,
          DefaultQimenData.defaultMinute,
        ); // 示例数据的日期时间
      });
    }
  }

  /// 加载农历日期（仅用于页面初始化）
  Future<void> _loadLunarDate() async {
    _updateLunarForSelectedDate();
  }

  /// 根据选择的日期更新农历
  Future<void> _updateLunarForSelectedDate() async {
    try {
      // 使用 lunar 包计算农历
      final solar = Solar.fromYmd(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
      );
      final lunar = solar.getLunar();

      // 计算时辰
      final timeZhi = _getTimeZhi(_selectedDateTime.hour);

      if (!mounted) return;

      setState(() {
        // 格式: "2025 九月 廿三 申时"
        _lunarDate = '${_selectedDateTime.year} ${lunar.getMonthInChinese()}月 ${lunar.getDayInChinese()} $timeZhi';
      });
    } catch (e) {
      // 农历加载失败不影响主要功能
      if (mounted) {
        setState(() {
          _lunarDate = '';
        });
      }
    }
  }

  /// 根据小时获取时辰
  String _getTimeZhi(int hour) {
    const timeZhiList = [
      '子时', '丑时', '寅时', '卯时', '辰时', '巳时',
      '午时', '未时', '申时', '酉时', '戌时', '亥时',
    ];

    // 23:00-00:59 子时
    // 01:00-02:59 丑时
    // 03:00-04:59 寅时
    // ...以此类推
    int index;
    if (hour == 23) {
      index = 0; // 子时
    } else {
      index = (hour + 1) ~/ 2;
    }

    return timeZhiList[index];
  }

  /// 初始化配额检查
  Future<void> _initQuotaCheck() async {
    try {
      final User? user = await UserService().getUserInfo();
      print('AuspiciousTime _initQuotaCheck: user=${user?.id}, token=${user?.token?.substring(0, 10)}...');
      if (user == null) {
        print('AuspiciousTime _initQuotaCheck: user is null, retrying in 2 seconds...');
        // 用户信息未加载，等待2秒后重试
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _initQuotaCheck(); // 递归重试一次
        return;
      }

      if (!mounted) return;
      // 所有用户统一调用后端查询配额（后端会根据 vip_level_id 返回对应配额）
      final QuotaInfo? quotaInfo = await HttpUtil.request<QuotaInfo?>(
        () => QimenService.checkQuota(),
        context,
        () => mounted,
      );

      print('AuspiciousTime _initQuotaCheck: quotaInfo=${quotaInfo?.remaining}/${quotaInfo?.limit}');

      if (!mounted) return;
      setState(() {
        _quotaInfo = quotaInfo;
      });
    } catch (e) {
      print('AuspiciousTime _initQuotaCheck error: $e');
      // 配额检查失败，允许继续（graceful degradation）
    }
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFFFFD54F),     // 选中的日期/按钮颜色
                    onPrimary: Colors.black,              // 选中日期的文字颜色
                    surface: theme.cardTheme.color ?? const Color(0xFF2A2A2A),
                    onSurface: Colors.white,              // 普通文字颜色
                  )
                : ColorScheme.light(
                    primary: const Color(0xFFFFC107),     // 选中的日期/按钮颜色（主题黄色）
                    onPrimary: Colors.black,              // 选中日期的文字颜色
                    surface: Colors.white,                // 背景色
                    onSurface: Colors.black,              // 普通文字颜色
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
      // 日期改变后，重新加载农历
      _updateLunarForSelectedDate();
    }
  }

  /// 选择时间
  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFFFFD54F),     // 选中的时间/按钮颜色
                    onPrimary: Colors.black,              // 选中时间的文字颜色
                    surface: theme.cardTheme.color ?? const Color(0xFF2A2A2A),
                    onSurface: Colors.white,              // 普通文字颜色
                  )
                : ColorScheme.light(
                    primary: const Color(0xFFFFC107),     // 选中的时间/按钮颜色（主题黄色）
                    onPrimary: Colors.black,              // 选中时间的文字颜色
                    surface: Colors.white,                // 背景色
                    onSurface: Colors.black,              // 普通文字颜色
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  /// 生成吉时
  Future<void> _generateAuspiciousTime() async {
    // 检查配额
    if (_quotaInfo != null && _quotaInfo!.remaining <= 0) {
      final confirmed = await DialogUtil.confirm(
        context,
        title: "次数超限",
        content: "本月免费次数已用完",
        cancelText: "取消",
        confirmText: "升级会员",
      );

      if (!mounted || !confirmed) return;
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const MemberPrivilegePage()),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 并行调用奇门和六壬 API
      final results = await Future.wait([
        HttpUtil.request<QimenResult?>(
          () => QimenService.getAuspiciousTime(
            year: _selectedDateTime.year,
            month: _selectedDateTime.month,
            day: _selectedDateTime.day,
            hour: _selectedDateTime.hour,
            minute: _selectedDateTime.minute,
          ),
          context,
          () => mounted,
        ),
        HttpUtil.request<LiurenResult?>(
          () => QimenService.getLiurenDescription(
            year: _selectedDateTime.year,
            month: _selectedDateTime.month,
            day: _selectedDateTime.day,
            hour: _selectedDateTime.hour,
            minute: _selectedDateTime.minute,
          ),
          context,
          () => mounted,
        ),
      ]);

      if (!mounted) return;

      final QimenResult? result = results[0] as QimenResult?;
      final LiurenResult? liurenResult = results[1] as LiurenResult?;

      // 后端已经在 getAuspiciousTime 中消耗次数，前端只需更新显示
      // 重新检查配额以获取最新的剩余次数
      try {
        final quotaInfo = await QimenService.checkQuota();
        if (mounted) {
          setState(() {
            _quotaInfo = quotaInfo;
          });
        }
      } catch (e) {
        // 配额查询失败不影响结果显示
      }

      setState(() {
        _result = result;
        _liurenResult = liurenResult;
        _isLoading = false;
        _isExampleData = false; // 用户查询的结果，标记为非示例数据
        _resultDateTime = _selectedDateTime; // 保存查询时的日期时间
      });
    } catch (e, stack) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 处理 API 异常，特别是次数不足的情况
      if (e is ApiException) {
        if (e.message == '没有权限或次数不足') {
          final confirmed = await DialogUtil.confirm(
            context,
            title: "次数超限",
            content: "本月免费次数已用完",
            cancelText: "取消",
            confirmText: "升级会员",
          );

          if (!mounted || !confirmed) return;
          Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const MemberPrivilegePage()),
          );
        } else {
          MessageUtil.info(context, e.message);
        }
      } else {
        MessageUtil.info(context, '请求错误');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.appBarTheme.iconTheme?.color ?? (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '吉时出行',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 16,
        ),
        child: Column(
          children: [
            // 卡片1：日期选择模块（包含日期时间选择器、农历、配额、生成按钮）
            _buildDateSelectionCard(screenWidth, screenHeight),

            SizedBox(height: screenHeight * 0.02),

            // 卡片2：结果显示区域
            if (_result != null) _buildResultCard(screenWidth, screenHeight),

            // 卡片3：天干地支表格
            if (_result != null) ...[
              SizedBox(height: screenHeight * 0.02),
              _buildStemsTable(screenWidth),
            ],

            // 导师咨询按钮
            if (_result != null) ...[
              SizedBox(height: screenHeight * 0.02),
              _buildTutorConsultButton(screenWidth, screenHeight),
            ],

            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  /// 卡片1：日期选择模块
  Widget _buildDateSelectionCard(double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      0.3, 0, 0, 0, 0,
                      0, 0.3, 0, 0, 0,
                      0, 0, 0.3, 0, 0,
                      0, 0, 0, 1, 0,
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Image.asset(
                'assets/icons/luckout_card_bg1.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          // 深色模式下加一层蒙版
          if (isDark)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          // 内容
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF555555) : const Color(0xFF3A3A3A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期时间选择器
                _buildDateTimeSelector(screenWidth, screenHeight),

                SizedBox(height: screenHeight * 0.01),

                // 农历显示
                if (_lunarDate.isNotEmpty)
                  Center(
                    child: Text(
                      '农历 $_lunarDate',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF666666),
                        fontSize: screenWidth * 0.035,
                        shadows: isDark ? null : [
                          const Shadow(offset: Offset(-1, -1), color: Colors.white),
                          const Shadow(offset: Offset(1, -1), color: Colors.white),
                          const Shadow(offset: Offset(1, 1), color: Colors.white),
                          const Shadow(offset: Offset(-1, 1), color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.02),

                // 配额显示
                if (_quotaInfo != null) ...[
                  _buildQuotaDisplay(screenWidth),
                  SizedBox(height: screenHeight * 0.02),
                ],

                // 生成吉时按钮
                _buildGenerateButton(screenWidth, screenHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 卡片2：结果显示区域
  Widget _buildResultCard(double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 格式化日期时间显示（使用结果对应的日期时间）
    final displayDateTime = _resultDateTime ?? _selectedDateTime;
    final dateTimeStr = '${displayDateTime.year}-'
        '${displayDateTime.month.toString().padLeft(2, '0')}-'
        '${displayDateTime.day.toString().padLeft(2, '0')} '
        '${displayDateTime.hour.toString().padLeft(2, '0')}:'
        '${displayDateTime.minute.toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      0.3, 0, 0, 0, 0,
                      0, 0.3, 0, 0, 0,
                      0, 0, 0.3, 0, 0,
                      0, 0, 0, 1, 0,
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Image.asset(
                'assets/icons/luckout_card_bg2.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          // 深色模式下加一层蒙版
          if (isDark)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          // 内容
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF555555) : const Color(0xFF3A3A3A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态标识 - 居中显示
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : const Color(0xFFEFECED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExampleData ? '查询示例' : '最近查询',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF666666),
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF999999),
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Text(
                          dateTimeStr,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF666666),
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                // 吉时出行区块
                _buildQimenSection(screenWidth),

                // 运势指南区块
                if (_liurenResult != null) ...[
                  SizedBox(height: screenHeight * 0.02),
                  _buildLiurenSection(screenWidth),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 日期时间选择器（年月日合并，时分独立）
  Widget _buildDateTimeSelector(double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark
        ? (theme.cardTheme.color ?? const Color(0xFF2A2A2A)).withOpacity(0.9)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final separatorColor = isDark ? Colors.white38 : const Color(0xFFCCCCCC);

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 日期卡片（年月日合并）
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.012,
              ),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedDateTime.year}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' - ',
                    style: TextStyle(
                      color: separatorColor,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    '${_selectedDateTime.month}月',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' - ',
                    style: TextStyle(
                      color: separatorColor,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    '${_selectedDateTime.day}日',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          // 时分卡片（独立）
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.012,
              ),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 配额显示
  Widget _buildQuotaDisplay(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        //color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppStyles.formatQuotaDisplay(_quotaInfo!.remaining, _quotaInfo!.limit),
        textAlign: TextAlign.center,
        style: AppStyles.getQuotaTextStyle(screenWidth, context),
      ),
    );
  }

  /// 生成吉时按钮（无边框，居中）
  Widget _buildGenerateButton(double screenWidth, double screenHeight) {
    // 定义响应式断点
    final isSmall = screenWidth < 600;  // 手机
    final isMedium = screenWidth >= 600 && screenWidth < 1000;  // 平板

    // 根据断点设置不同的按钮宽度
    double btnWidth;
    double btnHeight;
    double fontSize;

    if (isSmall) {
      // 手机：按钮占容器较小比例
      btnWidth = 100;
      btnHeight = 30;
      fontSize = 14;
    } else if (isMedium) {
      // 平板：中等尺寸
      btnWidth = 120;
      btnHeight = 45;
      fontSize = 15;
    } else {
      // 网页：更大尺寸
      btnWidth = 140;
      btnHeight = 50;
      fontSize = 16;
    }

    return Center(
      child: SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _generateAuspiciousTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),  // 黄色，与登录按钮一致
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),  // 高圆角
            ),
            disabledBackgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '生成吉时',
                  style: TextStyle(
                    fontSize: fontSize.toDouble(),
                    color: Colors.black,  // 黑色文字
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }


  /// 吉时出行区块
  Widget _buildQimenSection(double screenWidth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF000000);
    final contentColor = isDark ? Colors.white70 : const Color(0xFF000000);
    final separatorColor = isDark ? Colors.white38 : const Color(0xFF999999);
    final luckColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFCBA656);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏：吉时出行 | 吉
        Row(
          children: [
            Text(
              '吉时出行',
              style: TextStyle(
                color: titleColor,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' | ',
              style: TextStyle(
                color: separatorColor,
                fontSize: screenWidth * 0.04,
              ),
            ),
            Text(
              _result!.luck,
              style: TextStyle(
                color: luckColor,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // 内容
        Text(
          _convertToChinese(_result!.description),
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: contentColor,
            fontSize: screenWidth * 0.035,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// 运势指南区块
  Widget _buildLiurenSection(double screenWidth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF000000);
    final contentColor = isDark ? Colors.white70 : const Color(0xFF000000);
    final separatorColor = isDark ? Colors.white38 : const Color(0xFF999999);
    final luckColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFCBA656);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏：运势指南 | 吉
        Row(
          children: [
            Text(
              '运势指南',
              style: TextStyle(
                color: titleColor,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' | ',
              style: TextStyle(
                color: separatorColor,
                fontSize: screenWidth * 0.04,
              ),
            ),
            Text(
              _liurenResult!.luck,
              style: TextStyle(
                color: luckColor,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // 内容
        Text(
          _convertToChinese(_liurenResult!.description),
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: contentColor,
            fontSize: screenWidth * 0.035,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// 将英文标点符号转换为中文标点符号，并去掉换行符
  String _convertToChinese(String text) {
    return text
        .replaceAll('\n', '')  // 去掉换行符
        .replaceAll('\r', '')  // 去掉回车符
        .replaceAll(',', '，')
        .replaceAll('.', '。')
        .replaceAll(':', '：')
        .replaceAll(';', '；')
        .replaceAll('!', '！')
        .replaceAll('?', '？')
        .replaceAll('(', '（')
        .replaceAll(')', '）')
        .replaceAll('"', '"');
  }

  /// 导师咨询按钮 - 使用 LayoutBuilder 实现响应式设计
  Widget _buildTutorConsultButton(double screenWidth, double screenHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 定义响应式断点
        final isSmall = screenWidth < 600;  // 手机
        final isMedium = screenWidth >= 600 && screenWidth < 1000;  // 平板
        final isLarge = screenWidth >= 1000;  // 网页

        // 根据断点设置不同的按钮高度和字体大小
        double btnHeight;
        double fontSize;

        if (isSmall) {
          // 手机：较小高度
          btnHeight = 40;
          fontSize = 14;
        } else if (isMedium) {
          // 平板：中等高度
          btnHeight = 45;
          fontSize = 15;
        } else {
          // 网页：更大高度
          btnHeight = 50;
          fontSize = 16;
        }

        return SizedBox(
          width: double.infinity,
          height: btnHeight,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TutorConsultPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),  // 黄色，与登录按钮一致
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),  // 高圆角
              ),
              elevation: 0,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              '点击详细咨询导师 >',
              style: TextStyle(
                fontSize: fontSize.toDouble(),
                color: Colors.black,  // 黑色文字
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  /// 八字排盘表格（自定义宽高比，铺满背景块）
  Widget _buildStemsTable(double screenWidth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white54 : const Color(0xFF3A3A3A);
    final tableBgColor = isDark ? (theme.cardTheme.color ?? const Color(0xFF2A2A2A)) : const Color(0xFFFFFFFF);
    final borderWidth = 0.5;
    final containerPadding = 0.0;
    final minColumnWidth = 35.0;  // 最小列宽，确保两个字能横排显示
    // 基础单位宽度：表格分为18个单位（边栏1 + 数据列8×2 + 边栏1 = 18）
    final baseWidth = max((screenWidth * 0.9 - containerPadding * 2) / 18, minColumnWidth / 2);

    // 使用 Stack 实现真正的表格合并效果
    final rowHeight = baseWidth * 2; // 每行高度为2个基础单位，保持正方形

    // 计算神煞的最大行数（提前计算，用于确定总行数）
    final shenshaLists = [
      _result!.b4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.c4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.d4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.e4Shensha.where((s) => s.isNotEmpty).toList(),
    ];
    final maxShenshaRows = shenshaLists.isNotEmpty
        ? shenshaLists.map((list) => list.length).reduce((a, b) => a > b ? a : b)
        : 0;
    final shenshaRowCount = maxShenshaRows > 0 ? maxShenshaRows : 1;
    final totalRows = 10 + shenshaRowCount; // 前10行固定 + 神煞动态行

    final tableWidth = baseWidth * 18; // 表格总宽度（18个基础单位）

    return SizedBox(
      width: screenWidth * 0.95,
      child: Center(
        child: Container(
          width: tableWidth + 2, // 外边框宽度 = 表格宽度 + 2px(左右各1px)
          padding: const EdgeInsets.all(1.0), // 1px 内边距
          decoration: BoxDecoration(
            color: borderColor, // 外边框颜色使用表格边框颜色
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: tableWidth,
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              color: tableBgColor,
              borderRadius: BorderRadius.circular(11), // 内圆角稍小,避免外边框露出
            ),
            child: Stack(
              children: [
                // 底层：所有行的布局（占位）- 第一行高度为单倍，其他行为双倍
                Column(
                  children: [
                    SizedBox(height: baseWidth), // 第一行单倍高度
                    ...List.generate(totalRows - 1, (index) => SizedBox(height: rowHeight)), // 其他行双倍高度
                  ],
                ),

                // 中层：所有单元格用 Positioned 定位
                ..._buildAllCells(baseWidth, rowHeight, borderColor, borderWidth, isDark),

                // 顶层：装饰框层
                ..._buildDecorativeBoxes(baseWidth, rowHeight, borderColor, borderWidth, shenshaRowCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建装饰框层（储物格效果）
  List<Widget> _buildDecorativeBoxes(
    double baseWidth,
    double rowHeight,
    Color borderColor,
    double borderWidth,
    int shenshaRowCount,
  ) {
    List<Widget> boxes = [];

    // 辅助函数：创建单个装饰框
    Widget buildBox({
      required double left,
      required double top,
      required double width,
      required double height,
      BorderRadius? borderRadius, // 可选圆角
    }) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor, // 使用正常边框颜色
                width: borderWidth, // 使用正常边框粗细
              ),
              borderRadius: borderRadius, // 圆角
              color: Colors.transparent, // 透明背景,露出下方内容
            ),
          ),
        ),
      );
    }

    // 装饰框0: 最外层框 - 包围整个表格内容(第0-17列,所有行)
    final totalHeight = baseWidth + rowHeight * (9 + shenshaRowCount); // 总高度
    final gap = borderWidth * 3; // 间距倍数,可调整
    boxes.add(buildBox(
      left: 0.0 - gap,
      top: 0.0 - gap,
      width: baseWidth * 18 + gap * 2, // 18列
      height: totalHeight + gap * 2,
      borderRadius:  null//BorderRadius.circular(11), // 与内层Container圆角一致
    ));

    // 装饰框1: 时日月年+十神+天干+地支 (第0-3行,第1-16列)
    // 向外扩展 gap,在单元格边框外留出空隙,形成双线效果
    boxes.add(buildBox(
      left: baseWidth * 1 - gap,
      top: 0.0 - gap,
      width: baseWidth * 16 + gap * 2,
      height: baseWidth + rowHeight * 3 + gap * 2, // 1个单倍行 + 3个双倍行
    ));

    // 装饰框2: 藏干12格 (第4-6行,第1-16列,每列分4格,每格2单位宽)
    for (int row = 0; row < 3; row++) { // 3行
      for (int col = 0; col < 4; col++) { // 4列(时日月年)
        boxes.add(buildBox(
          left: baseWidth * (1 + col * 4) - gap,
          top: baseWidth + rowHeight * (3 + row) - gap,
          width: baseWidth * 4 + gap * 2, // 每列4单位(包含2个小格)
          height: rowHeight + gap * 2,
        ));
      }
    }

    // 装饰框3: 运/纳音/空亡 (第7-9行,第1-16列)
    boxes.add(buildBox(
      left: baseWidth * 1 - gap,
      top: baseWidth + rowHeight * 6 - gap,
      width: baseWidth * 16 + gap * 2,
      height: rowHeight * 3 + gap * 2,
    ));

    // 装饰框4: 神煞 (第10行开始,第1-16列,高度动态)
    boxes.add(buildBox(
      left: baseWidth * 1 - gap,
      top: baseWidth + rowHeight * 9 - gap,
      width: baseWidth * 16 + gap * 2,
      height: rowHeight * shenshaRowCount + gap * 2,
    ));

    return boxes;
  }

  /// 构建所有单元格（使用绝对定位）
  List<Widget> _buildAllCells(double baseWidth, double rowHeight, Color borderColor, double borderWidth, bool isDark) {
    List<Widget> allCells = [];
    // 统一使用 .sp 单位
    final fontSize = 11.sp;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    // 辅助函数：将文字转为竖排（每个字符加换行符）
    String toVerticalText(String text) {
      if (text.isEmpty) return text;
      // 在冒号前后添加全角空格，使其在竖排时视觉居中
      // 全角空格（U+3000）不会被 Flutter Text 压缩
      final processedText = text.replaceAll('：', ' :');
      return processedText.split('').join('\n');
    }

    // 辅助函数：创建单元格
    Widget buildCell(
      int row,
      int col,
      int rowSpan,
      int colSpan,
      String text, {
      bool isHeader = false,
      bool isVertical = false,
      bool hasTopLine = false,         // 上方装饰线
      bool hasBottomLine = false,      // 下方装饰线
      bool hasLeftLine = false,        // 左侧装饰线
      bool hasRightLine = false,       // 右侧装饰线
      double topLinePosition = 1.0,    // 顶部装饰线距离上边缘的距离
      double bottomLinePosition = 1.0, // 底部装饰线距离下边缘的距离
      double leftLinePosition = 1.0,   // 左侧装饰线距离左边缘的距离
      double rightLinePosition = 1.0,  // 右侧装饰线距离右边缘的距离
      double lineMargin = 0.0,         // 装饰线两端缩进距离
      double lineThickness = 1.0,      // 装饰线粗细
    }) {
      // 第一行、第一列、最后一列保留粗体
      final isBold = row == 0 || col == 0 || col == 17;
      final displayText = isVertical ? toVerticalText(text) : text;

      // 第一行高度为单倍，其他行为双倍
      // 如果从第0行开始且跨多行，需要计算正确的总高度：1个单倍 + (rowSpan-1)个双倍
      final cellHeight = row == 0
          ? (rowSpan == 1 ? baseWidth : baseWidth + (rowSpan - 1) * rowHeight)
          : (rowSpan * rowHeight);
      // 第一行的top坐标为0，其他行需要加上第一行的单倍高度
      final cellTop = row == 0 ? 0.0 : (baseWidth + (row - 1) * rowHeight);

      // 判断是否是四个角的单元格，去除外侧边框
      final isTopLeft = row == 0 && col == 0;
      final isTopRight = row == 0 && col == 17;
      final isBottomLeft = row == 10 && col == 0;
      final isBottomRight = row == 10 && col == 17;

      // 根据位置选择性显示边框
      Border cellBorder;
      if (isTopLeft) {
        // 左上角：去掉上边框和左边框
        cellBorder = Border(
          right: BorderSide(color: borderColor, width: borderWidth),
          bottom: BorderSide(color: borderColor, width: borderWidth),
        );
      } else if (isTopRight) {
        // 右上角：去掉上边框和右边框
        cellBorder = Border(
          left: BorderSide(color: borderColor, width: borderWidth),
          bottom: BorderSide(color: borderColor, width: borderWidth),
        );
      } else if (isBottomLeft) {
        // 左下角：去掉下边框和左边框
        cellBorder = Border(
          top: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
        );
      } else if (isBottomRight) {
        // 右下角：去掉下边框和右边框
        cellBorder = Border(
          top: BorderSide(color: borderColor, width: borderWidth),
          left: BorderSide(color: borderColor, width: borderWidth),
        );
      } else {
        // 普通单元格：四边都有边框
        cellBorder = Border.all(color: borderColor, width: borderWidth);
      }

      return Positioned(
        left: col * baseWidth,
        top: cellTop,
        width: colSpan * baseWidth,
        height: cellHeight,
        child: Container(
          decoration: BoxDecoration(
            border: cellBorder,
          ),
          child: Stack(
            children: [
              // 文字内容层
              Center(
                child: Padding(
                  padding: row == 0 && rowSpan > 1
                      ? EdgeInsets.only(
                          left: 4,
                          right: 4,
                          top: 4 + (rowHeight - baseWidth) / 2, // 补偿第0行高度差异
                          bottom: 4,
                        )
                      : (row == 0 && rowSpan == 1
                          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0) // 第0行单行单元格：上下padding为0
                          : (col == 0
                              ? const EdgeInsets.only(left: 3, right: 5, top: 4, bottom: 4) // 第一列：左侧加padding
                              : (col == 17
                                  ? const EdgeInsets.only(left: 3, right: 5, top: 2, bottom: 6) // 最后一列：右侧加padding
                                  : const EdgeInsets.all(4)))),
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    maxLines: isVertical ? rowSpan * 10 : (rowSpan * 5), // 增加行数限制
                    overflow: TextOverflow.visible, // 允许完整显示
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      height: isVertical ? 1.5 : 1.0, // 竖排行高1.5，横排行高1.0实现真正居中
                    ),
                  ),
                ),
              ),

              // 顶部装饰线
              if (hasTopLine)
                Positioned(
                  top: topLinePosition,
                  left: lineMargin,
                  right: lineMargin,
                  child: Container(
                    height: lineThickness,
                    color: borderColor,
                  ),
                ),

              // 底部装饰线
              if (hasBottomLine)
                Positioned(
                  bottom: bottomLinePosition,
                  left: lineMargin,
                  right: lineMargin,
                  child: Container(
                    height: lineThickness,
                    color: borderColor,
                  ),
                ),

              // 左侧装饰线
              if (hasLeftLine)
                Positioned(
                  left: leftLinePosition,
                  top: lineMargin,
                  bottom: lineMargin,
                  child: Container(
                    width: lineThickness,
                    color: borderColor,
                  ),
                ),

              // 右侧装饰线
              if (hasRightLine)
                Positioned(
                  right: rightLinePosition,
                  top: lineMargin,
                  bottom: lineMargin,
                  child: Container(
                    width: lineThickness,
                    color: borderColor,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 第1行：标题（新列坐标：0, 1-4, 5-8, 9-12, 13-16, 17）
    // 第一列从第0行开始显示"胎元"，跨4行（合并第1行的空白格和第2-4行的胎元）
    allCells.add(buildCell(0, 0, 4, 1, '胎元：${_result!.a1Taiyuan}', isVertical: true));
    allCells.add(buildCell(0, 1, 1, 4, '时', isHeader: true));
    allCells.add(buildCell(0, 5, 1, 4, '日', isHeader: true));
    allCells.add(buildCell(0, 9, 1, 4, '月', isHeader: true));
    allCells.add(buildCell(0, 13, 1, 4, '年', isHeader: true));
    allCells.add(buildCell(0, 17, 1, 1, ''));

    // 第2-4行：十神/天干/地支（胎元已在第0行定义）

    // 第2行：十神行
    allCells.add(buildCell(1, 1, 1, 4, _result!.b1TimeShishen));
    allCells.add(buildCell(1, 5, 1, 4, '日主'));
    allCells.add(buildCell(1, 9, 1, 4, _result!.d1MonthShishen));
    allCells.add(buildCell(1, 13, 1, 4, _result!.e1YearShishen));
    allCells.add(buildCell(1, 17, 1, 1, '十神', isVertical: true));

    // 第3行：天干行
    allCells.add(buildCell(2, 1, 1, 4, _result!.b2TimeTiangan));
    allCells.add(buildCell(2, 5, 1, 4, _result!.c2DayTiangan));
    allCells.add(buildCell(2, 9, 1, 4, _result!.d2MonthTiangan));
    allCells.add(buildCell(2, 13, 1, 4, _result!.e2YearTiangan));
    allCells.add(buildCell(2, 17, 1, 1, '天干', isVertical: true));

    // 第4行：地支行
    allCells.add(buildCell(3, 1, 1, 4, _result!.b3TimeDizhi));
    allCells.add(buildCell(3, 5, 1, 4, _result!.c3DayDizhi));
    allCells.add(buildCell(3, 9, 1, 4, _result!.d3MonthDizhi));
    allCells.add(buildCell(3, 13, 1, 4, _result!.e3YearDizhi));
    allCells.add(buildCell(3, 17, 1, 1, '地支', isVertical: true));

    // 第5-7行：润下水（rowSpan=3） + 藏干
    allCells.add(buildCell(4, 0, 3, 1, '润下水', isVertical: true));
    allCells.add(buildCell(4, 1, 1, 2, _result!.b21Zhanggan));
    allCells.add(buildCell(4, 3, 1, 2, _result!.b22Zhanggan));
    allCells.add(buildCell(4, 5, 1, 2, _result!.c21Zhanggan));
    allCells.add(buildCell(4, 7, 1, 2, _result!.c22Zhanggan));
    allCells.add(buildCell(4, 9, 1, 2, _result!.d21Zhanggan));
    allCells.add(buildCell(4, 11, 1, 2, _result!.d22Zhanggan));
    allCells.add(buildCell(4, 13, 1, 2, _result!.e21Zhanggan));
    allCells.add(buildCell(4, 15, 1, 2, _result!.e22Zhanggan));
    allCells.add(buildCell(4, 17, 1, 1, '藏干', isVertical: true));

    allCells.add(buildCell(5, 1, 1, 2, _result!.b31Zhanggan));
    allCells.add(buildCell(5, 3, 1, 2, _result!.b32Zhanggan));
    allCells.add(buildCell(5, 5, 1, 2, _result!.c31Zhanggan));
    allCells.add(buildCell(5, 7, 1, 2, _result!.c32Zhanggan));
    allCells.add(buildCell(5, 9, 1, 2, _result!.d31Zhanggan));
    allCells.add(buildCell(5, 11, 1, 2, _result!.d32Zhanggan));
    allCells.add(buildCell(5, 13, 1, 2, _result!.e31Zhanggan));
    allCells.add(buildCell(5, 15, 1, 2, _result!.e32Zhanggan));
    allCells.add(buildCell(5, 17, 1, 1, '藏干', isVertical: true));

    allCells.add(buildCell(6, 1, 1, 2, _result!.b41Zhanggan));
    allCells.add(buildCell(6, 3, 1, 2, _result!.b42Zhanggan));
    allCells.add(buildCell(6, 5, 1, 2, _result!.c41Zhanggan));
    allCells.add(buildCell(6, 7, 1, 2, _result!.c42Zhanggan));
    allCells.add(buildCell(6, 9, 1, 2, _result!.d41Zhanggan));
    allCells.add(buildCell(6, 11, 1, 2, _result!.d42Zhanggan));
    allCells.add(buildCell(6, 13, 1, 2, _result!.e41Zhanggan));
    allCells.add(buildCell(6, 15, 1, 2, _result!.e42Zhanggan));
    allCells.add(buildCell(6, 17, 1, 1, '藏干', isVertical: true));

    // 第8-10行：胎息（rowSpan=3） + 运/纳音/空亡
    allCells.add(buildCell(7, 0, 3, 1, '胎息：${_result!.a3Taixi}', isVertical: true));
    allCells.add(buildCell(7, 1, 1, 4, _result!.b31Yun));
    allCells.add(buildCell(7, 5, 1, 4, _result!.c31Yun));
    allCells.add(buildCell(7, 9, 1, 4, _result!.d31Yun));
    allCells.add(buildCell(7, 13, 1, 4, _result!.e31Yun));
    allCells.add(buildCell(7, 17, 1, 1, '运', isVertical: true));

    allCells.add(buildCell(8, 1, 1, 4, _result!.b32Nayin));
    allCells.add(buildCell(8, 5, 1, 4, _result!.c32Nayin));
    allCells.add(buildCell(8, 9, 1, 4, _result!.d32Nayin));
    allCells.add(buildCell(8, 13, 1, 4, _result!.e32Nayin));
    allCells.add(buildCell(8, 17, 1, 1, '纳音', isVertical: true));

    allCells.add(buildCell(9, 1, 1, 4, _result!.b33Kongwang));
    allCells.add(buildCell(9, 5, 1, 4, _result!.c33Kongwang));
    allCells.add(buildCell(9, 9, 1, 4, _result!.d33Kongwang));
    allCells.add(buildCell(9, 13, 1, 4, _result!.e33Kongwang));
    allCells.add(buildCell(9, 17, 1, 1, '空亡', isVertical: true));

    // 第11行开始：命宫 + 神煞（动态高度）
    // 计算神煞数组的最大行数
    final shenshaLists = [
      _result!.b4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.c4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.d4Shensha.where((s) => s.isNotEmpty).toList(),
      _result!.e4Shensha.where((s) => s.isNotEmpty).toList(),
    ];
    final maxShenshaRows = shenshaLists.map((list) => list.length).reduce((a, b) => a > b ? a : b);
    final shenshaRowCount = maxShenshaRows > 0 ? maxShenshaRows : 1; // 至少1行

    // 命宫单元格（左侧边栏）
    allCells.add(buildCell(10, 0, shenshaRowCount, 1, '命宫：${_result!.a4Minggong}', isVertical: true));

    // 神煞标签（右侧边栏）
    allCells.add(buildCell(10, 17, shenshaRowCount, 1, '神煞', isVertical: true));

    // 填充每一列的神煞数据（每列合并成一个单元格，高度统一=最大神煞数量）
    final columns = [1, 5, 9, 13]; // 时、日、月、年的起始列
    for (int i = 0; i < shenshaLists.length; i++) {
      final shensha = shenshaLists[i];
      final startCol = columns[i];

      // 将神煞数组用换行符连接
      final shenshaText = shensha.isNotEmpty ? shensha.join('\n') : '';

      // 所有列的高度统一为最大行数
      allCells.add(buildCell(10, startCol, shenshaRowCount, 4, shenshaText));
    }

    return allCells;
  }

}