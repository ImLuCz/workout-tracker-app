import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';

import '../../data/repositories/session_repository.dart';

/// Manages active workout sessions with set logging and rest timers.
class WorkoutViewModel extends ChangeNotifier {
  WorkoutViewModel({required SessionRepository repository}) : _repository = repository;

  final SessionRepository _repository;
  final _uuid = const Uuid();

  WorkoutSession? _session;
  WorkoutSession? get session => _session;

  bool _isFinished = false;
  bool get isFinished => _isFinished;

  // Rest timer state
  int _restSeconds = 0;
  int get restSeconds => _restSeconds;
  bool _restTimerRunning = false;
  bool get restTimerRunning => _restTimerRunning;
  Timer? _timer;

  String _restTarget = '90'; // seconds
  String get restTarget => _restTarget;

  void setRestTarget(String value) {
    _restTarget = value;
    notifyListeners();
  }

  void startSetRest() {
    if (_restTimerRunning) return;
    _restSeconds = int.tryParse(_restTarget) ?? 90;
    _restTimerRunning = true;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void cancelRest() {
    _restTimerRunning = false;
    _restSeconds = 0;
    _timer?.cancel();
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_restSeconds <= 1) {
      cancelRest();
      notifyListeners();
      return;
    }
    _restSeconds--;
    notifyListeners();
  }

  /// Creates a new session from a routine.
  WorkoutSession createSession(WorkoutRoutine routine) {
    final exercises = routine.exercises.map((re) {
      return SessionExercise(
        routineExercise: re,
        sets: _defaultSetsForExercise(re.exercise),
      );
    }).toList();

    _session = WorkoutSession(
      id: _uuid.v4(),
      routineId: routine.id,
      routineName: routine.name,
      startTime: DateTime.now(),
      exercises: exercises,
    );
    notifyListeners();
    return _session!;
  }

  List<WorkoutSet> _defaultSetsForExercise(Exercise exercise) {
    // Provide 3 default sets for most exercises
    return List.generate(3, (i) => WorkoutSet(
      id: _uuid.v4(),
      weightKg: 0.0,
      reps: 0,
      completed: false,
    ));
  }

  /// Logs a set as completed and auto-starts rest timer.
  void completeSet(int exerciseIndex, int setIndex) {
    if (_session == null) return;
    final exercise = _session!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    if (set.completed) return;

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = set.copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );

    _session = _session!.copyWith(
      exercises: List<SessionExercise>.generate(
        _session!.exercises.length,
        (i) => i == exerciseIndex
            ? exercise.copyWith(sets: updatedSets)
            : _session!.exercises[i],
      ),
    );
    notifyListeners();
    startSetRest();
  }

  void updateSetWeight(int exerciseIndex, int setIndex, double weight) {
    if (_session == null) return;
    final exercise = _session!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = set.copyWith(weightKg: weight);
    _session = _session!.copyWith(
      exercises: List<SessionExercise>.generate(
        _session!.exercises.length,
        (i) => i == exerciseIndex
            ? exercise.copyWith(sets: updatedSets)
            : _session!.exercises[i],
      ),
    );
    notifyListeners();
  }

  void updateSetReps(int exerciseIndex, int setIndex, int reps) {
    if (_session == null) return;
    final exercise = _session!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = set.copyWith(reps: reps);
    _session = _session!.copyWith(
      exercises: List<SessionExercise>.generate(
        _session!.exercises.length,
        (i) => i == exerciseIndex
            ? exercise.copyWith(sets: updatedSets)
            : _session!.exercises[i],
      ),
    );
    notifyListeners();
  }

  void finishSession() {
    if (_session == null || _session!.isFinished) return;
    _timer?.cancel();
    _restTimerRunning = false;
    _session = _session!.copyWith(endTime: DateTime.now());
    _isFinished = true;
    notifyListeners();
  }

  Future<void> saveSession() async {
    if (_session == null) return;
    await _repository.saveSession(_session!);
  }

  double estimate1RM(double weightKg, int reps) {
    if (reps <= 0) return 0;
    // Epley formula
    return weightKg * (1 + reps / 30.0);
  }

  Duration get sessionDuration {
    if (_session == null) return Duration.zero;
    final end = _session!.endTime ?? DateTime.now();
    return end.difference(_session!.startTime);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
