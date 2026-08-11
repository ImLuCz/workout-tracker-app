import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';

import 'workout_active_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final routine = context.read<RoutineRepository>().getRoutine(routineId);
    if (routine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine')),
        body: const Center(child: Text('Routine not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutActiveScreen(routineId: routineId),
              ),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                context.read<RoutineViewModel>().delete(routineId);
                Navigator.pop(context);
              } else if (value == 'edit') {
                context.push('/routine/new?editId=$routineId');
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routine.exercises.length,
        itemBuilder: (context, index) {
          final exercise = routine.exercises[index];
          return Card(
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
            ),
          );
        },
      ),
    );
  }
}
