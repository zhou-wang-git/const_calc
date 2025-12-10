import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LuckChartData {
  String date = '';
  String month = '';
  String century = '';
  String decade = '';
  String center = '';
  String topCircle = '';
  String bottomCircle = '';
  String leftCircle = '';
  String rightCircle = '';
  List<String> squares = ['', '', '', '']; // [左上, 右上, 左下, 右下]
  List<String> triangleNumbers = ['', '', '', '']; // [左1, 左2, 右1, 右2]
  List<String> bottomLeft = ['', '', ''];
  List<String> bottomRight = ['', '', ''];
  List<String> fiveElements = ['', '', '', '', '']; // 五行数字 [火, 土, 金, 水, 木]
  List<String> fiveElementsName = ['', '', '', '', '']; // 五行数字 [火, 土, 金, 水, 木]

  LuckChartData({
    required this.date,
    required this.month,
    required this.century,
    required this.decade,
    required this.center,
    required this.topCircle,
    required this.bottomCircle,
    required this.leftCircle,
    required this.rightCircle,
    required this.squares,
    required this.triangleNumbers,
    required this.bottomLeft,
    required this.bottomRight,
    required this.fiveElements,
  });
}

class LuckChartWidget extends StatelessWidget {
  final LuckChartData data;
  static const double originalWidth = 690;
  static const double originalHeight = 715;

  const LuckChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: 330.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(width: 22.w),
              Text('日期', style: TextStyle(fontSize: 15.sp, color: textColor)),
              SizedBox(width: 6.w),
              Text('月份', style: TextStyle(fontSize: 15.sp, color: textColor)),
              SizedBox(width: 151.w),
              Text('世纪', style: TextStyle(fontSize: 15.sp, color: textColor)),
              SizedBox(width: 5.w),
              Text('年代', style: TextStyle(fontSize: 15.sp, color: textColor)),
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

                  _buildText(115, 50, data.date, TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(252, 50, data.month, TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(1000, 50, data.century, TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(1135, 50, data.decade, TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),

                  _buildText(625, 20, data.topCircle, TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(625,  680, data.center, TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(625, 1280, data.bottomCircle, TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(55, 675, data.leftCircle, TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(1195, 675, data.rightCircle, TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor)),

                  _buildText(480, 511, data.squares[0], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(780, 511, data.squares[1], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(480, 820, data.squares[2], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(780, 820, data.squares[3], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),

                  _buildText(290, 270, data.triangleNumbers[0], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(525, 270, data.triangleNumbers[1], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(725, 270, data.triangleNumbers[2], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(950, 270, data.triangleNumbers[3], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),

                  _buildText(130, 1255, data.bottomLeft[0], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(265, 1255, data.bottomLeft[1], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(395, 1255, data.bottomLeft[2], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(850, 1255, data.bottomRight[0], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(985, 1255, data.bottomRight[1], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                  _buildText(1125, 1255, data.bottomRight[2], TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(double x, double y, String text, TextStyle style) {
    return Align(
      alignment: FractionalOffset(x / 1252, y / 1300),
      child: Text(text, style: style),
    );
  }

}

class LuckDetailScreenTab extends StatelessWidget {
  final LuckChartData data;

  const LuckDetailScreenTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 五行标题
    final descriptions = ['自身性格', '子女财富', '事业伴侣', '官鬼疾病', '父母贵人'];
    final icons = [
      'assets/icons/wuxing_shui-nigtht.png',
      'assets/icons/wuxing_mu-nigtht.png',
      'assets/icons/wuxing_huo-nigtht.png',
      'assets/icons/wuxing_tu-nigtht.png',
      'assets/icons/wuxing_jin-nigtht.png',
    ];

    return SingleChildScrollView(
      child: Column(
          children: [
            LuckChartWidget(data: data),

            const SizedBox(height: 30),

            // ✅ 五个块并排
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图标
                    Image.asset(
                      icons[index],
                      width: screenWidth * 0.14, // 按比例缩放
                    ),
                    const SizedBox(height: 6),

                    // 数字
                    Text(
                      data.fiveElements[index],
                      style: TextStyle(
                        fontSize: screenWidth * 0.045, // 自适应字体
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 描述
                    Text(
                      descriptions[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03, // 自适应字体
                      ),
                    ),
                  ],
                ),
              );
            }),
            ),

            const SizedBox(height: 20),
          ],
      ),
    );
  }
}
