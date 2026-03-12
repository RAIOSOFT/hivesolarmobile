class SolarAmcModel {
  final int expiringSoon;
  final int activeAmcs;
  final int expired;
  final int amcDatabase;

  SolarAmcModel({
    required this.expiringSoon,
    required this.activeAmcs,
    required this.expired,
    required this.amcDatabase,
  });

  factory SolarAmcModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>;
    return SolarAmcModel(
      expiringSoon: s['expiring'] ?? 0,
      activeAmcs: s['active'] ?? 0,
      expired: s['expired'] ?? 0,
      amcDatabase: s['amcDatabase'] ?? 0,
    );
  }
}
