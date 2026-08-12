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

  List<MuscleStats> _muscleStats = [];
  List<MuscleStats> get muscleStats => _muscleStats;

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
      _muscleStats = result.muscleStats;
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
  final List<MuscleStats> muscleStats;
  final List<WeeklyMuscleStats> weeklyMuscleStats;
  _StatsComputeResult({required this.muscleStats, required this.weeklyMuscleStats});
}

_StatsComputeResult _computeAllStats(List<WorkoutSession> sessions) {
  return _StatsComputeResult(
    muscleStats: _computeMuscleStats(sessions),
    weeklyMuscleStats: _computeWeeklyMuscleStats(sessions),
  );
}

List<MuscleStats> _computeMuscleStats(List<WorkoutSession> sessions) {
  final muscleData = <String, _MuscleAccumulator>{};

  for (final session in sessions) {
    for (final ex in session.exercises) {
      final allMuscles = [
        ...ex.primaryMuscles,
        ...ex.secondaryMuscles,
      ];
      for (final muscle in allMuscles) {
        if (!muscleData.containsKey(muscle)) {
          muscleData[muscle] = _MuscleAccumulator();
        }
        final acc = muscleData[muscle]!;
        acc.totalWorkouts++;
        for (final set in ex.sets) {
          if (set.completed) {
            acc.completedSets++;
            acc.totalVolumeKg += set.weightKg * set.reps;
            if (set.weightKg > acc.heaviestWeightKg) {
              acc.heaviestWeightKg = set.weightKg;
            }
          }
        }
      }
    }
  }

  return muscleData.entries
      .map((e) => MuscleStats(
            muscleName: e.key,
            totalWorkouts: e.value.totalWorkouts,
            completedSets: e.value.completedSets,
            totalVolumeKg: e.value.totalVolumeKg,
            heaviestWeightKg: e.value.heaviestWeightKg,
          ))
      .toList()
    ..sort((a, b) => b.totalVolumeKg.compareTo(a.totalVolumeKg));
}

List<WeeklyMuscleStats> _computeWeeklyMuscleStats(List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  final muscleData = <String, _WeeklyMuscleAccumulator>{};

  for (final session in sessions) {
    if (session.startTime.isBefore(startOfWeek)) continue;
    for (final ex in session.exercises) {
      final allMuscles = [...ex.primaryMuscles, ...ex.secondaryMuscles];
      for (final muscle in allMuscles) {
        if (!muscleData.containsKey(muscle)) {
          muscleData[muscle] = _WeeklyMuscleAccumulator();
        }
        final acc = muscleData[muscle]!;
        for (final set in ex.sets) {
          if (set.completed) {
            acc.totalSets++;
            acc.totalVolumeKg += set.weightKg * set.reps;
          }
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

class _MuscleAccumulator {
  int totalWorkouts = 0;
  int completedSets = 0;
  double totalVolumeKg = 0.0;
  double heaviestWeightKg = 0.0;
}

class _WeeklyMuscleAccumulator {
  int totalSets = 0;
  double totalVolumeKg = 0.0;
}
