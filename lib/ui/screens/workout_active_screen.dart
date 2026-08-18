import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:workout_tracker_app/data/repositories/session_repository.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
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
          if (viewModel.restTimerRunning) _RestTimerChip(viewModel: viewModel),
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
          if (viewModel.restTimerRunning) _RestTimerBar(viewModel: viewModel),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.session!.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                final exercise = viewModel.session!.exercises[exerciseIndex];
                return _ExerciseCard(
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
              foregroundColor: WidgetStatePropertyAll(Colors.red.shade700),
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
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () => viewModel.adjustRestSeconds(-10),
            tooltip: 'Remove 10s',
          ),
          Text(
            'Rest: $timeStr',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => viewModel.adjustRestSeconds(10),
            tooltip: 'Add 10s',
          ),
          const SizedBox(width: 8),
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
  final ValueChanged<int> onSetComplete;
  final ValueChanged2<int, double> onChangeWeight;
  final ValueChanged2<int, int> onChangeReps;

  const _ExerciseCard({
    required this.exercise,
    required this.onSetComplete,
    required this.onChangeWeight,
    required this.onChangeReps,
  });

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
              return _SetRow(
                set: set,
                index: index,
                onComplete: () => onSetComplete(index),
                onChangeWeight: (idx, weight) => onChangeWeight(idx, weight),
                onChangeReps: (idx, reps) => onChangeReps(idx, reps),
              );
            }),
          ],
        ),
      ),
    );
  }
}

typedef ValueChanged2<A, B> = void Function(A a, B b);

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

class _SetRow extends StatelessWidget {
  final WorkoutSet set;
  final int index;
  final VoidCallback onComplete;
  final ValueChanged2<int, double> onChangeWeight;
  final ValueChanged2<int, int> onChangeReps;

  const _SetRow({
    required this.set,
    required this.index,
    required this.onComplete,
    required this.onChangeWeight,
    required this.onChangeReps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              'Set ${index + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (set.completed)
            Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.primary,
            )
          else
            IconButton(
              icon: Icon(
                Icons.circle_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onComplete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: _SetInput(
              label: 'kg',
              value: set.weightKg,
              onChanged: (v) => onChangeWeight(index, v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: _SetInput(
              label: 'reps',
              value: set.reps.toDouble(),
              onChanged: (v) => onChangeReps(index, v.toInt()),
            ),
          ),
          const SizedBox(width: 12),
          if (set.weightKg > 0 && set.reps > 0)
            Text(
              '${(set.weightKg * set.reps).toStringAsFixed(0)}kg total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _SetInput extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SetInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SetInput> createState() => _SetInputState();
}

class _SetInputState extends State<_SetInput> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _SetInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onEditingComplete: () {
        final parsed = double.tryParse(_controller.text);
        widget.onChanged(parsed ?? 0);
        FocusScope.of(context).unfocus();
      },
      onChanged: (value) {},
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _editing
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
        ),
        suffixText: widget.label,
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
      onTapOutside: (event) {
        final parsed = double.tryParse(_controller.text);
        widget.onChanged(parsed ?? 0);
        setState(() => _editing = false);
      },
    );
  }
}
