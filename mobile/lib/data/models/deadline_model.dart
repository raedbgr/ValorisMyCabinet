enum DeadlineStatus { upcoming, urgent, late, complete }

class DeadlineModel {
  final String id;
  final String code;
  final String title;
  final String period;
  final DateTime dueDate;
  final DeadlineStatus status;
  final int missingDocs;
  final List<String> requiredDocTypes;

  const DeadlineModel({
    required this.id,
    required this.code,
    required this.title,
    required this.period,
    required this.dueDate,
    required this.status,
    this.missingDocs = 0,
    this.requiredDocTypes = const [],
  });

  String get statusLabel {
    switch (status) {
      case DeadlineStatus.upcoming:
        return 'À venir';
      case DeadlineStatus.urgent:
        return 'Urgent';
      case DeadlineStatus.late:
        return 'En retard';
      case DeadlineStatus.complete:
        return 'Déposée';
    }
  }

  String relativeDate(DateTime now) {
    final diff = dueDate.difference(now);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      return 'il y a $days jour${days > 1 ? 's' : ''}';
    }
    final days = diff.inDays;
    if (days == 0) return "aujourd'hui";
    if (days == 1) return 'demain';
    return 'dans $days jours';
  }
}
