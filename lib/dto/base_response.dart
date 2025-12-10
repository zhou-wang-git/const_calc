class BaseResponse<T> {
  final int code;
  final String msg;
  final int? time;
  final T? data;

  bool get success => code == 1;

  BaseResponse({required this.code, required this.msg, this.time, this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return BaseResponse(
      code: json['code'] ?? 0,
      msg: (json['msg'] is String && json['msg']?.isNotEmpty == true)
          ? json['msg']
          : (json['info'] is String ? json['info'] : ''),
      time: json['time'] ?? 0,
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : null,
    );
  }
}