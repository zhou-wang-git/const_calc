import 'package:const_calc/dto/user.dart';
import 'package:const_calc/handler/api_exception.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/http_util.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';

import '../../component/bottom_date_picker.dart';
import '../../component/bottom_time_zodiac_picker.dart';
import '../../dto/digit_calculation.dart';
import '../../dto/digit_calculation_sum.dart';
import '../../models/qimen_result.dart';
import '../../services/digit_calculation_service.dart';
import '../../util/date_util.dart';
import '../../util/dialog_util.dart';
import '../../util/twin_util.dart';
import '../../util/app_styles.dart';
import '../my/member_privilege_page.dart';
import 'fortune_detail_page.dart';

class DigitCalculationPage extends StatefulWidget {
  const DigitCalculationPage({super.key});

  @override
  State<DigitCalculationPage> createState() => _DigitCalculationPageState();
}

class _DigitCalculationPageState extends State<DigitCalculationPage>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _enNameController = TextEditingController();
  String birthday = "请选择";
  String birthTime = "请选择";
  int gender = 0;
  int twinStatus = 0; // 0=不是双胞胎, 1=大的, 2=小的
  String parentBirthday = "请选择"; // 父亲/母亲的生日
  bool isLoading = false;
  bool showResult = false;
  int detailId = -1;
  late AnimationController _rotate1;
  late AnimationController _rotate2;
  int _vipLevelId = 1;
  String _levelLabel = '基础会员';
  String _shownCount = '';
  QuotaInfo? _quotaInfo;
  static const vipMapper = {1: '普通会员', 2: '精英会员', 3: '至尊会员'};

  @override
  void initState() {
    super.initState();
    _rotate1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _rotate2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 34),
    )..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final User? user = await UserService().getUserInfo();
    if (user != null) {
      setState(() {
        _vipLevelId = user.vipLevelId;
        _levelLabel = vipMapper[_vipLevelId] ?? '普通会员';
      });
    }

    // 改用统一的配额检查
    await _initQuotaCheck();
  }

  /// 初始化配额检查
  Future<void> _initQuotaCheck() async {
    try {
      final User? user = await UserService().getUserInfo();
      print('DigitCalculation _initQuotaCheck: user=${user?.id}, token=${user?.token?.substring(0, 10)}...');
      if (user == null) {
        print('DigitCalculation _initQuotaCheck: user is null, retrying in 2 seconds...');
        // 用户信息未加载，等待2秒后重试
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _initQuotaCheck(); // 递归重试一次
        return;
      }

      if (!mounted) return;
      final QuotaInfo? quotaInfo = await HttpUtil.request<QuotaInfo?>(
        () => DigitCalculationService.checkQuota(),
        context,
        () => mounted,
      );

      print('DigitCalculation _initQuotaCheck: quotaInfo=${quotaInfo?.remaining}/${quotaInfo?.limit}');

      if (!mounted) return;
      setState(() {
        _quotaInfo = quotaInfo;
        // 统一显示格式: 剩余查询次数: X/Y 或 无限
        if (quotaInfo != null) {
          _shownCount = AppStyles.formatQuotaDisplay(quotaInfo.remaining, quotaInfo.limit);
        }
      });
    } catch (e) {
      print('DigitCalculation _initQuotaCheck error: $e');
      // 配额检查失败，允许继续
    }
  }

  @override
  void dispose() {
    _rotate1.dispose();
    _rotate2.dispose();
    super.dispose();
  }

  void submit() async {
    // 预检查配额
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
      return; // 阻止提交
    }

    // 修改验证逻辑：中文姓名或英文姓名至少填一个
    if (_nameController.text.isEmpty && _enNameController.text.isEmpty) {
      MessageUtil.info(context, '请至少输入中文姓名或英文姓名');
      return;
    }

    // 如果填了中文姓名，验证是否为中文
    if (_nameController.text.isNotEmpty) {
      final RegExp chineseRegex = RegExp(r'^[\u4e00-\u9fa5]+$');
      if (!chineseRegex.hasMatch(_nameController.text)) {
        MessageUtil.info(context, '中文姓名必须是中文');
        return;
      }
    }
    if (gender == 0) {
      MessageUtil.info(context, '请选择性别');
      return;
    }
    if (birthday == "请选择") {
      MessageUtil.info(context, '请选择出生日期');
      return;
    }
    if (twinStatus != 0 && parentBirthday == "请选择") {
      final parentLabel = twinStatus == 1 ? "父亲" : "母亲";
      MessageUtil.info(context, '请选择$parentLabel的出生日期');
      return;
    }

    // 验证父母年龄不能小于双胞胎年龄
    if (twinStatus != 0 && parentBirthday != "请选择") {
      final parentLabel = twinStatus == 1 ? "父亲" : "母亲";
      final parentDate = DateTime.tryParse(parentBirthday);
      final childDate = DateTime.tryParse(birthday);

      if (parentDate != null && childDate != null) {
        if (parentDate.isAfter(childDate) || parentDate.isAtSameMomentAs(childDate)) {
          MessageUtil.info(context, '$parentLabel的出生日期不能晚于或等于您的出生日期');
          return;
        }
      }
    }

    setState(() => isLoading = true);

    try {
      // 始终传递真实生日给后端，后端会根据twin_status自动处理虚拟生日计算
      List<String> birthdayList = birthday.split('-');
      String isBirth = birthTime.contains('子时') ? '1' : '0';

      // 解析父母生日
      String? parentYear;
      String? parentMonth;
      String? parentDay;
      if (twinStatus != 0 && parentBirthday.isNotEmpty) {
        final parentParts = parentBirthday.split('-');
        if (parentParts.length == 3) {
          parentYear = parentParts[0];
          parentMonth = parentParts[1];
          parentDay = parentParts[2];
        }
      }

      // 临时调试：打印传递的参数
      print('=== DEBUG: 前端传递的参数 ===');
      print('twinStatus: $twinStatus');
      print('parentYear: $parentYear');
      print('parentMonth: $parentMonth');
      print('parentDay: $parentDay');
      print('birthday: ${birthdayList[0]}-${birthdayList[1]}-${birthdayList[2]}');

      DigitCalculation digitCalculation =
          await DigitCalculationService.getResultList(
            name: _nameController.text,
            ename: _enNameController.text,
            sex: gender.toString(),
            type: '-1',
            year: birthdayList[0],
            month: birthdayList[1],
            day: birthdayList[2],
            curyear: DateUtil.getCurrentYear(),
            curmonth: DateUtil.getCurrentMonth(),
            curday: DateUtil.getCurrentDay(),
            birthTime: birthTime,
            isBirth: isBirth,
            twinStatus: twinStatus,
            parentYear: parentYear,
            parentMonth: parentMonth,
            parentDay: parentDay,
          );

      // 临时调试：打印后端返回的调试信息
      print('=== DEBUG: 后端返回 ===');
      print('digitCalculation: ${digitCalculation.toJson()}');

      setState(() {
        showResult = true;
        detailId = int.parse(digitCalculation.id ?? '-1');
      });

      // 刷新配额显示
      await _initQuotaCheck();
    } catch (e, stack) {
      if (!mounted) return;
      if (e is ApiException) {
        if (e.message == '本月免费次数已用完') {
          final confirmed = await DialogUtil.confirm(
            context,
            title: "次数超限",
            content: e.message,
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
      debugPrintStack(stackTrace: stack);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(height: 1.1);

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.appBarTheme.iconTheme?.color ?? (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '数字测算',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/img08.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Transform.translate(
                      offset: const Offset(80, -50),
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _rotate1,
                              child: Image.asset(
                                'assets/icons/img03.png',
                                width: 240,
                              ),
                            ),
                            RotationTransition(
                              turns: Tween(
                                begin: 1.0,
                                end: 0.0,
                              ).animate(_rotate2),
                              child: Image.asset(
                                'assets/icons/img06.png',
                                width: 180,
                              ),
                            ),
                            Image.asset('assets/icons/img07.png', width: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // 配额显示（移到标题上面）
                    if (_quotaInfo != null) ...[
                      _buildQuotaDisplay(),
                      const SizedBox(height: 12),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Text(
                          '输入您的生辰信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _buildCardWrapper(
                          _buildInputRow("中文姓名", _nameController),
                        ),
                        _buildCardWrapper(
                          _buildInputRow("英文姓名", _enNameController, subtitle: "(中英二选一)"),
                        ),
                        _buildCardWrapper(
                          _buildPickerRow("出生日期", birthday, _pickDate),
                        ),
                        _buildCardWrapper(
                          _buildPickerRow("出生时间", birthTime, _pickTime),
                        ),
                        _buildCardWrapper(_buildGenderSelector()),
                        _buildCardWrapper(_buildTwinSelector()),
                        if (twinStatus != 0)
                          _buildCardWrapper(
                            _buildPickerRow(
                              twinStatus == 1 ? "父亲生日" : "母亲生日",
                              parentBirthday,
                              _pickParentDate,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: submit,
                        child: Image.asset(
                          'assets/icons/start.png',
                          width: 240,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading) _buildLoadingPopup(),
          if (showResult) _buildResultPopup(),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, {String? subtitle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final inputTextColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: Colors.grey,
              decoration: InputDecoration(
                hintText: "请输入$label",
                hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
                filled: true,
                fillColor: inputBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: inputTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pickerBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final pickerTextColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: double.infinity,
                decoration: BoxDecoration(
                  color: pickerBgColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: pickerTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = theme.textTheme.bodyLarge?.color;
    final radioActiveColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                "用户性别",
                style: TextStyle(color: labelColor),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio<int>(
                  value: 2,
                  groupValue: gender,
                  activeColor: radioActiveColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => gender = val!),
                ),
                Text("男", style: TextStyle(color: labelColor)),
                const SizedBox(width: 20),
                Radio<int>(
                  value: 1,
                  groupValue: gender,
                  activeColor: radioActiveColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => gender = val!),
                ),
                Text("女", style: TextStyle(color: labelColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    BottomDatePicker.showDatePicker(
      initialDate: DateUtil.parseDate(birthday, 'yyyy-MM-dd'),
      context: context,
      onConfirm: (formattedDate, rawDate) {
        setState(() {
          birthday = formattedDate;
        });
      },
      confirmColor: const Color(0xFFFFC107),
      cancelColor: Colors.grey,
    );
  }

  Future<void> _pickTime() async {
    BottomTimeZodiacPicker.showTimeZodiacPicker(
      context,
      initialValue: birthTime,
      onConfirm: (selected) {
        setState(() {
          birthTime = selected;
        });
      },
    );
  }

  Future<void> _pickParentDate() async {
    BottomDatePicker.showDatePicker(
      initialDate: DateUtil.parseDate(parentBirthday, 'yyyy-MM-dd'),
      context: context,
      onConfirm: (formattedDate, rawDate) {
        setState(() {
          parentBirthday = formattedDate;
        });
      },
      confirmColor: const Color(0xFFFFC107),
      cancelColor: Colors.grey,
    );
  }

  Widget _buildTwinSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = theme.textTheme.bodyLarge?.color;
    final radioActiveColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                "双胞胎",
                style: TextStyle(color: labelColor),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio<int>(
                  value: 0,
                  groupValue: twinStatus,
                  activeColor: radioActiveColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() {
                    twinStatus = val!;
                    if (twinStatus == 0) {
                      parentBirthday = "请选择";
                    }
                  }),
                ),
                Text("不", style: TextStyle(color: labelColor)),
                const SizedBox(width: 20),
                Radio<int>(
                  value: 1,
                  groupValue: twinStatus,
                  activeColor: radioActiveColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => twinStatus = val!),
                ),
                Text("长", style: TextStyle(color: labelColor)),
                const SizedBox(width: 20),
                Radio<int>(
                  value: 2,
                  groupValue: twinStatus,
                  activeColor: radioActiveColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => twinStatus = val!),
                ),
                Text("幼", style: TextStyle(color: labelColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPopup() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _rotate1,
              child: Image.asset('assets/icons/img13.png', width: 80),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildDot(0), _buildDot(0.3), _buildDot(0.6)],
            ),
            const SizedBox(height: 8),
            const Text("测算中...", style: TextStyle(color: Color(0xFFDFBC69))),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _rotate1,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFDFBC69),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildResultPopup() {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/img13.png', width: 80),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showResult = false;
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FortuneDetailPage(id: detailId),
                  ),
                ).then((value) {
                  _bootstrap();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC9650),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("查看结果", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaDisplay() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppStyles.formatQuotaDisplay(_quotaInfo!.remaining, _quotaInfo!.limit),
        textAlign: TextAlign.center,
        style: AppStyles.getQuotaTextStyle(screenWidth, context),
      ),
    );
  }

  Widget _buildCardWrapper(Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final borderColor = isDark ? Colors.white24 : const Color(0xFF000000);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
