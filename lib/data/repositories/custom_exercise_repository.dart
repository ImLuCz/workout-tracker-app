import 'dart:convert';

import 'package:workout_tracker_app/data/services/hive_service.dart';
import 'package:workout_tracker_app/domain/models/custom_exercise.dart';
import 'package:uuid/uuid.dart';

/// Repository for CRUD operations on custom exercises.
class CustomExerciseRepository {
  Future<void> saveExercise(CustomExercise exercise) async {
    final box = HiveService.customExercisesBox;
    final data = exercise.toJson();
    await box.put(exercise.id, jsonEncode(data));
  }

  Future<void> deleteExercise(String id) async {
    final box = HiveService.customExercisesBox;
    await box.delete(id);
  }

  Future<List<CustomExercise>> getAllExercises() async {
    final box = HiveService.customExercisesBox;
    final exercises = <CustomExercise>[];
    for (final key in box.keys) {
      final raw = box.get(key) as String?;
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          exercises.add(CustomExercise.fromJson(data));
        } catch (_) {}
      }
    }
    exercises.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return exercises;
  }

  CustomExercise? getExercise(String id) {
    final box = HiveService.customExercisesBox;
    final raw = box.get(id) as String?;
    if (raw == null) return null;
    try {
      return CustomExercise.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  CustomExerciseStats getStats(String exerciseId) {
    // Stats are derived from workout sessions.
    // For now, return empty stats; this can be expanded later.
    return CustomExerciseStats.empty();
  }

  String generateId() => const Uuid().v4();

  /// Alias for getAllExercises, used by routine_builder_screen.
  Future<List<CustomExercise>> getAllCustomExercises() => getAllExercises();

}
