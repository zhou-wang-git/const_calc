class NameValPair {
  final String name;
  final dynamic val; // val 可能为 int 或 string

  NameValPair({required this.name, required this.val});

  factory NameValPair.fromJson(Map<String, dynamic> json) {
    return NameValPair(
      name: json['name'] ?? '',
      val: json['val'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'val': val,
  };
}