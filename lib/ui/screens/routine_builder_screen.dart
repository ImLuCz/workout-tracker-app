import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/navigation/router.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';

import 'exercise_list_screen.dart';

class RoutineBuilderScreen extends StatelessWidget {
  const RoutineBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RoutineViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Routine'),
        actions: [
          TextButton(
            onPressed: viewModel.exercises.isEmpty ? null : viewModel.save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: viewModel.setName,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g., Push Day',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Exercises (${viewModel.exercises.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: viewModel.exercises.isEmpty
                  ? _EmptyState()
                  : _ExerciseList(viewModel: viewModel),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseListScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add exercises from the database',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  final RoutineViewModel viewModel;

  const _ExerciseList({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex--;
        viewModel.moveExercise(oldIndex, newIndex);
      },
      itemCount: viewModel.exercises.length,
      itemBuilder: (context, index) {
        final exercise = viewModel.exercises[index];
        return Dismissible(
          key: ValueKey(exercise.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => viewModel.removeExercise(exercise.id),
          background: Container(
            color: Colors.red.shade100,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              title: Text(exercise.exercise.name),
              subtitle: Text(exercise.exercise.category),
              trailing: const Icon(Icons.drag_handle),
            ),
          ),
        );
      },
    );
  }
}
