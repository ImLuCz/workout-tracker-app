/// Represents a single set performed during a workout session.
class WorkoutSet {
  final String id;
  final double weightKg;
  final int reps;
  final bool completed;
  final DateTime? completedAt;

  const WorkoutSet({
    required this.id,
    this.weightKg = 0.0,
    this.reps = 0,
    this.completed = false,
    this.completedAt,
  });

  WorkoutSet copyWith({
    double? weightKg,
    int? reps,
    bool? completed,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isLogged => completed && completedAt != null;
}
