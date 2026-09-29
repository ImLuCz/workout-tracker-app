import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';

import '../helpers/stub_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubRoutineRepository repository;
  late RoutineViewModel viewModel;

  setUp(() {
    repository = StubRoutineRepository();
    viewModel = RoutineViewModel(repository: repository);
  });

  group('RoutineViewModel', () {
    test('save() returns an ID and calls repository', () async {
      viewModel.setName('Push Day');
      final id = await viewModel.save();
      expect(id, isNotNull);
      expect(repository.savedRoutine, isNotNull);
    });

    test('save() returns null when name is empty', () async {
      viewModel.setName('');
      final id = await viewModel.save();
      expect(id, isNull);
    });

    test('save() with a name saves routine with correct name', () async {
      viewModel.setName('Push Day');
      final id = await viewModel.save();
      expect(id, isNotNull);
      expect(repository.savedRoutine!.name, 'Push Day');
    });

    test('delete() calls repository delete and reloads', () async {
      await repository.saveRoutine(WorkoutRoutine(
        id: 'routine-1',
        name: 'Test Routine',
        exercises: [],
        createdAt: DateTime.now(),
      ));
      expect(repository.routines.length, 1);

      await viewModel.delete('routine-1');
      expect(repository.deletedId, 'routine-1');
      expect(viewModel.routines.isEmpty, isTrue);
    });

    test('setName() updates the name and notifies', () {
      viewModel.addListener(() {});
      viewModel.setName('New Name');
      expect(viewModel.name, 'New Name');
    });

    test('addExercise() adds an exercise and notifies', () {
      final exercise = Exercise(id: 'ex-1', name: 'Bench Press', category: 'Chest');
      viewModel.addExercise(exercise);
      expect(viewModel.exercises.length, 1);
      expect(viewModel.exercises.first.exercise.id, 'ex-1');
      expect(viewModel.exercises.first.order, 0);
    });

    test('removeExercise() removes and reorders', () async {
      final exercise1 = Exercise(id: 'ex-1', name: 'A', category: 'Chest');
      final exercise2 = Exercise(id: 'ex-2', name: 'B', category: 'Back');
      final exercise3 = Exercise(id: 'ex-3', name: 'C', category: 'Legs');
      viewModel.addExercise(exercise1);
      viewModel.addExercise(exercise2);
      viewModel.addExercise(exercise3);

      expect(viewModel.exercises.length, 3);
      expect(viewModel.exercises[0].order, 0);
      expect(viewModel.exercises[1].order, 1);
      expect(viewModel.exercises[2].order, 2);

      final idToRemove = viewModel.exercises[1].id;
      viewModel.removeExercise(idToRemove);

      expect(viewModel.exercises.length, 2);
      expect(viewModel.exercises[0].order, 0);
      expect(viewModel.exercises[1].order, 1);
    });
  });
}
