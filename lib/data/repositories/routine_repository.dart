import 'dart:convert';

import 'package:workout_tracker_app/data/services/hive_service.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';

/// Repository for CRUD operations on workout routines.
class RoutineRepository {
  Future<void> saveRoutine(WorkoutRoutine routine) async {
    final box = HiveService.routinesBox;
    final data = <String, dynamic>{
      'id': routine.id,
      'name': routine.name,
      'exercises': routine.exercises
          .map((e) => _routineExerciseToJson(e))
          .toList(),
      'createdAt': routine.createdAt.toIso8601String(),
      'updatedAt': routine.updatedAt?.toIso8601String(),
    };
    await box.put(routine.id, jsonEncode(data));
  }

  Future<void> deleteRoutine(String id) async {
    final box = HiveService.routinesBox;
    await box.delete(id);
  }

  /// Deletes all routines from storage.
  Future<void> clearAll() async {
    final box = HiveService.routinesBox;
    await box.clear();
  }

  Future<List<WorkoutRoutine>> getAllRoutines() async {
    final box = HiveService.routinesBox;
    final routines = <WorkoutRoutine>[];
    for (final key in box.keys) {
      final raw = box.get(key) as String?;
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          routines.add(_fromJson(data));
        } catch (_) {}
      }
    }
    routines.sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? DateTime(0)) ?? 0);
    return routines;
  }

  WorkoutRoutine? getRoutine(String id) {
    final box = HiveService.routinesBox;
    final raw = box.get(id) as String?;
    if (raw == null) return null;
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  WorkoutRoutine _fromJson(Map<String, dynamic> data) {
    final exercises = (data['exercises'] as List<dynamic>?)
            ?.map((e) => _routineExerciseFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return WorkoutRoutine(
      id: data['id'] as String,
      name: data['name'] as String,
      exercises: exercises,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  RoutineExercise _routineExerciseFromJson(Map<String, dynamic> data) {
    return RoutineExercise(
      id: data['exerciseId'] as String,
      exercise: _exerciseFromJson(data['exercise'] as Map<String, dynamic>),
      order: data['order'] as int? ?? 0,
      restSeconds: data['restSeconds'] as int? ?? 90,
    );
  }

  Map<String, dynamic> _routineExerciseToJson(RoutineExercise e) {
    return {
      'exerciseId': e.exercise.id,
      'exercise': {
        'id': e.exercise.id,
        'name': e.exercise.name,
        'category': e.exercise.category,
        'description': e.exercise.description,
        'target': e.exercise.target,
        'secondaryMuscles': e.exercise.secondaryMuscles,
      },
      'order': e.order,
      'restSeconds': e.restSeconds,
    };
  }

  Exercise _exerciseFromJson(Map<String, dynamic> data) {
    return Exercise(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      description: data['description'] as String?,
      target: data['target'] as String?,
      secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
