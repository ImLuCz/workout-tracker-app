import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

class WorkoutActiveScreen extends StatelessWidget {
  final String routineId;

  const WorkoutActiveScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    final theme = Theme.of(context);

    if (viewModel.session == null) {
      return _StartScreen(routineId: routineId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.session!.routineName),
        actions: [
          if (viewModel.restTimerRunning)
            _RestTimerChip(viewModel: viewModel),
          if (!viewModel.session!.isFinished)
            TextButton(
              onPressed: () {
                viewModel.finishSession();
                viewModel.saveSession();
                Navigator.pop(context);
              },
              child: const Text('Finish'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (viewModel.restTimerRunning) _RestTimerBar(viewModel: viewModel),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.session!.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                final exercise = viewModel.session!.exercises[exerciseIndex];
                return _ExerciseCard(
                  exercise: exercise,
                  onSetComplete: () => viewModel.completeSet(exerciseIndex, 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StartScreen extends StatelessWidget {
  final String routineId;

  const _StartScreen({required this.routineId});

  @override
  Widget build(BuildContext context) {
    final routine = context.read<RoutineRepository>().getRoutine(routineId);
    final theme = Theme.of(context);

    if (routine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('Routine not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(routine.name)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to workout?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press start to begin your session',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final viewModel = context.read<WorkoutViewModel>();
                viewModel.createSession(routine);
              },
              child: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const _RestTimerBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final minutes = viewModel.restSeconds ~/ 60;
    final seconds = viewModel.restSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Rest: $timeStr',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: viewModel.cancelRest,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _RestTimerChip extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const _RestTimerChip({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final minutes = viewModel.restSeconds ~/ 60;
    final seconds = viewModel.restSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final SessionExercise exercise;
  final VoidCallback onSetComplete;

  const _ExerciseCard({required this.exercise, required this.onSetComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.routineExercise.exercise.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(set: set, index: index, onComplete: onSetComplete);
            }),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final WorkoutSet set;
  final int index;
  final VoidCallback onComplete;

  const _SetRow({required this.set, required this.index, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: set.completed ? null : onComplete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: set.completed
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              'Set ${index + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            if (set.completed)
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            const Spacer(),
            Text(
              '${set.weightKg}kg × ${set.reps}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
