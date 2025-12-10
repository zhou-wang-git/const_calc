import '../pages/information/card_data.dart';

class LibraryRadical {
  final int? id;
  final String? title;
  final int? brush;
  final String? info;
  final int? addTime;

  LibraryRadical({
    this.id, this.title, this.brush, this.info, this.addTime
  });

  /// ✅ fromJson 方法
  factory LibraryRadical.fromJson(Map<String, dynamic> json) {
    return LibraryRadical(
      id: json['id'] as int?,
      title: json['title'] as String?,
      brush: json['brush'] as int?,
      info: json['info'] as String?,
      addTime: json['add_time'] as int?,
    );
  }

  /// ✅ toJson 方法
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

extension LibraryRadicalMapper on LibraryRadical {
  CardData toItem() {
    return CardData(
      id: id ?? 0,
      number: title ?? '',
      summary: info ?? '',
    );
  }
}