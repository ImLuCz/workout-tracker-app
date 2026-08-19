import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:workout_tracker_app/data/repositories/session_repository.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/ui/screens/widgets/workout_active_widgets.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';
import 'package:workout_tracker_app/view_models/stats_view_model.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

class WorkoutActiveScreen extends StatelessWidget {
  final String routineId;

  const WorkoutActiveScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);

    if (viewModel.session == null) {
      return _StartScreen(routineId: routineId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.session!.routineName),
        actions: [
          if (viewModel.restTimerRunning) RestTimerChip(viewModel: viewModel),
          if (!viewModel.session!.isFinished) ...[
            TextButton(
              onPressed: () => _showFinishDialog(context),
              child: const Text('Finish'),
            ),
            TextButton(
              onPressed: () => _showDiscardDialog(context),
              child: const Text('Discard'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (viewModel.restTimerRunning) RestTimerBar(viewModel: viewModel),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.session!.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                final exercise = viewModel.session!.exercises[exerciseIndex];
                return ExerciseCard(
                  exercise: exercise,
                  onSetComplete: (setIndex) =>
                      viewModel.completeSet(exerciseIndex, setIndex),
                  onChangeWeight: (idx, weight) =>
                      viewModel.updateSetWeight(exerciseIndex, idx, weight),
                  onChangeReps: (idx, reps) =>
                      viewModel.updateSetReps(exerciseIndex, idx, reps),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context) {
    final viewModel = context.read<WorkoutViewModel>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final statsVm = context.read<StatsViewModel>();
              Navigator.pop(context);
              viewModel.finishSession();
              await viewModel.saveSession();
              await statsVm.reloadStats();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Workout'),
        content: const Text('Are you sure you want to discard this workout? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Workout'),
          ),
          TextButton(
            onPressed: () {
              context.read<WorkoutViewModel>().discardSession();
              Navigator.of(context).pop();
              if (context.mounted) {
                context.go('/');
              }
            },
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
            ),
            child: const Text('Discard'),
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
    final routine = context.read<RoutineViewModel>().getRoutine(routineId);
    final viewModel = context.read<WorkoutViewModel>();
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
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final sessionRepo = context.read<SessionRepository>();
                final previousSession = await sessionRepo.getLastCompletedSessionForRoutine(routine.id);
                final previousSetDefaults = _extractSetDefaults(previousSession);
                await viewModel.createSession(
                  routine,
                  previousSetDefaults: previousSetDefaults,
                );
              },
              child: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracts the last-known weight and reps per set index for each exercise
/// in a previous completed session, keyed by exercise ID.
Map<String, Map<int, SetDefaults>> _extractSetDefaults(
    WorkoutSession? session) {
  if (session == null) return {};
  final result = <String, Map<int, SetDefaults>>{};
  for (final ex in session.exercises) {
    final exerciseId = ex.routineExercise.exercise.id;
    final setMap = <int, SetDefaults>{};
    for (int i = 0; i < ex.sets.length; i++) {
      final set = ex.sets[i];
      setMap[i] = SetDefaults(weightKg: set.weightKg, reps: set.reps);
    }
    result[exerciseId] = setMap;
  }
  return result;
}
