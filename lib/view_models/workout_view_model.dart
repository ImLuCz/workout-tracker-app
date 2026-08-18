import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker_app/constants/rest.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';

import '../../data/repositories/custom_exercise_repository.dart';
import '../../data/repositories/session_repository.dart';

/// Stores the last-known weight and reps for a single set index.
class SetDefaults {
  final double weightKg;
  final int reps;

  const SetDefaults({required this.weightKg, required this.reps});
}

/// Manages active workout sessions with set logging and rest timers.
class WorkoutViewModel extends ChangeNotifier {
  WorkoutViewModel({
    required this._repository,
    this._customExerciseRepository,
  });

  final SessionRepository _repository;
  final CustomExerciseRepository? _customExerciseRepository;
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

  void startSetRest({int customSeconds = 0}) {
    if (_restTimerRunning) return;
    _restSeconds = customSeconds > 0 ? customSeconds : (int.tryParse(_restTarget) ?? defaultRestSeconds);
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

  /// Temporarily adjusts the current rest timer by [delta] seconds.
  /// This is not permanent — the next rest period resets to the exercise default.
  void adjustRestSeconds(int delta) {
    _restSeconds = (_restSeconds + delta).clamp(0, maxRestSeconds);
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

  /// Creates a new session from a routine, optionally carrying forward weights and reps
  /// from the most recent completed session for the same routine.
  Future<WorkoutSession> createSession(
    WorkoutRoutine routine, {
    Map<String, Map<int, SetDefaults>>? previousSetDefaults,
  }) async {
    final exerciseFutures = routine.exercises.map((re) async {
      List<String> primaryMuscles = [];
      List<String> secondaryMuscles = [];

      if (re.exercise.category == 'Custom' && _customExerciseRepository != null) {
        final customEx = _customExerciseRepository.getExercise(re.exercise.id);
        if (customEx != null) {
          primaryMuscles = customEx.primaryMuscles;
          secondaryMuscles = customEx.secondaryMuscles;
        }
      } else if (re.exercise.target != null && re.exercise.target!.isNotEmpty) {
        primaryMuscles = [re.exercise.target!];
        secondaryMuscles = re.exercise.secondaryMuscles ?? [];
      } else if (re.exercise.category.isNotEmpty) {
        primaryMuscles = [re.exercise.category];
      }

      final setDefaults = previousSetDefaults?[re.exercise.id];

      return SessionExercise(
        routineExercise: re,
        sets: _defaultSetsForExercise(re, setDefaults: setDefaults),
        restSeconds: re.restSeconds,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
      );
    });

    final sessionExercises = await Future.wait(exerciseFutures);

    _session = WorkoutSession(
      id: _uuid.v4(),
      routineId: routine.id,
      routineName: routine.name,
      startTime: DateTime.now(),
      exercises: sessionExercises,
    );
    notifyListeners();
    return _session!;
  }

  /// Builds the initial sets for an exercise, carrying forward weights/reps from a previous session.
  List<WorkoutSet> _defaultSetsForExercise(
    RoutineExercise routineExercise, {
    Map<int, SetDefaults>? setDefaults,
  }) {
    return List.generate(routineExercise.setsCount, (i) {
      final defaults = setDefaults?[i];
      return WorkoutSet(
        id: _uuid.v4(),
        weightKg: defaults?.weightKg ?? 0.0,
        reps: defaults?.reps ?? 0,
        completed: false,
      );
    });
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
    startSetRest(customSeconds: exercise.restSeconds);
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

  void discardSession() {
    _timer?.cancel();
    _restTimerRunning = false;
    _restSeconds = 0;
    _session = null;
    _isFinished = false;
    notifyListeners();
  }

  Future<void> saveSession() async {
    if (_session == null) return;
    await _repository.saveSession(_session!);
    _session = null;
    _isFinished = false;
    notifyListeners();
  }

  /// Estimates one-rep max using the Epley formula:
  ///   1RM = weight × (1 + reps / 30)
  /// Valid for reps in the range 1–10; accuracy decreases beyond that.
  double estimate1RM(double weightKg, int reps) {
    if (reps <= 0) return 0;
    return weightKg * (1 + reps / 30.0);
  }

  Duration get sessionDuration {
    if (_session == null) return Duration.zero;
    final end = _session!.endTime ?? DateTime.now();
    return end.difference(_session!.startTime);
  }

  bool get hasActiveWorkout => _session != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
