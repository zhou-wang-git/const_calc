class Wuxing {
  final int p1;
  final int p2;
  final int p3;
  final int p4;
  final int p5;
  final int p6;
  final int p7;
  final int p8;
  final int mainNumber;
  final int secondaryNumber;
  final int left1;
  final int left2;
  final int left3;
  final int right1;
  final int right2;
  final int right3;

  Wuxing({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.p4,
    required this.p5,
    required this.p6,
    required this.p7,
    required this.p8,
    required this.mainNumber,
    required this.secondaryNumber,
    required this.left1,
    required this.left2,
    required this.left3,
    required this.right1,
    required this.right2,
    required this.right3,
  });

  factory Wuxing.fromJson(Map<String, dynamic> json) {
    return Wuxing(
      p1: json['p1'] ?? 0,
      p2: json['p2'] ?? 0,
      p3: json['p3'] ?? 0,
      p4: json['p4'] ?? 0,
      p5: json['p5'] ?? 0,
      p6: json['p6'] ?? 0,
      p7: json['p7'] ?? 0,
      p8: json['p8'] ?? 0,
      mainNumber: json['main_number'] ?? 0,
      secondaryNumber: json['secondary_number'] ?? 0,
      left1: json['left1'] ?? 0,
      left2: json['left2'] ?? 0,
      left3: json['left3'] ?? 0,
      right1: json['right1'] ?? 0,
      right2: json['right2'] ?? 0,
      right3: json['right3'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'p1': p1,
    'p2': p2,
    'p3': p3,
    'p4': p4,
    'p5': p5,
    'p6': p6,
    'p7': p7,
    'p8': p8,
    'main_number': mainNumber,
    'secondary_number': secondaryNumber,
    'left1': left1,
    'left2': left2,
    'left3': left3,
    'right1': right1,
    'right2': right2,
    'right3': right3,
  };
}
