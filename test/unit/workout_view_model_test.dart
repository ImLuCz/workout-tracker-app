import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';
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
}

void main() {
  late _StubSessionRepository repository;
  late WorkoutViewModel viewModel;

  setUp(() {
    repository = _StubSessionRepository();
    viewModel = WorkoutViewModel(repository: repository);
  });

  WorkoutRoutine makeRoutine({
    String id = 'routine-1',
    String name = 'Test Routine',
    List<RoutineExercise> exercises = const [],
  }) {
    return WorkoutRoutine(
      id: id,
      name: name,
      exercises: exercises,
      createdAt: DateTime.now(),
    );
  }

  RoutineExercise makeRoutineExercise({
    String id = 're-1',
    Exercise? exercise,
    int restSeconds = 90,
    int setsCount = 3,
  }) {
    return RoutineExercise(
      id: id,
      exercise: exercise ??
          const Exercise(id: 'ex-1', name: 'Bench Press', category: 'Chest'),
      order: 0,
      restSeconds: restSeconds,
      setsCount: setsCount,
    );
  }

  group('WorkoutViewModel', () {
    test('createSession() creates a session with correct exercises', () async {
      final routine = makeRoutine(
        exercises: [
          makeRoutineExercise(setsCount: 3),
        ],
      );

      final session = await viewModel.createSession(routine);

      expect(session, isNotNull);
      expect(session.routineId, 'routine-1');
      expect(session.routineName, 'Test Routine');
      expect(session.exercises.length, 1);
      expect(session.exercises.first.sets.length, 3);
      expect(session.exercises.first.sets.every((s) => !s.completed), isTrue);
    });

    test('completeSet() marks a set as completed', () async {
      final routine = makeRoutine(
        exercises: [
          makeRoutineExercise(setsCount: 2),
        ],
      );
      await viewModel.createSession(routine);

      viewModel.completeSet(0, 0);

      final session = viewModel.session;
      expect(session, isNotNull);
      expect(session!.exercises[0].sets[0].completed, isTrue);
      expect(session.exercises[0].sets[0].completedAt, isNotNull);
    });

    test('finishSession() sets end time and isFinished', () async {
      final routine = makeRoutine(
        exercises: [
          makeRoutineExercise(setsCount: 2),
        ],
      );
      await viewModel.createSession(routine);

      viewModel.finishSession();

      expect(viewModel.isFinished, isTrue);
      expect(viewModel.session!.endTime, isNotNull);
    });

    test('discardSession() clears the session', () async {
      final routine = makeRoutine(
        exercises: [
          makeRoutineExercise(setsCount: 2),
        ],
      );
      await viewModel.createSession(routine);
      expect(viewModel.session, isNotNull);

      viewModel.discardSession();

      expect(viewModel.session, isNull);
      expect(viewModel.isFinished, isFalse);
    });
  });
}
