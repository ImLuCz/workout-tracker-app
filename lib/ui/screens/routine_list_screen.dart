import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RoutineViewModel>().loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RoutineViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.routines.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.routines.length,
                  itemBuilder: (context, index) {
                    final routine = viewModel.routines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(routine.name),
                        subtitle: Text(
                          '${routine.exercises.length} exercise${routine.exercises.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/routine?id=${routine.id}'),
                      ),
                    );
                  },
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
            'No routines yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first routine to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
