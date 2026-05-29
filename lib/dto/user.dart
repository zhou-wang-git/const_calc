import 'order.dart';

class MallBinding {
  final bool isBound;
  final String kccUserId;
  final String mallEmail;
  final String mallHandle;
  final String mallDisplayName;
  final String mallClientId;
  final String mallWalletId;
  final int mallBoundAt;
  final bool hasPassword;
  final int mallPasswordUpdatedAt;
  final String preferredIdentifier;

  const MallBinding({
    this.isBound = false,
    this.kccUserId = '',
    this.mallEmail = '',
    this.mallHandle = '',
    this.mallDisplayName = '',
    this.mallClientId = 'shuyi',
    this.mallWalletId = '',
    this.mallBoundAt = 0,
    this.hasPassword = false,
    this.mallPasswordUpdatedAt = 0,
    this.preferredIdentifier = '',
  });

  factory MallBinding.fromJson(Map<String, dynamic> json) {
    final mallEmail = json['mall_email']?.toString() ?? '';
    final mallHandle = json['mall_handle']?.toString() ?? '';

    return MallBinding(
      isBound: json['is_bound'] == true || json['mall_bound'] == 1,
      kccUserId: json['kcc_user_id']?.toString() ?? '',
      mallEmail: mallEmail,
      mallHandle: mallHandle,
      mallDisplayName: json['mall_display_name']?.toString() ?? '',
      mallClientId: json['mall_client_id']?.toString() ?? 'shuyi',
      mallWalletId: json['mall_wallet_id']?.toString() ?? '',
      mallBoundAt: json['mall_bound_at'] ?? 0,
      hasPassword:
          json['has_password'] == true || json['has_mall_password'] == 1,
      mallPasswordUpdatedAt: json['mall_password_updated_at'] ?? 0,
      preferredIdentifier:
          json['preferred_identifier']?.toString() ??
          (mallEmail.isNotEmpty ? mallEmail : mallHandle),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_bound': isBound,
      'kcc_user_id': kccUserId,
      'mall_email': mallEmail,
      'mall_handle': mallHandle,
      'mall_display_name': mallDisplayName,
      'mall_client_id': mallClientId,
      'mall_wallet_id': mallWalletId,
      'mall_bound_at': mallBoundAt,
      'has_password': hasPassword,
      'mall_password_updated_at': mallPasswordUpdatedAt,
      'preferred_identifier': preferredIdentifier,
    };
  }
}

class User {
  final int id;
  final String username;
  final String? nickname;
  final String? birthTime;
  final String password;
  final String encrypt;
  final int point;
  final String amount;
  final int login;
  final String email;
  final String? mobile;
  final String avatar;
  final int groupid;
  final int modelid;
  final int vip;
  final int overduedate;
  final String? regIp;
  final int regTime;
  final String? lastLoginIp;
  final int lastLoginTime;
  final int ischeckEmail;
  final int ischeckMobile;
  final String token;
  final int status;
  final int num;
  final String year;
  final String month;
  final String day;
  final int computed;
  final String? curdate;
  final int? rid;
  final int vipLevelId;
  final String vipSubscriptionStart;
  final String vipSubscriptionEnd;
  final String vipDate;
  final int vipTime;
  final String sex;
  final String realName;
  final Order? order;
  final int twinStatus;
  final String? parentYear;
  final String? parentMonth;
  final String? parentDay;
  final MallBinding mallBinding;

  User({
    required this.id,
    required this.username,
    this.nickname,
    this.birthTime,
    required this.password,
    required this.encrypt,
    required this.point,
    required this.amount,
    required this.login,
    required this.email,
    this.mobile,
    required this.avatar,
    required this.groupid,
    required this.modelid,
    required this.vip,
    required this.overduedate,
    this.regIp,
    required this.regTime,
    this.lastLoginIp,
    required this.lastLoginTime,
    required this.ischeckEmail,
    required this.ischeckMobile,
    required this.token,
    required this.status,
    required this.num,
    required this.year,
    required this.month,
    required this.day,
    required this.computed,
    this.curdate,
    this.rid,
    required this.vipLevelId,
    required this.vipSubscriptionStart,
    required this.vipSubscriptionEnd,
    required this.vipDate,
    required this.vipTime,
    required this.sex,
    required this.realName,
    this.order,
    this.twinStatus = 0,
    this.parentYear,
    this.parentMonth,
    this.parentDay,
    this.mallBinding = const MallBinding(),
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final mallBindingJson = json['mall_binding'] is Map<String, dynamic>
        ? json['mall_binding'] as Map<String, dynamic>
        : json['mall_binding'] is Map
        ? Map<String, dynamic>.from(json['mall_binding'] as Map)
        : <String, dynamic>{
            'mall_bound': json['mall_bound'],
            'kcc_user_id': json['kcc_user_id'],
            'mall_email': json['mall_email'],
            'mall_handle': json['mall_handle'],
            'mall_display_name': json['mall_display_name'],
            'mall_client_id': json['mall_client_id'],
            'mall_wallet_id': json['mall_wallet_id'],
            'mall_bound_at': json['mall_bound_at'],
          };

    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      birthTime: json['birth_time'] ?? '',
      password: json['password'] ?? '',
      encrypt: json['encrypt'] ?? '',
      point: json['point'] ?? 0,
      amount: json['amount']?.toString() ?? '0.00',
      login: json['login'] ?? 0,
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      avatar: json['avatar'] ?? '',
      groupid: json['groupid'] ?? 0,
      modelid: json['modelid'] ?? 0,
      vip: json['vip'] ?? 0,
      overduedate: json['overduedate'] ?? 0,
      regIp: json['reg_ip'] ?? '',
      regTime: json['reg_time'] ?? 0,
      lastLoginIp: json['last_login_ip'] ?? '',
      lastLoginTime: json['last_login_time'] ?? 0,
      ischeckEmail: json['ischeck_email'] ?? 0,
      ischeckMobile: json['ischeck_mobile'] ?? 0,
      token: json['token'] ?? '',
      status: json['status'] ?? 0,
      num: json['num'] ?? 0,
      year: json['year'] ?? '',
      month: json['month'] ?? '',
      day: json['day'] ?? '',
      computed: json['computed'] ?? 0,
      curdate: json['curdate']?.toString(),
      rid: json['rid'],
      vipLevelId: json['vip_level_id'] ?? 0,
      vipSubscriptionStart: json['vip_subscription_start'] ?? '',
      vipSubscriptionEnd: json['vip_subscription_end'] ?? '',
      vipDate: json['vip_date'] ?? '',
      vipTime: json['vip_time'] ?? 0,
      sex: json['sex']?.toString() ?? '',
      realName: json['real_name'] ?? '',
      order: json['order'] != null && json['order'] is Map
          ? Order.fromJson(Map<String, dynamic>.from(json['order'] as Map))
          : null,
      twinStatus: json['twin_status'] ?? 0,
      parentYear: json['parent_year']?.toString(),
      parentMonth: json['parent_month']?.toString(),
      parentDay: json['parent_day']?.toString(),
      mallBinding: MallBinding.fromJson(mallBindingJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname ?? '',
      'birth_time': birthTime ?? '',
      'password': password,
      'encrypt': encrypt,
      'point': point,
      'amount': amount,
      'login': login,
      'email': email,
      'mobile': mobile ?? '',
      'avatar': avatar,
      'groupid': groupid,
      'modelid': modelid,
      'vip': vip,
      'overduedate': overduedate,
      'reg_ip': regIp ?? '',
      'reg_time': regTime,
      'last_login_ip': lastLoginIp ?? '',
      'last_login_time': lastLoginTime,
      'ischeck_email': ischeckEmail,
      'ischeck_mobile': ischeckMobile,
      'token': token,
      'status': status,
      'num': num,
      'year': year,
      'month': month,
      'day': day,
      'computed': computed,
      'curdate': curdate ?? '',
      'rid': rid ?? 0,
      'vip_level_id': vipLevelId,
      'vip_subscription_start': vipSubscriptionStart,
      'vip_subscription_end': vipSubscriptionEnd,
      'vip_date': vipDate,
      'vip_time': vipTime,
      'sex': sex,
      'real_name': realName,
      'order': order?.toJson(),
      'twin_status': twinStatus,
      'parent_year': parentYear ?? '',
      'parent_month': parentMonth ?? '',
      'parent_day': parentDay ?? '',
      'mall_binding': mallBinding.toJson(),
    };
  }
}
