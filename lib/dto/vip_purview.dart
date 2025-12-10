class VipPurview {
  final int id;
  final String purviewName;
  final String purviewNotes;
  final String baseVipKey;
  final int baseVipValue;
  final String elitistVipKey;
  final int elitistVipValue;
  final String supremeVipKey;
  final int supremeVipValue;
  final int isDefault;
  final int addTime;

  VipPurview({
    required this.id,
    required this.purviewName,
    required this.purviewNotes,
    required this.baseVipKey,
    required this.baseVipValue,
    required this.elitistVipKey,
    required this.elitistVipValue,
    required this.supremeVipKey,
    required this.supremeVipValue,
    required this.isDefault,
    required this.addTime,
  });

  factory VipPurview.fromJson(Map<String, dynamic> json) {
    return VipPurview(
      id: json['id'] ?? 0,
      purviewName: json['purview_name'] ?? '',
      purviewNotes: json['purview_notes'] ?? '',
      baseVipKey: json['base_vip_key'] ?? '',
      baseVipValue: json['base_vip_value'] ?? 0,
      elitistVipKey: json['elitist_vip_key'] ?? '',
      elitistVipValue: json['elitist_vip_value'] ?? 0,
      supremeVipKey: json['supreme_vip_key'] ?? '',
      supremeVipValue: json['supreme_vip_value'] ?? 0,
      isDefault: json['is_default'] ?? 0,
      addTime: json['add_time'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purview_name': purviewName,
      'purview_notes': purviewNotes,
      'base_vip_key': baseVipKey,
      'base_vip_value': baseVipValue,
      'elitist_vip_key': elitistVipKey,
      'elitist_vip_value': elitistVipValue,
      'supreme_vip_key': supremeVipKey,
      'supreme_vip_value': supremeVipValue,
      'is_default': isDefault,
      'add_time': addTime,
    };
  }
}
