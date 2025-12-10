class Tag {
  final String name;
  final int value;
  final bool selected;

  Tag({
    required this.name,
    required this.value,
    required this.selected,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String,
      value: json['value'] as int,
      selected: json['selected'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'selected': selected,
    };
  }
}
