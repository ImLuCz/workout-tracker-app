import '../../constants/rest.dart';
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
    this.restSeconds = defaultRestSeconds,
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
      // Keep the whole Exercise unless the id is being replaced. Rebuilding it
      // from name/category/description alone silently dropped equipment, target,
      // secondaryMuscles and instructions, and every reordering or rest/sets
      // edit routes through here.
      exercise: exerciseId == null
          ? exercise
          : Exercise(
              id: exerciseId,
              name: exercise.name,
              category: exercise.category,
              description: exercise.description,
              equipment: exercise.equipment,
              target: exercise.target,
              secondaryMuscles: exercise.secondaryMuscles,
              instructions: exercise.instructions,
            ),
      order: order ?? this.order,
      restSeconds: restSeconds ?? this.restSeconds,
      setsCount: setsCount ?? this.setsCount,
    );
  }
}
