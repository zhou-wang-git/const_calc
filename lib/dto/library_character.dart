import '../pages/information/card_data.dart';

class LibraryCharacter {
  final int? id;
  final String? title;
  final String? content;
  final int? time;

  LibraryCharacter({
    this.id, this.title, this.content, this.time
  });

  /// ✅ fromJson 方法
  factory LibraryCharacter.fromJson(Map<String, dynamic> json) {
    return LibraryCharacter(
      id: json['id'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      time: json['time'] as int?,
    );
  }

  /// ✅ toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'time': time,
    };
  }
}

extension LibraryCharacterMapper on LibraryCharacter {
  CardData toItem() {
    return CardData(
      id: id ?? 0,
      number: title ?? '',
      summary: content ?? '',
    );
  }
}