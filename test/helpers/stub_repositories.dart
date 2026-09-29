// In-memory repositories shared by every test in this package.
//
// Each stub extends the real repository (rather than `implements` it) and
// overrides every method that would otherwise read from or write to a
// `HiveService` box, so no test ever needs `Hive.initFlutter()` on a real
// filesystem. Methods that never touch Hive are left inherited.
//
// No mocking library is used — see the `flutter-testing` project skill.

import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/data/repositories/session_repository.dart';
import 'package:workout_tracker_app/domain/models/custom_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';

/// Stub repository that extends the real one and overrides methods.
class StubRoutineRepository extends RoutineRepository {
  final List<WorkoutRoutine> _routines = [];
  WorkoutRoutine? _savedRoutine;
  String? _deletedId;

  @override
  Future<List<WorkoutRoutine>> getAllRoutines() async => _routines;

  @override
  WorkoutRoutine? getRoutine(String id) {
    for (final routine in _routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  @override
  Future<void> saveRoutine(WorkoutRoutine routine) async {
    _savedRoutine = routine;
    final existing = _routines.indexWhere((r) => r.id == routine.id);
    if (existing >= 0) {
      _routines[existing] = routine;
    } else {
      _routines.add(routine);
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    _deletedId = id;
    _routines.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> clearAll() async {
    _routines.clear();
  }

  WorkoutRoutine? get savedRoutine => _savedRoutine;
  String? get deletedId => _deletedId;
  List<WorkoutRoutine> get routines => _routines;
}

/// Stub repository that extends the real one and overrides methods.
class StubSessionRepository extends SessionRepository {
  final List<WorkoutSession> _sessions = [];

  @override
  Future<List<WorkoutSession>> getAllSessions() async => _sessions;

  @override
  WorkoutSession? getSession(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {
    _sessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearAll() async {
    _sessions.clear();
  }

  void addSession(WorkoutSession session) {
    _sessions.add(session);
  }

  List<WorkoutSession> get sessions => _sessions;
}

/// Stub repository that extends the real one and overrides methods.
class StubCustomExerciseRepository extends CustomExerciseRepository {
  final List<CustomExercise> _exercises = [];

  @override
  Future<List<CustomExercise>> getAllExercises() async => _exercises;

  @override
  CustomExercise? getExercise(String id) {
    for (final exercise in _exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  @override
  Future<void> saveExercise(CustomExercise exercise) async {
    final existing = _exercises.indexWhere((e) => e.id == exercise.id);
    if (existing >= 0) {
      _exercises[existing] = exercise;
    } else {
      _exercises.add(exercise);
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clearAll() async {
    _exercises.clear();
  }

  List<CustomExercise> get exercises => _exercises;
}
