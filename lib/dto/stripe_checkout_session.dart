/// 模型：Stripe Checkout Session
class StripeCheckoutSession {
  final String sessionId;
  final Uri? redirectUrl; // 用 Uri，更安全
  final String publicKey;

  const StripeCheckoutSession({
    required this.sessionId,
    required this.redirectUrl,
    required this.publicKey,
  });

  /// 软解析：字段缺失/格式不对不会抛异常，给默认值或 null
  factory StripeCheckoutSession.fromJson(Map<String, dynamic> json) {
    final sid = (json['sessionId'] as String?)?.trim() ?? '';
    final pk = (json['publicKey'] as String?)?.trim() ?? '';
    final ru = (json['redirectUrl'] as String?)?.trim();

    return StripeCheckoutSession(
      sessionId: sid,
      publicKey: pk,
      redirectUrl: (ru == null || ru.isEmpty) ? null : Uri.tryParse(ru),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'redirectUrl': redirectUrl?.toString(),
    'publicKey': publicKey,
  };

}
