import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/view_models/stats_view_model.dart';
import 'package:workout_tracker_app/data/repositories/session_repository.dart';

// Stub repository that extends the real one and overrides methods
class _StubSessionRepository extends SessionRepository {
  final List<WorkoutSession> _sessions = [];

  @override
  Future<List<WorkoutSession>> getAllSessions() async => _sessions;

  @override
  Future<void> saveSession(WorkoutSession session) async {
    _sessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  void addSession(WorkoutSession session) {
    _sessions.add(session);
  }

  List<WorkoutSession> get sessions => _sessions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubSessionRepository repository;
  late StatsViewModel viewModel;

  setUp(() {
    repository = _StubSessionRepository();
    viewModel = StatsViewModel(repository: repository);
  });

  WorkoutSession makeSession({
    required String id,
    required DateTime startTime,
    DateTime? endTime,
    required List<SessionExercise> exercises,
  }) {
    return WorkoutSession(
      id: id,
      routineId: 'routine-1',
      routineName: 'Test Routine',
      startTime: startTime,
      endTime: endTime,
      exercises: exercises,
    );
  }

  SessionExercise makeExercise({
    required List<WorkoutSet> sets,
    List<String> primaryMuscles = const [],
    List<String> secondaryMuscles = const [],
  }) {
    return SessionExercise(
      routineExercise: const RoutineExercise(
        id: 're-1',
        exercise: Exercise(id: 'ex-1', name: 'Bench', category: 'Chest'),
        order: 0,
      ),
      sets: sets,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
    );
  }

  group('StatsViewModel', () {
    test('loadStats() populates session stats, overall stats, muscle stats',
        () async {
      final now = DateTime.now();
      repository.addSession(makeSession(
        id: 'session-1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        exercises: [
          makeExercise(
            sets: [
              WorkoutSet(id: 's1', weightKg: 60.0, reps: 10, completed: true),
              WorkoutSet(id: 's2', weightKg: 60.0, reps: 10, completed: false),
            ],
            primaryMuscles: ['Chest'],
          ),
        ],
      ));

      await viewModel.loadStats();

      expect(viewModel.sessionStats.length, 1);
      expect(viewModel.overallStats, isNotNull);
      expect(viewModel.overallStats!.totalSessions, 1);
      expect(viewModel.weeklyMuscleStats.length, 1);
      expect(viewModel.weeklyMuscleStats.first.muscleName, 'Chest');
    });

    test('_computeWeeklyMuscleStats handles multiple sessions in the same week', () async {
      final now = DateTime.now();
      repository.addSession(makeSession(
        id: 'session-1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        exercises: [
          makeExercise(
            sets: [
              WorkoutSet(id: 's1', weightKg: 80.0, reps: 8, completed: true),
              WorkoutSet(id: 's2', weightKg: 80.0, reps: 8, completed: true),
            ],
            primaryMuscles: ['Chest'],
            secondaryMuscles: ['Triceps'],
          ),
        ],
      ));
      repository.addSession(makeSession(
        id: 'session-2',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, minutes: 30)),
        exercises: [
          makeExercise(
            sets: [
              WorkoutSet(id: 's3', weightKg: 85.0, reps: 6, completed: true),
            ],
            primaryMuscles: ['Chest'],
            secondaryMuscles: ['Triceps'],
          ),
        ],
      ));

      await viewModel.loadStats();

      final weeklyChest = viewModel.weeklyMuscleStats
          .where((s) => s.muscleName == 'Chest')
          .firstOrNull;
      final weeklyTriceps = viewModel.weeklyMuscleStats
          .where((s) => s.muscleName == 'Triceps')
          .firstOrNull;

      expect(weeklyChest, isNotNull);
      expect(weeklyChest!.totalSetsThisWeek, 3.0);
      expect(weeklyChest.totalVolumeKgThisWeek, (80.0 * 8 * 2) + (85.0 * 6));

      expect(weeklyTriceps, isNotNull);
      expect(weeklyTriceps!.totalSetsThisWeek, 1.5);
    });

    test('_computeWeeklyMuscleStats correctly filters by week', () async {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Session this week
      repository.addSession(makeSession(
        id: 'session-1',
        startTime: startOfWeek.add(const Duration(days: 1)),
        endTime: startOfWeek.add(const Duration(days: 1, minutes: 30)),
        exercises: [
          makeExercise(
            sets: [
              WorkoutSet(id: 's1', weightKg: 60.0, reps: 10, completed: true),
            ],
            primaryMuscles: ['Chest'],
          ),
        ],
      ));

      // Session last week (before start of current week)
      repository.addSession(makeSession(
        id: 'session-2',
        startTime: startOfWeek.subtract(const Duration(days: 6)),
        endTime: startOfWeek.subtract(const Duration(days: 6, minutes: 30)),
        exercises: [
          makeExercise(
            sets: [
              WorkoutSet(id: 's2', weightKg: 70.0, reps: 10, completed: true),
            ],
            primaryMuscles: ['Chest'],
          ),
        ],
      ));

      await viewModel.loadStats();

      final weeklyChest = viewModel.weeklyMuscleStats
          .where((m) => m.muscleName == 'Chest')
          .firstOrNull;

      expect(weeklyChest, isNotNull);
      expect(weeklyChest!.totalSetsThisWeek, 1);
      expect(weeklyChest.totalVolumeKgThisWeek, 600.0);
    });
  });
}
