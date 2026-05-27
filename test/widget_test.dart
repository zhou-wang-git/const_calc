import 'package:const_calc/dto/Tutor.dart';
import 'package:const_calc/pages/home/tutor_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tutor detail page renders core content',
      (WidgetTester tester) async {
    final tutor = Tutor(
      id: 1,
      email: 'mentor@example.com',
      mobile: '13800138000',
      avatar: '',
      status: 1,
      chineseName: '郭俯宏',
      englishName: 'Guo Fuhong',
      levelName: '资深导师',
      experienceYears: 10,
      location: '上海',
      country: '中国',
      background: '这里是导师介绍内容。',
      sex: 2,
      recommendStatus: 1,
      hourlyConsultationFee: '299',
      addTime: 0,
      wx: 'mentor-wechat',
      wa: '',
      website: '',
      contactPriority: 'email,wx,mobile',
      waTemplate: '',
      line: '',
      tagIds: '1,2',
      tagNames: '事业规划,人生咨询',
      level: 1,
      gradeId: 1,
      contactNum: 9,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 750),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFC107),
                primary: const Color(0xFFFFC107),
                surface: Colors.white,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF3F3F3),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
                bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            home: TutorDetailPage(tutor: tutor),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    final exception = tester.takeException();

    expect(find.text('导师详情'), findsOneWidget);
    expect(find.text('郭俯宏'), findsOneWidget);
    expect(find.text('服务领域：'), findsOneWidget);
    expect(find.text('认证导师'), findsOneWidget);
    expect(find.text('个人介绍'), findsOneWidget);
    expect(find.text('预约'), findsOneWidget);
    expect(exception, isNull);
  });
}
