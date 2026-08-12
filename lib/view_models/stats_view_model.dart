import 'package:flutter/material.dart';
import 'package:workout_tracker_app/domain/models/stats.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';

import '../../data/repositories/session_repository.dart';

/// Manages stats calculations and queries.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel({required this._repository});

  final SessionRepository _repository;

  List<SessionStat> _sessionStats = [];
  List<SessionStat> get sessionStats => _sessionStats;

  WorkoutStats? _overallStats;
  WorkoutStats? get overallStats => _overallStats;

  List<WeeklyMuscleStats> _weeklyMuscleStats = [];
  List<WeeklyMuscleStats> get weeklyMuscleStats => _weeklyMuscleStats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> reloadStats() async {
    await loadStats();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sessions = await _repository.getAllSessions();
      _sessionStats = sessions.map(SessionStat.fromSession).toList();
      _overallStats = _computeOverallStats(_sessionStats);
      final result = _computeAllStats(sessions);
      _weeklyMuscleStats = result.weeklyMuscleStats;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WorkoutStats _computeOverallStats(List<SessionStat> stats) {
    return WorkoutStats(
      totalVolumeKg: stats.fold(0.0, (sum, s) => sum + s.volumeKg),
      totalSessions: stats.length,
      totalSets: stats.fold(0, (sum, s) => sum + s.totalSets),
      totalCompletedSets: stats.fold(0, (sum, s) => sum + s.completedSets),
      sessionStats: stats,
    );
  }
}

class _StatsComputeResult {
  final List<WeeklyMuscleStats> weeklyMuscleStats;
  _StatsComputeResult({required this.weeklyMuscleStats});
}

_StatsComputeResult _computeAllStats(List<WorkoutSession> sessions) {
  return _StatsComputeResult(
    weeklyMuscleStats: _computeWeeklyMuscleStats(sessions),
  );
}

List<WeeklyMuscleStats> _computeWeeklyMuscleStats(List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  final muscleData = <String, _WeeklyMuscleAccumulator>{};

  for (final session in sessions) {
    if (session.startTime.isBefore(startOfWeek)) continue;
    for (final ex in session.exercises) {
      for (final set in ex.sets) {
        if (!set.completed) continue;
        final volume = set.weightKg * set.reps;
        for (final muscle in ex.primaryMuscles) {
          if (!muscleData.containsKey(muscle)) {
            muscleData[muscle] = _WeeklyMuscleAccumulator();
          }
          muscleData[muscle]!.totalSets += 1.0;
          muscleData[muscle]!.totalVolumeKg += volume;
        }
        for (final muscle in ex.secondaryMuscles) {
          if (!muscleData.containsKey(muscle)) {
            muscleData[muscle] = _WeeklyMuscleAccumulator();
          }
          muscleData[muscle]!.totalSets += 0.5;
          muscleData[muscle]!.totalVolumeKg += volume;
        }
      }
    }
  }

  return muscleData.entries
      .map((e) => WeeklyMuscleStats(
            muscleName: e.key,
            totalSetsThisWeek: e.value.totalSets,
            totalVolumeKgThisWeek: e.value.totalVolumeKg,
          ))
      .toList()
    ..sort((a, b) => b.totalSetsThisWeek.compareTo(a.totalSetsThisWeek));
}

class _WeeklyMuscleAccumulator {
  double totalSets = 0.0;
  double totalVolumeKg = 0.0;
}
