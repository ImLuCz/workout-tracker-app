import 'package:workout_tracker_app/domain/models/workout_session.dart';

/// Statistics computed from workout sessions.
class WorkoutStats {
  final double totalVolumeKg;
  final int totalSessions;
  final int totalSets;
  final int totalCompletedSets;
  final List<SessionStat> sessionStats;

  const WorkoutStats({
    required this.totalVolumeKg,
    required this.totalSessions,
    required this.totalSets,
    required this.totalCompletedSets,
    required this.sessionStats,
  });

  double get avgVolumePerSession =>
      totalSessions == 0 ? 0 : totalVolumeKg / totalSessions;

  double get completionRate =>
      totalSets == 0 ? 0 : totalCompletedSets / totalSets;
}

class SessionStat {
  final DateTime date;
  final String routineName;
  final double volumeKg;
  final int completedSets;
  final int totalSets;
  final Duration duration;

  const SessionStat({
    required this.date,
    required this.routineName,
    required this.volumeKg,
    required this.completedSets,
    required this.totalSets,
    required this.duration,
  });

  factory SessionStat.fromSession(WorkoutSession session) {
    return SessionStat(
      date: session.startTime,
      routineName: session.routineName,
      volumeKg: session.totalVolume,
      completedSets: session.completedSets,
      totalSets: session.totalSets,
      duration: session.endTime != null
          ? session.endTime!.difference(session.startTime)
          : Duration.zero,
    );
  }
}
