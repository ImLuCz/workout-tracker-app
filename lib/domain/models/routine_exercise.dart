import 'exercise.dart';

/// Represents an exercise assigned to a workout routine.
class RoutineExercise {
  final String id;
  final Exercise exercise;
  final int order;
  final int restSeconds;
  final int setsCount;

  const RoutineExercise({
    required this.id,
    required this.exercise,
    required this.order,
    this.restSeconds = 90,
    this.setsCount = 3,
  });

  RoutineExercise copyWith({
    String? exerciseId,
    int? order,
    int? restSeconds,
    int? setsCount,
  }) {
    return RoutineExercise(
      id: id,
      exercise: Exercise(
        id: exerciseId ?? exercise.id,
        name: exercise.name,
        category: exercise.category,
        description: exercise.description,
      ),
      order: order ?? this.order,
      restSeconds: restSeconds ?? this.restSeconds,
      setsCount: setsCount ?? this.setsCount,
    );
  }
}
