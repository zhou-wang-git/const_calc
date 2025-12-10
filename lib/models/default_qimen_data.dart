import 'qimen_result.dart';

/// 默认的吉时出行查询结果
/// 日期: 1988年8月8日 09:01
class DefaultQimenData {
  /// 默认查询日期时间
  static const int defaultYear = 1988;
  static const int defaultMonth = 8;
  static const int defaultDay = 8;
  static const int defaultHour = 9;
  static const int defaultMinute = 1;

  /// 默认奇门遁甲结果
  static final QimenResult defaultQimenResult = QimenResult.fromJson({
    "luck": "凶",
    "description": "北方有人骔,乾坤道尼,屠赴牛羊去,诸凶必应之.\n前有津粝,后有豖羊,若遇此時,萬事俱歃.",
    "description_qimen": "吉时出行录\n源自于\n《奇门出行录》\n\n《奇门出行录》是一部结合奇门遁甲学术与实际应用的传统书籍或指引，主要针对人们在日常生活中的出行吉凶进行预测。奇门遁甲是一门古老的预测学，起源于中国，历史悠久，常被用于战争、决策、谋略等方面…在现代，《奇门出行录》已不仅限于出行用途，更多地被当作一种生活指南，帮助人们选择适合的时间与方向来完成各类事务，比如安全出行，\n出差或商务活动的时机选择，旅行和搬迁选择，节庆、婚嫁出行安排，避免意外或突发事件，日常生活中的短途出行等等…\n\n以上内容仅供参考，若需更详细的解答或有其他疑问，欢迎随时联系玄创小助理哦！感谢您的关注与支持！",
    "a1_taiyuan": "辛亥",
    "b1_time_shishen": "偏官",
    "b2_time_tiangan": "辛",
    "b3_time_dizhi": "巳",
    "c2_day_tiangan": "乙",
    "c3_day_dizhi": "未",
    "d1_month_shishen": "正官",
    "d2_month_tiangan": "庚",
    "d3_month_dizhi": "申",
    "e1_year_shishen": "正财",
    "e2_year_tiangan": "戊",
    "e3_year_dizhi": "辰",
    "a2": "钗钏金",
    "b2_1_zhanggan": "丙",
    "b3_1_zhanggan": "戊",
    "b4_1_zhanggan": "庚",
    "b2_2_zhanggan": "伤官",
    "b3_2_zhanggan": "正财",
    "b4_2_zhanggan": "正官",
    "c2_1_zhanggan": "己",
    "c3_1_zhanggan": "丁",
    "c4_1_zhanggan": "乙",
    "c2_2_zhanggan": "偏财",
    "c3_2_zhanggan": "食神",
    "c4_2_zhanggan": "比肩",
    "d2_1_zhanggan": "庚",
    "d3_1_zhanggan": "壬",
    "d4_1_zhanggan": "戊",
    "d2_2_zhanggan": "正官",
    "d3_2_zhanggan": "正印",
    "d4_2_zhanggan": "正财",
    "e2_1_zhanggan": "戊",
    "e3_1_zhanggan": "乙",
    "e4_1_zhanggan": "癸",
    "e2_2_zhanggan": "正财",
    "e3_2_zhanggan": "比肩",
    "e4_2_zhanggan": "偏印",
    "a3_taixi": "庚午",
    "b3_1_yun": "沐浴",
    "b3_2_nayin": "白蜡金",
    "b3_3_kongwang": "申酉",
    "c3_1_yun": "养",
    "c3_2_nayin": "沙中金",
    "c3_3_kongwang": "辰巳",
    "d3_1_yun": "胎",
    "d3_2_nayin": "石榴木",
    "d3_3_kongwang": "子丑",
    "e3_1_yun": "冠带",
    "e3_2_nayin": "大林木",
    "e3_3_kongwang": "戌亥",
    "a4_minggong": "丙辰",
    "b4_shensha": ["孤辰", "", "", "", "", "金舆贵人", "驿马", "", "", ""],
    "c4_shensha": ["", "", "", "", "", "天医", "華蓋", "", "", ""],
    "d4_shensha": ["", "", "", "", "", "天乙贵人", "红艳", "劫煞", "", "", ""],
    "e4_shensha": ["天德", "", "", "", "", ""]
  });

  /// 默认六壬结果
  static final LiurenResult defaultLiurenResult = LiurenResult.fromJson({
    "title": "赤口",
    "luck": "凶",
    "description": "赤口：代表冲突、不和，容易出现争执，适合用来提醒小心处理人际关系。"
  });
}
