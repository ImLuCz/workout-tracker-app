import 'routine_exercise.dart';
import 'workout_set.dart';

/// Represents a single workout session.
class WorkoutSession {
  final String id;
  final String routineId;
  final String routineName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<SessionExercise> exercises;

  const WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startTime,
    this.endTime,
    required this.exercises,
  });

  WorkoutSession copyWith({
    DateTime? endTime,
    List<SessionExercise>? exercises,
  }) {
    return WorkoutSession(
      id: id,
      routineId: routineId,
      routineName: routineName,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
    );
  }

  bool get isFinished => endTime != null;

  double get totalVolume {
    return exercises.fold(0.0, (sum, ex) => sum + ex.totalWeight);
  }

  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  int get completedSets =>
      exercises.fold(0, (sum, ex) => sum + ex.sets.where((s) => s.completed).length);
}

/// An exercise within a workout session with its sets.
class SessionExercise {
  final RoutineExercise routineExercise;
  final List<WorkoutSet> sets;
  final int restSeconds;

  const SessionExercise({
    required this.routineExercise,
    required this.sets,
    this.restSeconds = 90,
  });

  double get totalWeight =>
      sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));

  SessionExercise copyWith({List<WorkoutSet>? sets, int? restSeconds}) {
    return SessionExercise(
      routineExercise: routineExercise,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}
