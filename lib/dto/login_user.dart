class LoginUser {
  final int userid;
  final String username;
  final String avatar;
  final String token;
  final int num;
  final String birthTime;

  LoginUser({
    required this.userid,
    required this.username,
    required this.avatar,
    required this.token,
    required this.num,
    required this.birthTime,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      userid: json['userid'] ?? 0,
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      num: json['num'] ?? 0,
      birthTime: json['birth_time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'username': username,
      'avatar': avatar,
      'token': token,
      'num': num,
      'birth_time': birthTime,
    };
  }
}
