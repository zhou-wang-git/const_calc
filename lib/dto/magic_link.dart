class MagicLink {
  final String link;

  MagicLink({required this.link});

  factory MagicLink.fromJson(Map<String, dynamic> json) {
    return MagicLink(
      link: json['link'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
    };
  }
}
