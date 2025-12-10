import 'package:flutter/material.dart';

class LuckHeaderData {
  String? mainWx; // 主性格号
  String? luckDateStr; // 日期
  String? luckWeekStr; // 星期
  String? realName; // 姓名
  String? sex; // 性别
  String? birthday; // 出生日期
  String? userStar; // 星座
  String? userSx; // 生肖
  String? birthTime; // 出生时间

  LuckHeaderData({
    this.mainWx,
    this.luckDateStr,
    this.luckWeekStr,
    this.realName,
    this.sex,
    this.birthday,
    this.userStar,
    this.userSx,
    this.birthTime,
  });

}

class LuckHeaderCard extends StatelessWidget {
  final LuckHeaderData? data; // ✅ 数据对象可空

  const LuckHeaderCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;

    final screenWidth = MediaQuery.of(context).size.width;
    final double aspectRatio = 0.95; // 可调比例
    final double cardHeight = screenWidth * aspectRatio;

    // ✅ 动态尺寸
    final double imageSize = screenWidth * 0.26; // 主性格图片占 26%
    final double fontSize = screenWidth * 0.045; // 动态字体大小
    final double smallFont = screenWidth * 0.035;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// ✅ 背景图
              Positioned(
                top: screenWidth * 0.15,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/icons/myFortunebg-night.png',
                  width: double.infinity,
                  height: screenWidth * 0.75,
                  fit: BoxFit.cover,
                ),
              ),

              /// ✅ 顶部：主性格号 + 日期
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${data?.mainWx ?? ''}号人',
                          style: TextStyle(
                            fontSize: smallFont,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data?.luckDateStr ?? ''} ${data?.luckWeekStr ?? ''}',
                        style: TextStyle(fontSize: smallFont, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),

              /// ✅ 中间内容
              Positioned.fill(
                top: screenWidth * 0.22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (data?.mainWx != null)
                      Positioned(
                        top: screenWidth * 0.175,
                        child: Image.asset('assets/icons/9g/rg${data!.mainWx!}.png', width: imageSize),
                      ),

                    /// 左侧三项
                    Positioned(
                      left: screenWidth * 0.13,
                      top: screenWidth * 0.06,
                      child: _buildText(data?.realName, fontSize, textColor),
                    ),
                    Positioned(
                      left: screenWidth * 0.08,
                      top: screenWidth * 0.26,
                      child: _buildText(data?.sex, fontSize, textColor),
                    ),
                    Positioned(
                      left: screenWidth * 0.10,
                      top: screenWidth * 0.47,
                      child: _buildText(data?.birthday, fontSize, textColor),
                    ),

                    /// 右侧三项
                    Positioned(
                      right: screenWidth * 0.15,
                      top: screenWidth * 0.06,
                      child: _buildText(data?.userStar, fontSize, textColor),
                    ),
                    Positioned(
                      right: screenWidth * 0.08,
                      top: screenWidth * 0.26,
                      child: _buildText(data?.userSx, fontSize, textColor),
                    ),
                    Positioned(
                      right: screenWidth * 0.10,
                      top: screenWidth * 0.47,
                      child: _buildText(data?.birthTime, fontSize, textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildText(String? text, double size, Color color) {
    return Text(
      text ?? '',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
