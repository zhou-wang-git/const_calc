import 'package:flutter/material.dart';

/// iOS PWA 安装引导对话框
class IosInstallGuideDialog extends StatelessWidget {
  const IosInstallGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F7EC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 标题
                const Text(
                  '添加"数字赋能"到桌面',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 40),

                // 主引导图
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.075),
                  child: Image.asset(
                    'assets/images/guide/ts.png',
                    width: screenWidth * 0.85,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                const SizedBox(height: 40),

                // 第一步
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.075),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '第一步',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFC9A45),
                            ),
                          ),
                          Text(
                            '：点击底部工具',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/guide/ts2.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 第二步
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.075),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第二步：在弹出框中点击"添加到主屏幕"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/guide/ts3.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 关闭按钮
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: screenWidth * 0.7,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBD08),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '我知道了',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
