import 'package:const_calc/util/loading_util.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../component/safe_web_view.dart';
import '../../dto/digit_calculation_info.dart';
import '../../dto/digit_calculation_name_result.dart';
import '../../dto/luck_detail_result.dart';
import '../../dto/name_profile_config.dart';
import '../../dto/radical.dart';
import '../../handler/api_exception.dart';
import '../../services/digit_calculation_service.dart';
import '../../services/http_service.dart';
import '../../services/information_service.dart';
import '../../util/html_util.dart';
import 'name_scorer.dart';
import 'tutor_consult_page.dart';

class NameResultPage extends StatefulWidget {
  final String id;

  const NameResultPage({super.key, required this.id});

  @override
  State<NameResultPage> createState() => _NameResultPage();
}

class _NameResultPage extends State<NameResultPage> {
  String? _nameChar1; // 姓名1
  String? _nameChar2; // 姓名2
  String? _nameChar3; // 姓名3
  String? _nameChar4; // 姓名4
  String? _nameReport; // 姓名报告
  String? _sex; // 性别
  String? _chineseZodiac; // 生肖
  List<List<String>>? _rows; // 3 行：字 / 笔画 / 象 / 五行
  List<List<String>>? _explainList; // 左边“关键字” + 右边解释

  final Map<String, String> chineseZodiacImgMapper = {
    '狗': 'assets/icons/12sx/gou.png',
    '猴': 'assets/icons/12sx/hou.png',
    '虎': 'assets/icons/12sx/hu.png',
    '鸡': 'assets/icons/12sx/ji.png',
    '龙': 'assets/icons/12sx/long.png',
    '马': 'assets/icons/12sx/ma.png',
    '牛': 'assets/icons/12sx/niu.png',
    '蛇': 'assets/icons/12sx/she.png',
    '鼠': 'assets/icons/12sx/shu.png',
    '兔': 'assets/icons/12sx/tu.png',
    '羊': 'assets/icons/12sx/yang.png',
    '猪': 'assets/icons/12sx/zhu.png',
  };

  final Map<String, String> sexImgMapper = {
    '1': 'assets/icons/sex_man.png',
    '2': 'assets/icons/sex_nv.png',
  };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _init();
  }

  Future<void> _init() async {
    try {
      LoadingUtil.openLoading(context);
      final DigitCalculationInfo digitCalculationInfo =
          await DigitCalculationService.getDetail(id: int.parse(widget.id));

      List<DigitCalculationNameResult>? result4List =
          DigitCalculationNameResult.listFromJsonString(
            digitCalculationInfo.result4,
          );
      List<DigitCalculationNameResult>? result5List =
          DigitCalculationNameResult.listFromJsonString(
            digitCalculationInfo.result5,
          );
      List<DigitCalculationNameResult>? result6List =
          DigitCalculationNameResult.listFromJsonString(
            digitCalculationInfo.result6,
          );
      List<DigitCalculationNameResult>? result7List =
          DigitCalculationNameResult.listFromJsonString(
            digitCalculationInfo.result7,
          );

      DigitCalculationNameResult? result4;
      DigitCalculationNameResult? result5;
      DigitCalculationNameResult? result6;
      DigitCalculationNameResult? result7;

      List<List<String>> rows = [];
      List<List<String>> explainList = [];

      Map<String, String> radicalFiveElements = {};
      List<int> strokesList = [];
      List<String> radicalList = [];
      List<String> pyList = [];

      if (result4List != null && result4List.isNotEmpty) {
        result4 = result4List[0];
        rows.add([
          result4.hanzi,
          result4.bushou,
          result4.bihua.toString(),
          result4.py,
        ]);

        Radical radical = await InformationService.getRadical(
          title: result4.bushou,
        );
        strokesList.add(result4.bihua);
        radicalList.add(result4.bushou);
        pyList.add(result4.py);
        radicalFiveElements[result4.bushou] = _extractFiveElementsNo(
          radical.info,
        ).join(',');
        explainList.add([
          result4.hanzi,
          '${_cleanContent(result4.content)}${radical.info.isEmpty ? '' : '</br></br>${radical.info}'}',
        ]);
      }

      if (result5List != null && result5List.isNotEmpty) {
        result5 = result5List[0];
        rows.add([
          result5.hanzi,
          result5.bushou,
          result5.bihua.toString(),
          result5.py,
        ]);

        Radical radical = await InformationService.getRadical(
          title: result5.bushou,
        );
        strokesList.add(result5.bihua);
        radicalList.add(result5.bushou);
        pyList.add(result5.py);
        radicalFiveElements[result5.bushou] = _extractFiveElementsNo(
          radical.info,
        ).join(',');
        explainList.add([
          result5.hanzi,
          '${_cleanContent(result5.content)}${radical.info.isEmpty ? '' : '</br></br>${radical.info}'}',
        ]);
      }

      if (result6List != null && result6List.isNotEmpty) {
        result6 = result6List[0];
        rows.add([
          result6.hanzi,
          result6.bushou,
          result6.bihua.toString(),
          result6.py,
        ]);

        Radical radical = await InformationService.getRadical(
          title: result6.bushou,
        );
        strokesList.add(result6.bihua);
        radicalList.add(result6.bushou);
        pyList.add(result6.py);
        radicalFiveElements[result6.bushou] = _extractFiveElementsNo(
          radical.info,
        ).join(',');
        explainList.add([
          result6.hanzi,
          '${_cleanContent(result6.content)}${radical.info.isEmpty ? '' : '</br></br>${radical.info}'}',
        ]);
      }

      if (result7List != null && result7List.isNotEmpty) {
        result7 = result7List[0];
        rows.add([
          result7.hanzi,
          result7.bushou,
          result7.bihua.toString(),
          result7.py,
        ]);

        Radical radical = await InformationService.getRadical(
          title: result7.bushou,
        );
        strokesList.add(result7.bihua);
        radicalList.add(result7.bushou);
        pyList.add(result7.py);
        radicalFiveElements[result7.bushou] = _extractFiveElementsNo(
          radical.info,
        ).join(',');
        explainList.add([
          result7.hanzi,
          '${_cleanContent(result7.content)}${radical.info.isEmpty ? '' : '</br></br>${radical.info}'}',
        ]);
      }

      LuckDetailResult? luckDetailResult = LuckDetailResult.fromJsonString(
        digitCalculationInfo.result,
      );

      String nameReport = '';
      try {
        final radicals = RadicalProvider.fromMap(radicalFiveElements);
        String hm = digitCalculationInfo.hm ?? '';
        if (hm.contains(':')) {
          hm = _getChineseHourRange(hm);
        } else {
          hm = _extractRange(hm);
        }
        int year = int.parse(digitCalculationInfo.year ?? '-1');
        int month = int.parse(digitCalculationInfo.month ?? '-1');
        int day = int.parse(digitCalculationInfo.day ?? '-1');
        if (digitCalculationInfo.birthTime == '23-01 子时') {
          DateTime addDate = _addOneDay(year, month, day);
          year = addDate.year;
          month = addDate.month;
          day = addDate.day;
        }
        final dob = Shichen.toDateTime(
          birthDate: DateTime(year, month, day),
          shichenOrRange: hm,
        );
        final cfg = ScoringConfig();
        NameProfileConfig config =
            await DigitCalculationService.getNameProfileConfig();
        cfg.weights = config.toMap();

        final scorer = NameScorer(cfg: cfg, radicals: radicals);
        final p = NameProfile(
          fullName: digitCalculationInfo.name ?? '',
          surname: digitCalculationInfo.surname ?? '',
          givenName: digitCalculationInfo.lastName ?? '',
          strokes: strokesList,
          radicals: radicalList,
          pinyin: pyList,
          birthDateTime: dob,
          zodiacZh: digitCalculationInfo.userSx,
          gender: digitCalculationInfo.sex == 2 ? Gender.male : Gender.female,
          personalityNumber: luckDetailResult?.mainwx ?? 0,
        );

        final s = scorer.score(p);
        nameReport = NameReport.generateParagraphs(p, s);
      } catch (e) {
        debugPrint('$e');
      }

      setState(() {
        _nameChar1 = result4?.hanzi ?? '';
        _nameChar2 = result5?.hanzi ?? '';
        _nameChar3 = result6?.hanzi ?? '';
        _nameChar4 = result7?.hanzi ?? '';
        _chineseZodiac = digitCalculationInfo.userSx ?? '';
        _sex = digitCalculationInfo.sex.toString();
        _rows = rows;
        _explainList = explainList;
        _nameReport = nameReport;
      });
    } catch (e, stack) {
      debugPrint('$e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      if (e is ApiException) {
        MessageUtil.info(context, e.message);
        return;
      }
      MessageUtil.info(context, '未知错误');
    } finally {
      LoadingUtil.closeLoading();
    }
  }

  DateTime _addOneDay(int year, int month, int day) {
    var date = DateTime(year, month, day);
    return date.add(const Duration(days: 1));
  }

  String _getChineseHourRange(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return '';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '';
    // 转换成总分钟
    final totalMinutes = hour * 60 + minute;
    // 定义 12 时辰区间（起始分钟，结束分钟，返回值）
    final ranges = [
      [23 * 60, 24 * 60, '23-1'], // 23:00-24:00
      [0, 60, '23-1'], // 00:00-01:00
      [60, 180, '1-3'], // 01:00-03:00
      [180, 300, '3-5'], // 03:00-05:00
      [300, 420, '5-7'], // 05:00-07:00
      [420, 540, '7-9'], // 07:00-09:00
      [540, 660, '9-11'], // 09:00-11:00
      [660, 780, '11-13'], // 11:00-13:00
      [780, 900, '13-15'], // 13:00-15:00
      [900, 1020, '15-17'], // 15:00-17:00
      [1020, 1140, '17-19'], // 17:00-19:00
      [1140, 1260, '19-21'], // 19:00-21:00
      [1260, 1380, '21-23'], // 21:00-23:00
    ];
    for (var r in ranges) {
      final start = r[0] as int;
      final end = r[1] as int;
      final label = r[2] as String;

      if (totalMinutes >= start && totalMinutes < end) {
        return label;
      }
    }
    return '';
  }

  String _extractRange(String input) {
    // 找到 "-" 的位置
    final dashIndex = input.indexOf('-');
    if (dashIndex == -1) return '';

    // 拿到 "-" 前后的数字部分
    final startStr = input.substring(0, dashIndex);
    final endStr = input.substring(dashIndex + 1, dashIndex + 3); // 取后两位数字

    // 转 int 自动去掉前导 0
    final start = int.parse(startStr);
    final end = int.parse(endStr);

    return '$start-$end';
  }

  List<String> _extractFiveElementsNo(String raw) {
    const elements = ['金', '木', '水', '火', '土'];
    final idx = raw.indexOf('五行归属');
    if (idx == -1) return [];
    // 截取 "五行归属" 后的一小段，最多 30 个字符
    final sub = raw.substring(idx, (idx + 30).clamp(0, raw.length));
    // 优先判断“无特定”
    if (sub.contains('无特定')) {
      return [];
    }
    // 依次检查五行字，按出现顺序收集
    final results = <String>[];
    for (var e in elements) {
      if (sub.contains(e)) results.add(e);
    }
    return results;
  }

  String _cleanContent(String content) {
    return content
        // 去掉前三个 <br> 及之前的内容
        .replaceFirst(RegExp(r'^.*?<br>.*?<br>.*?<br>'), '')
        // 去掉所有 HTML 标签
        .replaceAll(RegExp(r'<[^>]+>'), '')
        // 去掉英文字母和点号
        .replaceAll(RegExp(r'[a-zA-Z.]+'), '');
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
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          '测算结果',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部叠加图片
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景1（大）
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/icons/12sx/bg1.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 背景2 + 四角文字
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/12sx/bg2.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ 最上层中心覆盖图
                  Align(
                    alignment: Alignment.center,
                    child: () {
                      final String? zodiacPath =
                          chineseZodiacImgMapper[_chineseZodiac ?? ''];
                      if (zodiacPath != null && zodiacPath.isNotEmpty) {
                        return Image.asset(
                          zodiacPath,
                          width: MediaQuery.of(context).size.width * 0.48,
                          fit: BoxFit.contain,
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                  ),

                  // 🔹右上角按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildIconBtn(
                          'assets/icons/notice.png',
                          onTap: () {
                            // TODO: 提示逻辑
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildIconBtn(
                          'assets/icons/pdf.png',
                          onTap: () async {
                            final pdfUrl =
                                '${HttpService.domain}/pdfjs/web/viewer.html?file=${HttpService.baseUrl}/report/pdf?id=${widget.id}';
                            if (kIsWeb) {
                              // Web 平台使用 url_launcher 在新标签页打开
                              final uri = Uri.parse(pdfUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } else {
                              // 原生平台使用 WebView
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SafeWebViewPage(
                                    url: pdfUrl,
                                    title: '测算详情PDF',
                                    forceTextureOnAndroid: true,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 姓名行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _nameBar(
                '${_nameChar1 ?? ''}${_nameChar2 ?? ''}${_nameChar3 ?? ''}${_nameChar4 ?? ''}',
              ),
            ),

            // 3x4 信息行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _rows == null
                    ? []
                    : _rows!
                          .map((r) => _infoRow(r[0], r[1], r[2], r[3]))
                          .toList(),
              ),
            ),

            const SizedBox(height: 12),
            _sectionTitle('姓名评分报告'),
            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? theme.cardTheme.color : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFF222222),
                    width: 0.8,
                  ), // 外框更细
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                child: Text(
                  _nameReport ?? '',
                  textAlign: TextAlign.justify, // ✅ 两端对齐
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
            ),

            const SizedBox(height: 6),
            _sectionTitle('姓名字义解释'),
            const SizedBox(height: 6),
            // 解释表格
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _explainTable(_explainList ?? []),
            ),

            // 底部黄色按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  // ======= 小组件 =======
  Widget _circleText(String text) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFD700), // 金黄色
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ======= 三段式姓名条（左右中三个格子；外层圆角带黑色描边） =======
  Widget _nameBar(String name) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final borderColor = isDark ? Colors.white38 : Colors.black;
    final labelColor = theme.textTheme.bodyLarge?.color;
    final centerBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.black;
    final centerTextColor = isDark ? const Color(0xFFFFD54F) : Colors.white;

    return Container(
      height: 48, // 外框总高度
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(width: 2, color: borderColor),
      ),
      child: Row(
        children: [
          // 左侧"姓名"
          Container(
            width: 64,
            padding: const EdgeInsets.only(left: 15),
            // 往左贴一点
            decoration: BoxDecoration(
              color: barBgColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
            ),
            alignment: Alignment.center,
            child: Text(
              '姓名',
              style: TextStyle(fontWeight: FontWeight.w700, color: labelColor),
            ),
          ),
          // 中间黑底姓名（宽度缩短：居中 + 最大宽度限制）
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 80, // 可调：最小宽
                  maxWidth: 160, // 可调：最大宽（调小就更短）
                ),
                child: Container(
                  height: double.infinity,
                  // 与外框等高（贴上下）
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: centerBgColor,
                    borderRadius: const BorderRadius.all(Radius.circular(0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // 给文字两侧留点内边距
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // 名字太长时省略号
                    style: TextStyle(
                      color: centerTextColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 右侧按钮（把 Icon 换成图片）
          Container(
            width: 48,
            padding: const EdgeInsets.only(right: 15),
            // 往右贴一点
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: barBgColor,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            ),
            child: Container(
              // 可选：做成里面一个小圆框，更像你图上的样式
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: barBgColor,
              ),
              alignment: Alignment.centerLeft,
              child: isDark
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        -1, 0, 0, 0, 255,
                        0, -1, 0, 0, 255,
                        0, 0, -1, 0, 255,
                        0, 0, 0, 1, 0,
                      ]),
                      child: Image.asset(
                        sexImgMapper[_sex ?? ''] ?? '',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      sexImgMapper[_sex ?? ''] ?? '',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icons/star02.png', width: 18, height: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(width: 6),
        Image.asset('assets/icons/star02.png', width: 18, height: 18),
      ],
    );
  }

  Widget _infoRow(String a, String b, String c, String d) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = [a, b, c, d];
    const gap = 8.0; // 列间距
    const h = 40.0; // 行高
    const rSide = 22.0; // 两侧大圆角
    const rMid = 6.0; // 中间小圆角
    final borderColor = isDark ? Colors.white24 : const Color(0xFFE6E6E6);
    final cellBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // 行与行间距
      child: Row(
        children: List.generate(items.length, (i) {
          final isFirst = i == 0;
          final isLast = i == items.length - 1;

          return Expanded(
            child: Container(
              height: h,
              margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
              // 只给左侧留列间距
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cellBgColor,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(isFirst ? rSide : rMid),
                  right: Radius.circular(isLast ? rSide : rMid),
                ),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.4),
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ],
              ),
              child: Text(
                items[i],
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _explainTable(List<List<String>> list) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.cardTheme.color : const Color(0xFFEBEBEB);
    final outerBorder = isDark ? Colors.white24 : const Color(0xFF222222);
    final insideBorder = isDark ? Colors.white24 : const Color(0xFF222222);
    final textColor = theme.textTheme.bodyLarge?.color;
    const outerRadius = 16.0; // 圆角

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: outerBorder, width: 0.8), // 外框更细
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(0), // 外框与表格紧贴
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          // 🔑 加这一行
          columnWidths: const {0: FixedColumnWidth(72), 1: FlexColumnWidth()},
          // 只画内部的竖/横分割线，不画外框
          border: TableBorder(
            verticalInside: BorderSide(color: insideBorder, width: 0.7),
            horizontalInside: BorderSide(color: insideBorder, width: 0.7),
          ),
          children: list.map((e) {
            return TableRow(
              children: [
                // 左列（粗体，水平垂直居中）
                Container(
                  alignment: Alignment.center, // 水平+垂直居中
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    e[0],
                    style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
                  ),
                ),
                // 右列（多行说明）
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  child: Html(
                    data: _textJustify(e[1]),
                    style: {
                      "body": Style(color: textColor),
                      "div": Style(color: textColor),
                      "p": Style(color: textColor),
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _textJustify(String html) {
    html =
        '''
      <style>
        /* 🔹 段落文字左右对齐 */
        .text-justify {
          text-align: justify;
        }
        .text-justify::after {
          content: '';
          display: inline-block;
          width: 100%; /* 让最后一行也左右对齐 */
        }
      </style>
      <div class="text-justify">
        $html
      </div>
    ''';
    return HtmlUtil.appendHTML(html);
  }
}
