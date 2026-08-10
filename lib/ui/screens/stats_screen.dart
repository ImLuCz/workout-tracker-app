import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/domain/models/stats.dart';
import 'package:workout_tracker_app/view_models/stats_view_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StatsViewModel>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StatsViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.sessionStats.isEmpty
              ? _EmptyStats()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OverallStats(stats: viewModel.overallStats ?? _emptyStats()),
                    const SizedBox(height: 24),
                    _WeekActivity(viewModel.sessionStats),
                    const SizedBox(height: 24),
                    _VolumeChart(stats: viewModel.sessionStats),
                    const SizedBox(height: 24),
                    _SessionList(stats: viewModel.sessionStats),
                  ],
                ),
    );
  }

  WorkoutStats _emptyStats() => const WorkoutStats(
        totalVolumeKg: 0,
        totalSessions: 0,
        totalSets: 0,
        totalCompletedSets: 0,
        sessionStats: [],
      );
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout data yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallStats extends StatelessWidget {
  final WorkoutStats stats;

  const _OverallStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Volume',
          value: '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}t',
          icon: Icons.fitness_center,
        ),
        _StatCard(
          title: 'Sessions',
          value: '${stats.totalSessions}',
          icon: Icons.check_circle,
        ),
        _StatCard(
          title: 'Avg Volume',
          value: '${(stats.avgVolumePerSession / 1000).toStringAsFixed(1)}t',
          icon: Icons.show_chart,
        ),
        _StatCard(
          title: 'Completion',
          value: '${(stats.completionRate * 100).toStringAsFixed(0)}%',
          icon: Icons.percent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekActivity extends StatelessWidget {
  final List<SessionStat> stats;

  const _WeekActivity(this.stats);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final hasWorkout = List.generate(7, (index) {
      final dayDate = startOfWeek.add(Duration(days: index));
      return stats.any((s) =>
          s.date.year == dayDate.year &&
          s.date.month == dayDate.month &&
          s.date.day == dayDate.day);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.asMap().entries.map((e) {
              final isToday = e.key == now.weekday - 1;
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasWorkout[e.key]
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        e.value,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasWorkout[e.key]
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasWorkout[e.key] ? 'Done' : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: hasWorkout[e.key]
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<SessionStat> stats;

  const _VolumeChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last7 = stats.take(7).toList().reversed.toList();

    if (last7.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume Trend (Last 7 Sessions)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: last7.length,
                itemBuilder: (context, index) {
                  final stat = last7[index];
                  final maxVolume = last7.map((s) => s.volumeKg).reduce((a, b) => a > b ? a : b);
                  final height = maxVolume > 0 ? (stat.volumeKg / maxVolume.toDouble()) * 120.0 : 0.0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stat.completedSets}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<SessionStat> stats;

  const _SessionList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...stats.take(10).map((stat) => _SessionRow(stat: stat)),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final SessionStat stat;

  const _SessionRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(stat.routineName),
        subtitle: Text(
          '${stat.date.day}/${stat.date.month}/${stat.date.year} · ${_formatDuration(stat.duration)}',
        ),
        trailing: Text(
          '${(stat.volumeKg / 1000).toStringAsFixed(1)}t',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}
