import 'package:const_calc/pages/fortune/zcx_ring_widget.dart';
import 'package:const_calc/util/date_util.dart';
import 'package:const_calc/util/math_util.dart';
import 'package:const_calc/util/twin_util.dart';
import 'package:flutter/material.dart';

import '../../component/bottom_date_picker.dart';
import '../../dto/luck_detail.dart';
import '../../dto/luck_detail_result.dart';
import '../../dto/my_fortune.dart';
import '../../dto/user.dart';
import '../../services/luck_service.dart';
import '../../services/user_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../home/birthday_selection_guide_page.dart';
import 'luck_13_group_tab.dart';
import 'luck_detail_screen_tab.dart';
import 'luck_header_card.dart';
import 'luck_main_person_tab.dart';

class LuckPage extends StatefulWidget {
  const LuckPage({super.key});

  @override
  FortunePageState createState() => FortunePageState();
}

class FortunePageState extends State<LuckPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> zcxDataList = [
    {'text': '正常', 'val': 0, 'val2': 1, 'val3': 2, 'val4': 3},
    {'text': '昨天', 'val': 4, 'val2': 7, 'val3': 8, 'val4': 9},
    {'text': '明天', 'val': 5, 'val2': 10, 'val3': 11, 'val4': 12},
    {'text': '日期', 'val': 6, 'val2': 13, 'val3': 14, 'val4': 15},
  ];
  final List<GlobalKey<ZcxRingWidgetState>> _ringKeys = List.generate(
    4,
    (_) => GlobalKey<ZcxRingWidgetState>(),
  );

  LuckDetail? _luckDetail;
  String? _descHtml;
  String? _mainDescHtml;
  String? _mainWx;
  String? _mainWxx;
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
  DateTime? _datePickerValue;
  final LuckHeaderData _luckHeaderData = LuckHeaderData();
  List<LuckTextItem> _luck13GroupItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Tab 切换时刷新页面
    });
    // 页面加载完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMyFortune();
    });
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
        onConfirm: (formattedDate, rawDate) {
          if (!mounted) return;
          setState(() {
            _datePickerValue = rawDate; // 放进 setState 触发重建
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
      if (!mounted) return;
      setState(() {
        _setLuckDetailState(luckDetailResult);
      });
    }
  }


  /// ✅ 初始化我的运势数据
  void _initMyFortune({bool isCheck = true}) async {
    try {
      UserService.clearCache();
      final User? user = await UserService().getUserInfo();
      if (user == null && mounted) {
        return;
      }

      if (!mounted) return; // ✅ 安全使用 context
      if (isCheck &&
          (user?.year == null || user!.year.isEmpty || user.year == '0')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdaySelectionGuidePage()),
        ).then((onValue) {
          _initMyFortune(isCheck: false);
        });
        return;
      }

      if ((user?.year == null || user!.year.isEmpty || user.year == '0')) {
        return;
      }

      final MyFortune? myFortune = await HttpUtil.request<MyFortune?>(
        () => LuckService.getMyFortune(),
        context,
        () => mounted,
      );
      if (myFortune == null) {
        return;
      }

      if (!mounted) return;
      final LuckDetail? luckDetail = await HttpUtil.request<LuckDetail?>(
        () => LuckService.getDetail(id: myFortune.id),
        context,
        () => mounted,
      );
      if (luckDetail == null) {
        return;
      }

      setState(() {
        _luckDetail = luckDetail;
        _luckHeaderData.realName = myFortune.realName;
        _luckHeaderData.luckDateStr =
            '${_luckDetail?.year ?? ''}-${_luckDetail?.month ?? ''}-${_luckDetail?.day ?? ''}';
        _luckHeaderData.luckWeekStr = _getWeekdayFromDateString(
          _luckHeaderData.luckDateStr,
        );
        _luckHeaderData.sex = _luckDetail?.sex == 2 ? '男' : '女';
        _luckHeaderData.birthday =
            '${_luckDetail?.month ?? ''}-${_luckDetail?.day ?? ''}';
        _luckHeaderData.userStar = _luckDetail?.userStar ?? '';
        _luckHeaderData.birthTime = _luckDetail?.birthTime ?? '';
        _luckHeaderData.userSx = _luckDetail?.userSx ?? '';

        // ✅ tab1 数字排列推敲
        // ✅ 日期，月份，世纪，年代 下方正方形数值
        chartData.date = _luckDetail?.day ?? '';
        chartData.month = _luckDetail?.month ?? '';
        chartData.century = _luckDetail?.year.substring(0, 2) ?? '';
        chartData.decade = _luckDetail?.year.substring(2, 4) ?? '';
        LuckDetailResult? luckDetailResult = LuckDetailResult.fromJsonString(
          luckDetail.result,
        );
        _setLuckDetailState(luckDetailResult);

        // ✅ tab2 主性格总运势
        _descHtml = _luckDetail?.desc;
        _mainDescHtml = _luckDetail?.mainDesc;
      });
    } catch (e) {
      // 已在 HttpUtil 中统一处理错误，无需重复提示
    }
  }

  void _setLuckDetailState(LuckDetailResult? luckDetailResult) {
    _mainWx = luckDetailResult?.mainwx.toString() ?? '';
    _luckHeaderData.mainWx = _mainWx;
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
            luckDetailResult.wuxing.right3 +
            luckDetailResult.wuxing.secondaryNumber,
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

    if (luckDetailResult?.list != null) {
      final map = {for (var e in luckDetailResult!.list) e.name: e.val};
      _luck13GroupItems = [
        // 左侧
        LuckTextItem(
          number: map['父基因'] ?? '0',
          text: '父基因: ${map['父基因'] ?? '0'}',
          topPercent: 0.075,
          leftPercent: 0.178,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['主性格'] ?? '0',
          text: '主性格: ${map['主性格'] ?? '0'}',
          topPercent: 0.185,
          leftPercent: 0.225,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['人生过程(母)'] ?? '0',
          text: '人生过程(母): ${map['人生过程(母)'] ?? '0'}',
          topPercent: 0.307,
          leftPercent: 0.115,
          fontSizePercent: 0.028,
        ),
        LuckTextItem(
          number: map['事业过程(1)'] ?? '0',
          text: '事业过程(1): ${map['事业过程(1)'] ?? '0'}',
          topPercent: 0.432,
          leftPercent: 0.035,
          fontSizePercent: 0.028,
        ),
        LuckTextItem(
          number: map['当下朋友/事业'] ?? '0',
          text: '当下朋友/事业: ${map['当下朋友/事业'] ?? '0'}',
          topPercent: 0.558,
          leftPercent: 0.085,
          fontSizePercent: 0.028,
        ),
        LuckTextItem(
          number: map['婚姻(2)'] ?? '0',
          text: '婚姻(2): ${map['婚姻(2)'] ?? '0'}',
          topPercent: 0.678,
          leftPercent: 0.16,
          fontSizePercent: 0.028,
        ),

        // 右侧
        LuckTextItem(
          number: map['母基因'] ?? '0',
          text: '母基因: ${map['母基因'] ?? '0'}',
          topPercent: 0.020,
          rightPercent: 0.322,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['人生过程(父)'] ?? '0',
          text: '人生过程(父): ${map['人生过程(父)'] ?? '0'}',
          topPercent: 0.135,
          rightPercent: 0.113,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['子女下属'] ?? '0',
          text: '子女下属: ${map['子女下属'] ?? '0'}',
          topPercent: 0.265,
          rightPercent: 0.09,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['事业过程(2)'] ?? '0',
          text: '事业过程(2): ${map['事业过程(2)'] ?? '0'}',
          topPercent: 0.393,
          rightPercent: 0.02,
          fontSizePercent: 0.03,
        ),
        LuckTextItem(
          number: map['婚姻(1)'] ?? '0',
          text: '婚姻(1): ${map['婚姻(1)'] ?? '0'}',
          topPercent: 0.5,
          rightPercent: 0.2,
          fontSizePercent: 0.028,
        ),
        LuckTextItem(
          number: map['未来财富/健康/子女'] ?? '0',
          text: '未来财富/健康/子女: ${map['未来财富/健康/子女'] ?? '0'}',
          topPercent: 0.63,
          rightPercent: 0.085,
          fontSizePercent: 0.028,
        ),
        LuckTextItem(
          number: map['隐藏号'] ?? '0',
          text: '隐藏号: ${map['隐藏号'] ?? '0'}',
          topPercent: 0.747,
          rightPercent: 0.25,
          fontSizePercent: 0.026,
        ),
      ];
    }
  }

  String _getWeekdayFromDateString(String? dateStr) {
    try {
      if (dateStr == null) {
        return '';
      }
      final date = DateTime.parse(dateStr);
      const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      return weekdays[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 不让键盘推挤布局
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            '我的运势',
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
              const SizedBox(height: 20),
              // ✅ 头部区域 头像 生日信息
              LuckHeaderCard(data: _luckHeaderData),

              // ✅ 添加圆环图区域
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Container(
                  height: screenWidth * 0.3, // 自适应高度
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.12),
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
                        labelColor: labelColor,
                        isDark: isDark,
                        onSegmentTap: _handleSegmentTap,
                      );
                    }),
                  ),
                ),
              ),

              // Tab导航栏
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ 顶部 TabBar
                      Container(
                        height: 48,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: isDark ? const Color(0xFFFFD54F) : theme.primaryColor,
                          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
                          indicatorColor: Colors.transparent,
                          indicatorWeight: 0,
                          indicator: const BoxDecoration(),
                          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          unselectedLabelStyle: const TextStyle(fontSize: 13),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          tabs: const [
                            Tab(text: '数字排列推敲'),
                            Tab(text: '主性格总运势'),
                            Tab(text: '13组数字解析'),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // ✅ Tab 内容，统一在一个容器中
                      Padding(
                        padding: const EdgeInsets.all(12), // 内容内部间距
                        child: Builder(
                          builder: (_) {
                            if (_tabController.index == 0) {
                              return LuckDetailScreenTab(data: chartData);
                            } else if (_tabController.index == 1) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LuckMainPersonTab(
                                    title: '${_mainWx ?? ''}号人',
                                    htmlContent: _descHtml ?? '',
                                  ),
                                  SizedBox(height: 20),
                                  LuckMainPersonTab(
                                    title: '${_mainWxx ?? ''}性格总览',
                                    htmlContent: _mainDescHtml ?? '',
                                  ),
                                ],
                              );
                            } else {
                              return Luck13GroupTab(
                                margin: EdgeInsets.zero,
                                items: _luck13GroupItems,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
