import 'package:const_calc/component/bottom_date_picker.dart';
import 'package:const_calc/component/bottom_time_zodiac_picker.dart';
import 'package:const_calc/util/loading_util.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../handler/api_exception.dart';
import '../../models/qimen_result.dart';
import '../../services/digit_calculation_service.dart';
import '../../util/date_util.dart';
import '../../util/dialog_util.dart';
import '../../util/http_util.dart';
import '../../util/app_styles.dart';
import '../my/member_privilege_page.dart';
import 'name_result_page.dart';

class NameCalculationPage extends StatefulWidget {
  const NameCalculationPage({super.key});

  @override
  State<NameCalculationPage> createState() => _NameCalculationPageState();
}

class _NameCalculationPageState extends State<NameCalculationPage> {
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String birthday = "请选择";
  String birthTime = "请选择";
  int gender = 0;
  QuotaInfo? _quotaInfo;

  @override
  void initState() {
    super.initState();
    _initQuotaCheck();
  }

  /// 初始化配额检查
  Future<void> _initQuotaCheck() async {
    try {
      if (!mounted) return;
      final QuotaInfo? quotaInfo = await HttpUtil.request<QuotaInfo?>(
        () => DigitCalculationService.checkNameQuota(),
        context,
        () => mounted,
      );

      print('NameCalculation _initQuotaCheck: quotaInfo=${quotaInfo?.remaining}/${quotaInfo?.limit}');

      if (!mounted) return;
      setState(() {
        _quotaInfo = quotaInfo;
      });
    } catch (e) {
      print('NameCalculation _initQuotaCheck error: $e');
    }
  }

  Future<void> _submit() async {
    // 预检查配额
    if (_quotaInfo != null && _quotaInfo!.remaining <= 0) {
      final confirmed = await DialogUtil.confirm(
        context,
        title: '提示',
        content: '您的查询次数已用完，是否前往开通会员？',
        confirmText: '前往开通',
        cancelText: '取消',
      );
      if (confirmed == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MemberPrivilegePage()),
        );
      }
      return;
    }

    if (_surnameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        birthday == "请选择" ||
        birthTime == "请选择" ||
        gender == 0) {
      MessageUtil.info(context, '请填写完整表单信息');
      return;
    }
    final RegExp chineseRegex = RegExp(r'^[\u4e00-\u9fa5]+$');
    if (!chineseRegex.hasMatch(_surnameController.text)) {
      MessageUtil.info(context, '姓必须是中文');
      return;
    }
    if (!chineseRegex.hasMatch(_nameController.text)) {
      MessageUtil.info(context, '名必须是中文');
      return;
    }
    final navigator = Navigator.of(context);

    try {
      LoadingUtil.openLoading(context);

      List<String> birthdayList = birthday.split('-');
      final digitCalculation = await DigitCalculationService.getNameResultList(
        year: birthdayList[0],
        month: birthdayList[1],
        day: birthdayList[2],
        surname: _surnameController.text,
        lastName: _nameController.text,
        sex: gender.toString(),
        hm: birthTime,
      );

      if (!mounted) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => NameResultPage(id: digitCalculation.id.toString()),
        ),
      );
    } catch (e, stack) {
      debugPrint('$e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      if (e is ApiException) {
        ApiException apiException = e;
        MessageUtil.info(context, apiException.message);
        return;
      }
      MessageUtil.info(context, '未知错误');
    } finally {
      LoadingUtil.closeLoading();
    }
  }

  Future<void> _pickDate() async {
    BottomDatePicker.showDatePicker(
      context: context,
      dateFormat: 'yyyy-MM-dd',
      initialDate: DateUtil.parseDate(birthday, 'yyyy-MM-dd'),
      onConfirm: (String formatted, DateTime rawDate) {
        setState(() {
          birthday = formatted;
        });
      },
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          '姓名测算',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部图片
            Image.asset(
              'assets/icons/img09.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),

            // 表单 + 背景区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                children: [
                  // 显示剩余查询次数
                  if (_quotaInfo != null) _buildQuotaInfo(),
                  if (_quotaInfo != null) const SizedBox(height: 12),
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
                  _buildCardWrapper(_buildInputRow("姓", _surnameController)),
                  _buildCardWrapper(_buildInputRow("名", _nameController)),
                  _buildCardWrapper(
                    _buildPickerRow("出生日期", birthday, _pickDate),
                  ),
                  _buildCardWrapper(
                    _buildPickerRow("出生时分", birthTime, _pickTime),
                  ),
                  _buildCardWrapper(_buildGenderSelector()),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _submit,
                    child: Image.asset(
                      'assets/icons/start.png',
                      width: 240,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final inputTextColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: theme.colorScheme.primary,
              style: TextStyle(color: inputTextColor),
              decoration: InputDecoration(
                hintText: "请输入$label",
                hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
                filled: true,
                fillColor: inputBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
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
            width: 80.w,
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
      height: 50.h,
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Center(
              child: Text(
                "性别",
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
                  onChanged: (val) => setState(() => gender = val!),
                ),
                Text("男", style: TextStyle(color: labelColor)),
                const SizedBox(width: 20),
                Radio<int>(
                  value: 1,
                  groupValue: gender,
                  activeColor: radioActiveColor,
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

  Widget _buildCardWrapper(Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.black;

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

  /// 构建剩余查询次数显示
  Widget _buildQuotaInfo() {
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
}
