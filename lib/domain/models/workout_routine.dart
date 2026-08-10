import 'routine_exercise.dart';

/// Represents a saved workout routine (a list of exercises to perform).
class WorkoutRoutine {
  final String id;
  final String name;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
  });

  WorkoutRoutine copyWith({
    String? name,
    List<RoutineExercise>? exercises,
    DateTime? updatedAt,
  }) {
    return WorkoutRoutine(
      id: id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
