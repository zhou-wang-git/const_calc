import 'package:const_calc/dto/luck_detail.dart';
import 'package:const_calc/pages/home/pdf_web_view_with_share.dart';
import 'package:const_calc/pages/home/tutor_consult_page.dart';
import 'package:const_calc/services/luck_service.dart';
import 'package:const_calc/util/http_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../component/bottom_date_picker.dart';
import '../../dto/library_character.dart';
import '../../dto/luck_detail_result.dart';
import '../../dto/name_val_pair.dart';
import '../../services/http_service.dart';
import '../../services/information_service.dart';
import '../../util/date_util.dart';
import '../../util/html_util.dart';
import '../../util/math_util.dart';
import '../../util/twin_util.dart';
import '../fortune/luck_detail_screen_tab.dart';
import '../fortune/zcx_ring_widget.dart';
import '../information/number_card_detail_page.dart';

class FortuneDetailPage extends StatefulWidget {
  final int id;

  const FortuneDetailPage({super.key, required this.id});

  @override
  State<FortuneDetailPage> createState() => _FortuneDetailPage();
}

class _FortuneDetailPage extends State<FortuneDetailPage> {
  LuckDetail? _luckDetail;
  String _typeName = '正常';

  Map<int, String> sexMapper = {2: '男', 1: '女'};
  Map<String, String> sxMapper = {
    '狗': 'assets/icons/1/1.png',
    '羊': 'assets/icons/1/2.png',
    '兔': 'assets/icons/1/3.png',
    '蛇': 'assets/icons/1/4.png',
    '龙': 'assets/icons/1/5.png',
    '鼠': 'assets/icons/1/6.png',
    '马': 'assets/icons/1/7.png',
    '牛': 'assets/icons/1/8.png',
    '猪': 'assets/icons/1/9.png',
    '虎': 'assets/icons/1/10.png',
    '鸡': 'assets/icons/1/11.png',
    '猴': 'assets/icons/1/12.png',
  };
  String? _currentSx; // 当前生肖名称，用于动态获取图片
  final Map<String, String> _typeNameMapper = {
    '1': '正常',
    '2': '昨天',
    '3': '明天',
    '4': '日期',
  };
  final _allOrbitIds = const ['1', '2', '3', '4'];
  final List<GlobalKey<ZcxRingWidgetState>> _ringKeys = List.generate(
    4,
    (_) => GlobalKey<ZcxRingWidgetState>(),
  );
  final List<Map<String, dynamic>> zcxDataList = [
    {'text': '正常'},
    {'text': '昨天'},
    {'text': '明天'},
    {'text': '日期'},
  ];

  LuckChartData chartData = LuckChartData(
    date: '',
    month: '',
    century: '',
    decade: '',
    center: '',
    topCircle: '',
    bottomCircle: '',
    leftCircle: '',
    rightCircle: '',
    squares: ['', '', '', ''],
    triangleNumbers: ['', '', '', ''],
    bottomLeft: ['', '', ''],
    bottomRight: ['', '', ''],
    fiveElements: ['', '', '', '', ''],
  );
  String? _mainWx;
  String? _mainWxx;
  String? _descHtml;
  String? _mainDescHtml;
  DateTime? _datePickerValue;
  List<NameValPair> groupNumberList = [];
  /// 获取生肖图片路径
  String _getSxImg() {
    if (_currentSx == null) return '';
    return sxMapper[_currentSx] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '测算详情',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 个人信息卡片
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    height: 230.h,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 22.w),

                        // 左侧图片（定宽 + 保例）
                        SizedBox(
                          width: 100.w,
                          child: AspectRatio(
                            aspectRatio: 466 / 686,
                            child: (_getSxImg().isNotEmpty)
                                ? (isDark
                                    ? ColorFiltered(
                                        colorFilter: const ColorFilter.matrix(<double>[
                                          -1, 0, 0, 0, 255,
                                          0, -1, 0, 0, 255,
                                          0, 0, -1, 0, 255,
                                          0, 0, 0, 1, 0,
                                        ]),
                                        child: Image.asset(_getSxImg(), fit: BoxFit.contain),
                                      )
                                    : Image.asset(_getSxImg(), fit: BoxFit.contain))
                                : const SizedBox(), // 👉 空白
                          ),
                        ),

                        SizedBox(width: 15.w),

                        // 右侧文字：垂直居中、左对齐
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('姓名', _luckDetail?.name ?? '', textColor),
                                _buildLabel(
                                  '性别',
                                  sexMapper[_luckDetail?.sex] ?? '',
                                  textColor,
                                ),
                                _buildLabel('英文名', _luckDetail?.ename ?? '', textColor),
                                _buildLabel(
                                  '出生日期',
                                  _luckDetail?.year == null
                                      ? ''
                                      : '${_luckDetail?.year}-${_luckDetail?.month}-${_luckDetail?.day}',
                                  textColor,
                                ),
                                _buildLabel(
                                  '出生时间',
                                  _luckDetail?.birthTime ?? '',
                                  textColor,
                                ),
                                _buildLabel('星座', _luckDetail?.userStar ?? '', textColor),
                                _buildLabel('方式', _typeName, textColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右上角悬浮按钮（不占布局空间）
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Row(
                      children: [
                        _buildIconBtn('assets/icons/notice.png', onTap: () {}),
                        SizedBox(width: 8.w),
                        _buildIconBtn(
                          'assets/icons/pdf.png',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PdfWebViewWithShare(
                                  url: '${HttpService.baseUrl}/report/pdf?id=${widget.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 运势推算推荐卡片
            _TitleWithGradient('运势推算', isDark: isDark),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(zcxDataList.length, (i) {
                        return ZcxRingWidget(
                          key: _ringKeys[i],
                          centerText: zcxDataList[i]['text'] ?? '',
                          size: 70,
                          ringWidth: 14,
                          gapAngle: 0.18,
                          ringIndex: i,
                          labelColor: textColor,
                          isDark: isDark,
                          onSegmentTap: _handleSegmentTap,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // 测算结果卡片
            _TitleWithGradient('测算结果', isDark: isDark),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 数字生命图
                        SizedBox(
                          width: 330.w,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 22.w),
                                  Text(
                                    '日期',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '月份',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(width: 151.w),
                                  Text(
                                    '世纪',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    '年代',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),

                              // ② 真正的图片（需要时也可再覆盖内部文字/角标）
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 400.h),
                                child: AspectRatio(
                                  aspectRatio: 1252 / 1300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: Image.asset(
                                          'assets/icons/cesuan.png',
                                          fit: BoxFit.fill,
                                        ),
                                      ),

                                      _buildText(
                                        120,
                                        50,
                                        chartData.date,
                                        TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        255,
                                        50,
                                        chartData.month,
                                        TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        997,
                                        50,
                                        chartData.century,
                                        TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        1135,
                                        50,
                                        chartData.decade,
                                        TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),

                                      _buildText(
                                        625,
                                        20,
                                        chartData.topCircle,
                                        TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        625,
                                        680,
                                        chartData.center,
                                        TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        625,
                                        1280,
                                        chartData.bottomCircle,
                                        TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        55,
                                        675,
                                        chartData.leftCircle,
                                        TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        1195,
                                        675,
                                        chartData.rightCircle,
                                        TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),

                                      _buildText(
                                        480,
                                        511,
                                        chartData.squares[0],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        780,
                                        511,
                                        chartData.squares[1],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        480,
                                        820,
                                        chartData.squares[2],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        780,
                                        820,
                                        chartData.squares[3],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),

                                      // 生日子时计算会+1，设置小标志
                                      if (_luckDetail?.birthTime ==
                                          '23-01 子时') ...[
                                        _buildText(
                                          350,
                                          240,
                                          '+1',
                                          TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                      _buildText(
                                        290,
                                        270,
                                        _luckDetail?.birthTime == '23-01 子时'
                                            ? (int.parse(chartData.triangleNumbers[0]) - 1).toString()
                                            : chartData.triangleNumbers[0],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        525,
                                        270,
                                        chartData.triangleNumbers[1],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        725,
                                        270,
                                        chartData.triangleNumbers[2],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        950,
                                        270,
                                        chartData.triangleNumbers[3],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),

                                      _buildText(
                                        130,
                                        1255,
                                        chartData.bottomLeft[0],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        265,
                                        1255,
                                        chartData.bottomLeft[1],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        395,
                                        1255,
                                        chartData.bottomLeft[2],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        850,
                                        1255,
                                        chartData.bottomRight[0],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        985,
                                        1255,
                                        chartData.bottomRight[1],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      _buildText(
                                        1122,
                                        1255,
                                        chartData.bottomRight[2],
                                        TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // 八卦盘
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 14.w),
                            _buildFiveElements(
                              'assets/icons/img003.png',
                              chartData.fiveElements[0],
                              '自身性格',
                              textColor,
                            ),
                            _buildFiveElements(
                              'assets/icons/img002.png',
                              chartData.fiveElements[1],
                              '子女财富',
                              textColor,
                            ),
                            _buildFiveElements(
                              'assets/icons/img004.png',
                              chartData.fiveElements[2],
                              '事业伴侣',
                              textColor,
                            ),
                            _buildFiveElements(
                              'assets/icons/img002.png',
                              chartData.fiveElements[3],
                              '官鬼疾病',
                              textColor,
                            ),
                            _buildFiveElements(
                              'assets/icons/img001.png',
                              chartData.fiveElements[4],
                              '父母贵人',
                              textColor,
                            ),
                            SizedBox(width: 14.w),
                          ],
                        ),
                        SizedBox(height: 6.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 几号人卡片
            _TitleWithGradient('$_mainWx号人', isDark: isDark),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 40.h),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Html(data: HtmlUtil.appendHTML(_descHtml)),
                    ),
                  ),
                ],
              ),
            ),

            // 性格总览卡片
            _TitleWithGradient('$_mainWxx性格总览', isDark: isDark),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 40.h),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Html(data: HtmlUtil.appendHTML(_mainDescHtml)),
                    ),
                  ),
                ],
              ),
            ),

            // 十三组数字排列卡片
            _TitleWithGradient('十三组数字排列', isDark: isDark),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                children: [
                  // 卡片
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 40.h),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Wrap(
                        spacing: 8, // 列间距
                        runSpacing: 0, // 行间距
                        children: groupNumberList.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.name}: ',
                                  style: TextStyle(fontSize: 14.sp, color: textColor),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final LibraryCharacter? character =
                                        await InformationService.getLibraryContent(
                                          title: item.val,
                                        );

                                    if (character == null ||
                                        character.title == null)
                                      return;

                                    navigator.push(
                                      MaterialPageRoute(
                                        builder: (_) => NumberCardDetailPage(
                                          number: character.title,
                                          fullHtmlContent: character.content,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    item.val,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFFFFC107),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFFFFC107),
                                      decorationThickness: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 点击详细咨询导师
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TutorConsultPage(),
                      ),
                    );
                  },

                  child: const Text(
                    '点击详细咨询导师 >',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, // 比原来小一点（原来是16）
                      fontWeight: FontWeight.w800, // 更粗一点，贴近示意
                      letterSpacing: 2.0, // 每个字之间的间距（可改 1.5~3.0）
                      height: 1.1, // 行高紧凑一点（可选）
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initDetail();
  }

  void _setLuckDetailState(LuckDetailResult? luckDetailResult) {
    _mainWx = luckDetailResult?.mainwx.toString() ?? '';
    _mainWxx = luckDetailResult?.mainwxx.toString() ?? '';

    chartData.fiveElements = ['', '', '', '', ''];
    if (luckDetailResult?.fullOrder != null) {
      final order = ["水", "木", "火", "土", "金"];
      final Map<String, String> map = {
        for (var item in luckDetailResult!.fullOrder)
          item.name: item.val.toString(),
      };
      chartData.fiveElements = order.map((key) => map[key] ?? '').toList();
    }
    chartData.leftCircle = '';
    chartData.center = '';
    chartData.rightCircle = '';
    chartData.topCircle = '';
    chartData.bottomCircle = '';
    chartData.bottomLeft = ['', '', ''];
    chartData.bottomRight = ['', '', ''];
    chartData.triangleNumbers = ['', '', '', ''];
    chartData.squares = ['', '', '', ''];
    if (luckDetailResult?.wuxing != null) {
      // ✅ 圆圈数字
      chartData.leftCircle = MathUtil.sumIfTwoDigits(
        luckDetailResult!.wuxing.left3 +
            luckDetailResult.wuxing.secondaryNumber +
            luckDetailResult.wuxing.right3,
      ).toString();
      chartData.center = luckDetailResult.mainwx.toString();
      chartData.rightCircle = MathUtil.sumIfTwoDigits(
        luckDetailResult.mainwx * 2,
      ).toString();
      chartData.topCircle = MathUtil.sumIfTwoDigits(
        luckDetailResult.wuxing.p1 +
            luckDetailResult.wuxing.p4 +
            luckDetailResult.mainwx,
      ).toString();
      chartData.bottomCircle = luckDetailResult.wuxing.secondaryNumber
          .toString();

      // ✅ 三角形数字
      chartData.triangleNumbers = [
        luckDetailResult.wuxing.p1.toString(),
        luckDetailResult.wuxing.p2.toString(),
        luckDetailResult.wuxing.p3.toString(),
        luckDetailResult.wuxing.p4.toString(),
      ];

      // ✅ 中心圆环与三角交集区域数字
      chartData.squares = [
        luckDetailResult.wuxing.p5.toString(),
        luckDetailResult.wuxing.p6.toString(),
        luckDetailResult.wuxing.p7.toString(),
        luckDetailResult.wuxing.p8.toString(),
      ];

      // ✅ 底部正方形数字 左
      chartData.bottomLeft = [
        luckDetailResult.wuxing.left3.toString(),
        luckDetailResult.wuxing.left2.toString(),
        luckDetailResult.wuxing.left1.toString(),
      ];
      // ✅ 底部正方形数字 右
      chartData.bottomRight = [
        luckDetailResult.wuxing.right1.toString(),
        luckDetailResult.wuxing.right2.toString(),
        luckDetailResult.wuxing.right3.toString(),
      ];
    }

    groupNumberList = luckDetailResult?.list == null
        ? []
        : luckDetailResult!.list.sublist(3);
  }

  Widget _buildText(double x, double y, String text, TextStyle style) {
    return Align(
      alignment: FractionalOffset(x / 1252, y / 1300),
      child: Text(text, style: style),
    );
  }

  /// ✅ 圆环点击事件
  Future<void> _handleSegmentTap(int tappedRing, int tappedSegment) async {
    // 1) 清除其他圆环
    for (int i = 0; i < _ringKeys.length; i++) {
      if (i != tappedRing) {
        _ringKeys[i].currentState?.clearSelection();
      }
    }

    // 2) 点击"日期"且 segment 为 0：弹出日期选择器
    if (tappedRing == 3 && tappedSegment == 0) {
      BottomDatePicker.showDatePicker(
        context: context,
        dateFormat: 'yyyy年MM月dd日',
        onConfirm: (formattedDate, rawDate) {
          if (!mounted) return;
          setState(() {
            _datePickerValue = rawDate;
          });
        },
        confirmColor: const Color(0xFFFFC107),
        cancelColor: Colors.grey,
      );
    }

    // 3) 先同步更新文案（不含任何 await）
    setState(() {
      // 点击"正常"(tappedRing=0)的中心按钮，恢复基础命盘
      if (tappedRing == 0 && tappedSegment == 0) {
        LuckDetailResult? luckDetailResult = LuckDetailResult.fromJsonString(
          _luckDetail?.result,
        );
        _descHtml = _luckDetail?.desc;
        _mainDescHtml = _luckDetail?.mainDesc;
        _setLuckDetailState(luckDetailResult);
      } else if ([1, 2, 3].contains(tappedRing) && tappedSegment == 0) {
        final tip = tappedRing == 3
            ? '<p style="text-align: center;">请先选择日期，再点击流年或流月或流日查看解析</p>'
            : '<p style="text-align: center;">请选择流年或者流月或者流日获取解析</p>';
        _descHtml = tip;
        _mainDescHtml = tip;
      }

      switch (tappedSegment) {
        case 1:
          _descHtml = _luckDetail?.desc0;
          _mainDescHtml = _luckDetail?.mainDesc0;
          break;
        case 2:
          _descHtml = _luckDetail?.desc1;
          _mainDescHtml = _luckDetail?.mainDesc1;
          break;
        case 3:
          _descHtml = _luckDetail?.desc2;
          _mainDescHtml = _luckDetail?.mainDesc2;
          break;
      }

      _typeName = _typeNameMapper[_allOrbitIds[tappedRing]] ?? '';
    });

    // 4) 根据 tappedRing 确定目标日期
    DateTime targetDate = DateTime.now();
    if (tappedRing == 1) {
      targetDate = DateTime.now().subtract(const Duration(days: 1)); // 昨天
    } else if (tappedRing == 2) {
      targetDate = DateTime.now().add(const Duration(days: 1)); // 明天
    } else if (tappedRing == 3 && _datePickerValue != null) {
      targetDate = _datePickerValue!; // 选择的日期
    }

    String year = targetDate.year.toString();
    String month = targetDate.month.toString().padLeft(2, '0');
    String day = targetDate.day.toString().padLeft(2, '0');

    // 获取用于计算的生日（如果是双胞胎则使用虚拟生日）
    String birthMonth = _luckDetail?.month ?? '';
    String birthDay = _luckDetail?.day ?? '';

    // 如果是双胞胎，计算虚拟生日
    if (_luckDetail != null &&
        _luckDetail!.twinStatus != 0 &&
        _luckDetail!.parentYear != null &&
        _luckDetail!.parentMonth != null &&
        _luckDetail!.parentDay != null) {
      final virtualBirthday = TwinUtil.calculateVirtualBirthday(
        '${_luckDetail!.year}-${_luckDetail!.month}-${_luckDetail!.day}',
        '${_luckDetail!.parentYear}-${_luckDetail!.parentMonth}-${_luckDetail!.parentDay}',
      );
      final parts = virtualBirthday.split('-');
      birthMonth = parts[1];
      birthDay = parts[2];
    }

    // 子时处理：提前把出生日期+1，后续计算逻辑不变
    if (_luckDetail?.birthTime == '23-01 子时') {
      final birthYear = _luckDetail?.year ?? year;
      final originalDate = DateTime(
        int.parse(birthYear),
        int.parse(birthMonth),
        int.parse(birthDay),
      );
      final nextDate = originalDate.add(const Duration(days: 1));
      birthMonth = nextDate.month.toString().padLeft(2, '0');
      birthDay = nextDate.day.toString().padLeft(2, '0');
    }

    // 流年
    if (tappedSegment == 1) {
      month = birthMonth;
      day = birthDay;
    }

    // 流月
    if (tappedSegment == 2) {
      final baseM = int.tryParse(birthMonth) ?? 0;
      final nowM = int.tryParse(month) ?? 0;
      month = (baseM + nowM).toString().padLeft(2, '0');
      day = birthDay;
    }

    // 流日
    if (tappedSegment == 3) {
      final baseM = int.tryParse(birthMonth) ?? 0;
      final nowM = int.tryParse(month) ?? 0;
      month = (baseM + nowM).toString().padLeft(2, '0');

      final baseD = int.tryParse(birthDay) ?? 0;
      final nowD = int.tryParse(day) ?? 0;
      day = (baseD + nowD).toString().padLeft(2, '0');
    }

    // 5) 需要请求时，先 await，再同步 setState
    if (tappedSegment != 0) {
      final LuckDetailResult? luckDetailResult =
      await HttpUtil.request<LuckDetailResult?>(
            () => LuckService.getRes(year: year, month: month, day: day),
        context,
            () => mounted,
      );

      if (luckDetailResult != null) {
        final mainWxNum = luckDetailResult.mainwx.toString();
        final mainWxxNum = luckDetailResult.mainwxx.toString();

        final mainWxCharacter = await InformationService.getLibraryContent(
          title: mainWxNum,
        );
        final mainWxxCharacter = await InformationService.getLibraryContent(
          title: mainWxxNum,
        );

        final mainWxDesc = mainWxCharacter?.content;
        final mainWxxDesc = mainWxxCharacter?.content;

        if (!mounted) return;
        setState(() {
          _descHtml = mainWxDesc ?? _descHtml;
          _mainDescHtml = mainWxxDesc ?? _mainDescHtml;
          _currentSx = luckDetailResult.list[2].val;
          _setLuckDetailState(luckDetailResult);
        });
      }
    }
  }

  Future<void> _initDetail() async {
    final luckDetail = await HttpUtil.request<LuckDetail>(
      () => LuckService.getDetail(id: widget.id),
      context,
      () => mounted,
    );
    if (luckDetail == null) return;

    setState(() {
      _currentSx = luckDetail.userSx;
      _luckDetail = luckDetail;
    });

    setState(() {
      // ✅ 日期，月份，世纪，年代 下方正方形数值
      chartData.date = _luckDetail?.day ?? '';
      chartData.month = _luckDetail?.month ?? '';
      chartData.century = _luckDetail?.year.substring(0, 2) ?? '';
      chartData.decade = _luckDetail?.year.substring(2, 4) ?? '';
      LuckDetailResult? luckDetailResult = LuckDetailResult.fromJsonString(
        luckDetail.result,
      );
      _descHtml = _luckDetail?.desc;
      _mainDescHtml = _luckDetail?.mainDesc;
      _setLuckDetailState(luckDetailResult);
    });
  }

  Widget _buildFiveElements(String img, String num, String nature, Color textColor) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w), // 列间距
        child: Column(
          children: [
            SizedBox(
              height: 38.w, // 图标尺寸（按需调）
              child: Image.asset(img, fit: BoxFit.contain),
            ),
            SizedBox(height: 8.h),
            Text(
              num,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 8.h),
            Text(
              nature,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 小图标按钮（白底圆角可选）
  Widget _buildIconBtn(String asset, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shouldInvert = isDark && asset.contains('notice.png');

    return GestureDetector(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: shouldInvert
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain),
                )
              : Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, String value, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$label：',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFFFFC107)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, color: textColor),
          ),
        ],
      ),
    );
  }
}

/// 标题 + 两侧渐变分割线
class _TitleWithGradient extends StatelessWidget {
  const _TitleWithGradient(
    this.title, {
    super.key,
    this.top = 12,
    this.bottom = 8,
    this.gap = 18,
    this.thickness = 3.5,
    this.color = const Color(0xFFFBBF08),
    this.textStyle,
    this.isDark = false,
  });

  final String title;
  final double top;
  final double bottom;
  final double gap;
  final double thickness;
  final Color color;
  final TextStyle? textStyle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.only(top: top.h, bottom: bottom.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左：背景色 -> 主题色
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: gap.w),
              height: thickness.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(thickness.r),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [bgColor, const Color(0xFFFBBF08)],
                ),
              ),
            ),
          ),

          // 中间标题
          Text(
            title,
            style:
                textStyle ??
                TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: textColor,
                ),
          ),

          // 右：主题色 -> 背景色
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: gap.w),
              height: thickness.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(), // 圆角已在高度内足够小，可省
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [const Color(0xFFFBBF08), bgColor],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

