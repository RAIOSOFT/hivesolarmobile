class SupportStatsModel {
  final int newTickets;
  final int delayed;
  final int completed;
  final int archived;
  final int total;

  const SupportStatsModel({
    required this.newTickets,
    required this.delayed,
    required this.completed,
    required this.archived,
    required this.total,
  });

  factory SupportStatsModel.fromRecords(List<Map<String, dynamic>> records) {
    int newCount = 0;
    int delayedCount = 0;
    int completedCount = 0;
    int archivedCount = 0;

    for (final r in records) {
      final isArchive = r['isarchive'] == true;
      final status = (r['status'] ?? '').toString().toLowerCase();

      if (isArchive) archivedCount++;

      switch (status) {
        case 'new':
          newCount++;
          break;
        case 'delayed':
          delayedCount++;
          break;
        case 'completed':
          if (!isArchive) completedCount++;
          break;
      }
    }

    return SupportStatsModel(
      newTickets: newCount,
      delayed: delayedCount,
      completed: completedCount,
      archived: archivedCount,
      total: records.length,
    );
  }

  @override
  String toString() =>
      'SupportStatsModel(new: $newTickets, delayed: $delayed, '
      'completed: $completed, archived: $archived, total: $total)';
}
