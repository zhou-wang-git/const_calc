class TodayPerpetual {
  // 辅助方法：将动态类型转换为整数
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  final int id;
  final String date;
  final String ynian;
  final String yyue;
  final String yri;
  final String ganzhinian;
  final String ganzhiyue;
  final String ganzhiri;
  final String xingqi;
  final String yi;
  final String ji;
  final String jieri;
  final String shengxiao;
  final String xingzuo;
  final String xiangchong;
  final String jijie;
  final String nianwuxing;
  final String yuewuxing;
  final String riwuxing;
  final String xingxiu;
  final String liuyao;
  final String shiershen;
  final String rulueri;
  final String yisilan;
  final String pengzu;
  final String taishen;
  final String jieqi;
  final String jieqimsg;
  final String nyue;
  final String nri;

  TodayPerpetual({
    required this.id,
    required this.date,
    required this.ynian,
    required this.yyue,
    required this.yri,
    required this.ganzhinian,
    required this.ganzhiyue,
    required this.ganzhiri,
    required this.xingqi,
    required this.yi,
    required this.ji,
    required this.jieri,
    required this.shengxiao,
    required this.xingzuo,
    required this.xiangchong,
    required this.jijie,
    required this.nianwuxing,
    required this.yuewuxing,
    required this.riwuxing,
    required this.xingxiu,
    required this.liuyao,
    required this.shiershen,
    required this.rulueri,
    required this.yisilan,
    required this.pengzu,
    required this.taishen,
    required this.jieqi,
    required this.jieqimsg,
    required this.nyue,
    required this.nri,
  });

  factory TodayPerpetual.fromJson(Map<String, dynamic> json) {
    return TodayPerpetual(
      id: _parseInt(json['id']) ?? 0,
      date: json['date'] ?? '',
      ynian: json['ynian'] ?? '',
      yyue: json['yyue'] ?? '',
      yri: json['yri'] ?? '',
      ganzhinian: json['ganzhinian'] ?? '',
      ganzhiyue: json['ganzhiyue'] ?? '',
      ganzhiri: json['ganzhiri'] ?? '',
      xingqi: json['xingqi'] ?? '',
      yi: json['yi'] ?? '',
      ji: json['ji'] ?? '',
      jieri: json['jieri'] ?? '',
      shengxiao: json['shengxiao'] ?? '',
      xingzuo: json['xingzuo'] ?? '',
      xiangchong: json['xiangchong'] ?? '',
      jijie: json['jijie'] ?? '',
      nianwuxing: json['nianwuxing'] ?? '',
      yuewuxing: json['yuewuxing'] ?? '',
      riwuxing: json['riwuxing'] ?? '',
      xingxiu: json['xingxiu'] ?? '',
      liuyao: json['liuyao'] ?? '',
      shiershen: json['shiershen'] ?? '',
      rulueri: json['rulueri'] ?? '',
      yisilan: json['yisilan'] ?? '',
      pengzu: json['pengzu'] ?? '',
      taishen: json['taishen'] ?? '',
      jieqi: json['jieqi'] ?? '',
      jieqimsg: json['jieqimsg'] ?? '',
      nyue: json['nyue'] ?? '',
      nri: json['nri'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'ynian': ynian,
      'yyue': yyue,
      'yri': yri,
      'ganzhinian': ganzhinian,
      'ganzhiyue': ganzhiyue,
      'ganzhiri': ganzhiri,
      'xingqi': xingqi,
      'yi': yi,
      'ji': ji,
      'jieri': jieri,
      'shengxiao': shengxiao,
      'xingzuo': xingzuo,
      'xiangchong': xiangchong,
      'jijie': jijie,
      'nianwuxing': nianwuxing,
      'yuewuxing': yuewuxing,
      'riwuxing': riwuxing,
      'xingxiu': xingxiu,
      'liuyao': liuyao,
      'shiershen': shiershen,
      'rulueri': rulueri,
      'yisilan': yisilan,
      'pengzu': pengzu,
      'taishen': taishen,
      'jieqi': jieqi,
      'jieqimsg': jieqimsg,
      'nyue': nyue,
      'nri': nri,
    };
  }
}
