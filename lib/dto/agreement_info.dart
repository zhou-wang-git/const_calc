class AgreementInfo {
  final String title;
  final String content;
  final String time;

  AgreementInfo({
    required this.title,
    required this.content,
    required this.time,
  });

  factory AgreementInfo.fromJson(Map<String, dynamic>? json) {
    return AgreementInfo(
      title: json?['title']?.toString() ?? '',
      content: json?['content']?.toString() ?? '',
      time: json?['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'time': time,
    };
  }
}
