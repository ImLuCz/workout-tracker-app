import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workout_tracker_app/domain/models/workout_set.dart';
import 'package:workout_tracker_app/domain/models/workout_session.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

/// Typedef for callbacks that carry two arguments.
typedef ValueChanged2<A, B> = void Function(A a, B b);

/// Horizontal rest-timer bar with +/- 10s buttons and a skip action.
class RestTimerBar extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const RestTimerBar({required this.viewModel});

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

/// Pill-shaped rest-timer chip shown in the app bar.
class RestTimerChip extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const RestTimerChip({required this.viewModel});

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

/// Card displaying an exercise and its set rows.
class ExerciseCard extends StatelessWidget {
  final SessionExercise exercise;
  final ValueChanged<int> onSetComplete;
  final ValueChanged2<int, double> onChangeWeight;
  final ValueChanged2<int, int> onChangeReps;

  const ExerciseCard({
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
              return SetRow(
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

/// Single row for one set, showing completion toggle, weight, and reps inputs.
class SetRow extends StatelessWidget {
  final WorkoutSet set;
  final int index;
  final VoidCallback onComplete;
  final ValueChanged2<int, double> onChangeWeight;
  final ValueChanged2<int, int> onChangeReps;

  const SetRow({
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
            child: SetInput(
              label: 'kg',
              value: set.weightKg,
              onChanged: (v) => onChangeWeight(index, v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: SetInput(
              label: 'reps',
              value: set.reps.toDouble(),
              onChanged: (v) => onChangeReps(index, v.toInt()),
            ),
          ),
          const SizedBox(width: 12),
          if (set.weightKg > 0 && set.reps > 0)
            Flexible(
              child: Text(
                '${(set.weightKg * set.reps).toStringAsFixed(0)}kg total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Numeric text input for weight or reps with inline label.
class SetInput extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const SetInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SetInput> createState() => _SetInputState();
}

class _SetInputState extends State<SetInput> {
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
  void didUpdateWidget(covariant SetInput oldWidget) {
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
