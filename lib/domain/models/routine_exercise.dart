import 'exercise.dart';

/// Represents an exercise assigned to a workout routine.
class RoutineExercise {
  final String id;
  final Exercise exercise;
  final int order;

  const RoutineExercise({
    required this.id,
    required this.exercise,
    required this.order,
  });

  RoutineExercise copyWith({String? exerciseId, int? order}) {
    return RoutineExercise(
      id: id,
      exercise: Exercise(
        id: exerciseId ?? exercise.id,
        name: exercise.name,
        category: exercise.category,
        description: exercise.description,
      ),
      order: order ?? this.order,
    );
  }
}
