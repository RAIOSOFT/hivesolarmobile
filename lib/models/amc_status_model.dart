class AmcStatusModel {
  final int active;
  final int expiring;
  final int expired;
  // final int completed;
  final int visited;
  final int database;

  AmcStatusModel({
    required this.active,
    required this.expiring,
    required this.expired,
    // required this.completed,
    required this.visited,
    required this.database,
  });

  factory AmcStatusModel.fromJson(Map<String, dynamic> json) {
    final summary = json["summary"];

    return AmcStatusModel(
      active: summary["active"] ?? 0,
      expiring: summary["expiring"] ?? 0,
      expired: summary["expired"] ?? 0,
      // completed: summary["completed"] ?? 0,
      visited: summary["visited"] ?? 0,
      database: summary["database"] ?? 0,
    );
  }
}
