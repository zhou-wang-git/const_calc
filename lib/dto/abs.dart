class Abs {
  final int id;
  final int position;
  final String imageUrl;
  final String? url;
  final int vipShow;
  final String title;
  final int status;
  final int addTime;

  Abs({
    required this.id,
    required this.position,
    required this.imageUrl,
    this.url,
    required this.vipShow,
    required this.title,
    required this.status,
    required this.addTime,
  });

  factory Abs.fromJson(Map<String, dynamic> json) {
    return Abs(
      id: json['id'] as int,
      position: json['position'] as int,
      imageUrl: json['image_url'] as String,
      url: json['url'] as String?,
      vipShow: json['vip_show'] as int,
      title: json['title'] as String,
      status: json['status'] as int,
      addTime: json['add_time'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'image_url': imageUrl,
      'url': url,
      'vip_show': vipShow,
      'title': title,
      'status': status,
      'add_time': addTime,
    };
  }
}
