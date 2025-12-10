// 非 Web 默认用 IO 实现；在 Web 上切到 web 实现
export 'stripe_payment_service_io.dart'
if (dart.library.html) 'stripe_payment_service_web.dart';
