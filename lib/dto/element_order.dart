class ElementOrder {
  final String name;
  final int val;

  ElementOrder({required this.name, required this.val});

  factory ElementOrder.fromJson(Map<String, dynamic> json) {
    return ElementOrder(
      name: json['name'] ?? '',
      val: json['val'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'val': val,
  };
}
