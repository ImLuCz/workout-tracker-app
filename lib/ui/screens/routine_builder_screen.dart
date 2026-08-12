import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';

import 'package:workout_tracker_app/domain/models/exercise.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';

class RoutineBuilderScreen extends StatefulWidget {
  final String? routineId;

  const RoutineBuilderScreen({super.key, this.routineId});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.routineId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = Provider.of<RoutineViewModel>(context, listen: false);
        final routine = context.read<RoutineViewModel>().getRoutine(widget.routineId!);
        if (routine != null) {
          viewModel.startEdit(routine);
        }
      });
    }
  }

  Future<void> _handleSave(BuildContext context, RoutineViewModel viewModel) async {
    final id = await viewModel.save();
    if (id != null && context.mounted) {
      context.pushReplacement('/routine?id=$id');
    }
  }

  void _showAddExerciseSheet(BuildContext context) {
    _showCustomExercisesPicker(context);
  }

  void _showCustomExercisesPicker(BuildContext context) async {
    final exercises = await context
        .read<CustomExerciseRepository>()
        .getAllCustomExercises();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: exercises.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No custom exercises yet.\nCreate some first!',
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'My Exercises (${exercises.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exercises.length,
                        itemBuilder: (ctx, index) {
                          final exercise = exercises[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                exercise.name[0].toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(exercise.name),
                            subtitle: Text(exercise.primaryMuscles.join(', ')),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.read<RoutineViewModel>().addExercise(
                                Exercise(
                                  id: exercise.id,
                                  name: exercise.name,
                                  category: 'Custom',
                                  description: exercise.description,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${exercise.name} added to routine'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RoutineViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.editingId != null ? 'Edit Routine' : 'Create Routine'),
        actions: [
          TextButton(
            onPressed: viewModel.exercises.isEmpty
                ? null
                : () => _handleSave(context, viewModel),
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
        onPressed: () => _showAddExerciseSheet(context),
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add exercises from your custom exercises',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
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
          child: ReorderableDragStartListener(
            index: index,
            child: _ExerciseRow(
              exercise: exercise,
              order: index + 1,
              onRestChanged: (restSeconds) =>
                  viewModel.updateExerciseRestSeconds(exercise.id, restSeconds),
              onSetsChanged: (count) =>
                  viewModel.updateExerciseSetsCount(exercise.id, count),
            ),
          ),
        );
      },
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final RoutineExercise exercise;
  final int order;
  final ValueChanged<int> onRestChanged;
  final ValueChanged<int> onSetsChanged;

  const _ExerciseRow({
    required this.exercise,
    required this.order,
    required this.onRestChanged,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.drag_handle,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    exercise.exercise.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _RestSecondsInput(
                value: exercise.restSeconds,
                onChanged: onRestChanged,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: _SetsCountInput(
                value: exercise.setsCount,
                onChanged: onSetsChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestSecondsInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RestSecondsInput({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RestSecondsInput> createState() => _RestSecondsInputState();
}

class _RestSecondsInputState extends State<_RestSecondsInput> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _RestSecondsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
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
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onEditingComplete: () {
        final parsed = int.tryParse(_controller.text);
        widget.onChanged((parsed ?? 0).clamp(0, 1800));
        FocusScope.of(context).unfocus();
      },
      onChanged: (value) {},
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _editing ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2)),
        ),
        suffixText: 's',
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
      onTapOutside: (event) {
        final parsed = int.tryParse(_controller.text);
        widget.onChanged((parsed ?? 0).clamp(0, 1800));
        setState(() => _editing = false);
      },
    );
  }
}

class _SetsCountInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _SetsCountInput({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SetsCountInput> createState() => _SetsCountInputState();
}

class _SetsCountInputState extends State<_SetsCountInput> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _SetsCountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
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
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onEditingComplete: () {
        final parsed = int.tryParse(_controller.text);
        widget.onChanged((parsed ?? 1).clamp(1, 20));
        FocusScope.of(context).unfocus();
      },
      onChanged: (value) {},
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _editing ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2)),
        ),
        suffixText: 'sets',
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
      onTapOutside: (event) {
        final parsed = int.tryParse(_controller.text);
        widget.onChanged((parsed ?? 1).clamp(1, 20));
        setState(() => _editing = false);
      },
    );
  }
}
