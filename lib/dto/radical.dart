class Radical {
  final int id;
  final String title;
  final int brush;
  final String info;
  final int addTime;

  Radical({
    required this.id,
    required this.title,
    required this.brush,
    required this.info,
    required this.addTime,
  });

  factory Radical.fromJson(Map<String, dynamic> json) {
    return Radical(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString().trim(),
      brush: json['brush'] ?? 0,
      info: (json['info'] ?? '').toString(),
      addTime: json['add_time'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'brush': brush,
      'info': info,
      'add_time': addTime,
    };
  }
}
