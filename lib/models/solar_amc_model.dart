class SolarAmcModel {
  final int expiringSoon;
  final int activeAmcs;
  final int expired;
  final int amcDatabase;
  final int inprogress;
  final int notInterested;
  final int completed;
  final int archived;

  const SolarAmcModel({
    required this.expiringSoon,
    required this.activeAmcs,
    required this.expired,
    required this.amcDatabase,
    required this.inprogress,
    required this.notInterested,
    required this.completed,
    required this.archived,
  });

  factory SolarAmcModel.fromJson(Map<String, dynamic> json) {
    final s = (json['summary'] as Map<String, dynamic>?) ?? {};
    return SolarAmcModel(
      expiringSoon: (s['expiring'] as num?)?.toInt() ?? 0,
      activeAmcs: (s['active'] as num?)?.toInt() ?? 0,
      expired: (s['expired'] as num?)?.toInt() ?? 0,
      amcDatabase: (s['amcDatabase'] as num?)?.toInt() ?? 0,
      inprogress: (s['inprogress'] as num?)?.toInt() ?? 0,
      notInterested: (s['notinterested'] as num?)?.toInt() ?? 0,
      completed: (s['completed'] as num?)?.toInt() ?? 0,
      archived: (s['isarchive'] as num?)?.toInt() ?? 0,
    );
  }
}
