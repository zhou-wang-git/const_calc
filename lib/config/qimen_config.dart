/// 奇门遁甲 API 配置
class QimenConfig {
  /// API 基础 URL
  static const String baseUrl =
      'https://www.mielife.com.my/_adminCP/jiepan/api_qimenchuxingru.php';

  /// API Key
  static const String apiKey = 'mielife20250826';

  /// API Token
  static const String apiToken = 'YreTJhjvhj87567rfgjkbvdssd23vs';

  /// 免费用户每日查询限制
  static const int freeUserDailyLimit = 10;

  /// API 请求超时时间（秒）
  static const int timeoutSeconds = 30;
}
