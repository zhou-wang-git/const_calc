class DigitCalculationSum {
  final String sum;
  final int count;

  DigitCalculationSum({required this.sum, required this.count});

  factory DigitCalculationSum.fromJson(Map<String, dynamic> json) {
    return DigitCalculationSum(
      sum: json['sum'] ?? '',
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'sum': sum,
    'count': count,
  };
}