import 'dart:convert';

import 'package:workout_tracker_app/data/services/hive_service.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';

/// Repository for CRUD operations on workout sessions.
class SessionRepository {
  Future<void> saveSession(WorkoutSession session) async {
    final box = HiveService.sessionsBox;
    final data = <String, dynamic>{
      'id': session.id,
      'routineId': session.routineId,
      'routineName': session.routineName,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'exercises': session.exercises
          .map((e) => _sessionExerciseToJson(e))
          .toList(),
    };
    await box.put(session.id, jsonEncode(data));
  }

  Future<void> deleteSession(String id) async {
    final box = HiveService.sessionsBox;
    await box.delete(id);
  }

  Future<List<WorkoutSession>> getAllSessions() async {
    final box = HiveService.sessionsBox;
    final sessions = <WorkoutSession>[];
    for (final key in box.keys) {
      final raw = box.get(key) as String?;
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          sessions.add(_fromJson(data));
        } catch (_) {}
      }
    }
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  WorkoutSession? getSession(String id) {
    final box = HiveService.sessionsBox;
    final raw = box.get(id) as String?;
    if (raw == null) return null;
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Expose for Provider access
  static SessionRepository get instance => SessionRepository();

  WorkoutSession _fromJson(Map<String, dynamic> data) {
    final exercises = (data['exercises'] as List<dynamic>?)
            ?.map((e) => _sessionExerciseFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return WorkoutSession(
      id: data['id'] as String,
      routineId: data['routineId'] as String,
      routineName: data['routineName'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : null,
      exercises: exercises,
    );
  }

  SessionExercise _sessionExerciseFromJson(Map<String, dynamic> data) {
    final sets = (data['sets'] as List<dynamic>?)
            ?.map((s) => _workoutSetFromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    return SessionExercise(
      routineExercise: RoutineExercise(
        id: data['exerciseId'] as String,
        exercise: _exerciseFromJson(data['exercise'] as Map<String, dynamic>),
        order: data['order'] as int? ?? 0,
        restSeconds: data['restSeconds'] as int? ?? 90,
      ),
      sets: sets,
      restSeconds: data['restSeconds'] as int? ?? 90,
      primaryMuscles: (data['primaryMuscles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Exercise _exerciseFromJson(Map<String, dynamic> data) {
    return Exercise(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> _sessionExerciseToJson(SessionExercise e) {
    return {
      'exerciseId': e.routineExercise.exercise.id,
      'exercise': {
        'id': e.routineExercise.exercise.id,
        'name': e.routineExercise.exercise.name,
        'category': e.routineExercise.exercise.category,
        'description': e.routineExercise.exercise.description,
        'primaryMuscles': e.primaryMuscles,
        'secondaryMuscles': e.secondaryMuscles,
      },
      'order': e.routineExercise.order,
      'restSeconds': e.restSeconds,
      'sets': e.sets.map(_workoutSetToJson).toList(),
    };
  }

  WorkoutSet _workoutSetFromJson(Map<String, dynamic> data) {
    return WorkoutSet(
      id: data['id'] as String,
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: data['reps'] as int? ?? 0,
      completed: data['completed'] as bool? ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _workoutSetToJson(WorkoutSet s) {
    return {
      'id': s.id,
      'weightKg': s.weightKg,
      'reps': s.reps,
      'completed': s.completed,
      'completedAt': s.completedAt?.toIso8601String(),
    };
  }
}
