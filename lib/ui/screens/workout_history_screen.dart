import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:workout_tracker_app/view_models/stats_view_model.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StatsViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.sessionStats.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.sessionStats.length,
                  itemBuilder: (context, index) {
                    final stat = viewModel.sessionStats[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          stat.routineName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(stat.date),
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.fitness_center, size: 14),
                                const SizedBox(width: 4),
                                Text('${stat.completedSets}/${stat.totalSets} sets'),
                                const SizedBox(width: 16),
                                Icon(Icons.show_chart, size: 14),
                                const SizedBox(width: 4),
                                Text('${(stat.volumeKg / 1000).toStringAsFixed(1)}t'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatDuration(stat.duration),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
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
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first workout to see history',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
