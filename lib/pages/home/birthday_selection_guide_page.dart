import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../component/bottom_date_picker.dart';
import '../../component/bottom_time_zodiac_picker.dart';
import '../../services/my_service.dart';
import '../../util/http_util.dart';

class BirthdaySelectionGuidePage extends StatefulWidget {
  const BirthdaySelectionGuidePage({super.key});

  @override
  State<BirthdaySelectionGuidePage> createState() =>
      _BirthdaySelectionGuidePageState();
}

class _BirthdaySelectionGuidePageState
    extends State<BirthdaySelectionGuidePage> {
  final _pageCtrl = PageController();
  int _index = 0;

  final _dayKey = GlobalKey<FormState>();
  final _timeKey = GlobalKey<FormState>();
  final _dayCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _dayCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    switch (_index) {
      case 1:
        final day = _dayKey.currentState?.validate() ?? true;
        if (!day) {
          return;
        }
        break;
      case 2:
        final time = _timeKey.currentState?.validate() ?? true;
        if (!time) {
          return;
        }
        _finish();
        return;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_dayCtrl.text.isEmpty) {
      MessageUtil.info(context, '出生日期不能为空');
      return;
    }
    List<String> date = _dayCtrl.text.split('-');
    await HttpUtil.request<void>(
      () => MyService.updateBirthday(
        year: date[0],
        month: date[1],
        day: date[2],
        curid: '0',
      ),
      context,
      () => mounted,
    );

    await HttpUtil.request<void>(
      () => MyService.updateMember(
        birthTime: _timeCtrl.text ?? '',
        curid: '0',
        name: '',
        sex: '',
      ),
      // ignore: use_build_context_synchronously
      context,
      () => mounted,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == 2;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black45;
    final dotColor = isDark ? Colors.white : Colors.black;
    final inputBorderColor = isDark ? Colors.white38 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 页面
                PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    // Step 1
                    Transform.translate(
                      offset: Offset(0, -4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/birthday-step-1.svg',
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: double.infinity, // 🔑 让下面的 Column 占满整行
                              child: Column(
                                children: [
                                  Transform.translate(
                                    offset: Offset(10, 0),
                                    child: Text(
                                      '欢迎使用数易赋能！',
                                      // 可选：以父宽度为基准
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '结合科学与玄学的智能运用',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Step 2
                    Transform.translate(
                      offset: Offset(0, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/birthday-step-2.svg',
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: double.infinity, // 🔑 让下面的 Column 占满整行
                              child: Column(
                                children: [
                                  Transform.translate(
                                    offset: Offset(0, 0),
                                    child: Text(
                                      '请输入生日讯息',
                                      // 可选：以父宽度为基准
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '有利于查询每天的运势数据',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _dayKey,
                              child: TextFormField(
                                controller: _dayCtrl,
                                readOnly: true,
                                // ✅ 不弹键盘
                                showCursor: false,
                                // ✅ 不显示光标
                                decoration: InputDecoration(
                                  labelText: '出生日期',
                                  labelStyle: TextStyle(
                                    color: inputBorderColor,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: inputBorderColor,
                                  ),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: inputBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: inputBorderColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? '请输入出生日期'
                                    : null,
                                onTap: () {
                                  BottomDatePicker.showDatePicker(
                                    context: context,
                                    dateFormat: 'yyyy-MM-dd',
                                    onConfirm:
                                        (String formatted, DateTime rawDate) {
                                          setState(() {
                                            _dayCtrl.text = formatted;
                                          });
                                        },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Step 3
                    Transform.translate(
                      offset: Offset(0, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/birthday-step-3.svg',
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: double.infinity, // 🔑 让下面的 Column 占满整行
                              child: Column(
                                children: [
                                  Transform.translate(
                                    offset: Offset(0, 0),
                                    child: Text(
                                      '请输入生日时间',
                                      // 可选：以父宽度为基准
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '有利于查询每天的运势数据',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _timeKey,
                              child: TextFormField(
                                controller: _timeCtrl,
                                readOnly: true,
                                // ✅ 不弹键盘
                                showCursor: false,
                                // ✅ 不显示光标
                                decoration: InputDecoration(
                                  labelText: '出生时间',
                                  labelStyle: TextStyle(
                                    color: inputBorderColor,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: inputBorderColor,
                                  ),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: inputBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: inputBorderColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? '请输入出生时间'
                                    : null,
                                onTap: () {
                                  BottomTimeZodiacPicker.showTimeZodiacPicker(
                                    context,
                                    initialValue: "未知",
                                    onConfirm: (selected) {
                                      setState(() {
                                        _timeCtrl.text = selected;
                                      });
                                    },
                                  );
                                },
                                onFieldSubmitted: (_) {
                                  if (isLast) _finish();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 底部按钮区域
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.03, // 屏幕高度的 3%
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SmoothPageIndicator(
                        controller: _pageCtrl,
                        count: 3,
                        effect: WormEffect(
                          activeDotColor: dotColor,
                          dotColor: isDark ? Colors.white.withOpacity(0.26) : Colors.black26,
                          dotHeight: 8,
                          dotWidth: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 84),
                          child: ElevatedButton(
                            onPressed: _goNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFC107),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(isLast ? '完成' : '下一步'),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '跳过',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


