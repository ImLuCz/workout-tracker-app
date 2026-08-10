import 'package:flutter/material.dart';
import 'package:workout_tracker_app/domain/models/stats.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';

import '../../data/repositories/session_repository.dart';

/// Manages stats calculations and queries.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel({required SessionRepository repository})
      : _repository = repository;

  final SessionRepository _repository;

  List<SessionStat> _sessionStats = [];
  List<SessionStat> get sessionStats => _sessionStats;

  WorkoutStats? _overallStats;
  WorkoutStats? get overallStats => _overallStats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sessions = await _repository.getAllSessions();
      _sessionStats = sessions.map(SessionStat.fromSession).toList();
      _overallStats = _computeOverallStats(_sessionStats);
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
