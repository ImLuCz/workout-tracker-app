import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/constants/muscles.dart';
import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/data/repositories/session_repository.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StatsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.sessionStats.isEmpty
              ? _EmptyStats()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 11,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return _OverallStats(stats: viewModel.overallStats ?? _emptyStats());
                      case 1:
                        return const SizedBox(height: 24);
                      case 2:
                        return _WeekActivity(viewModel.sessionStats);
                      case 3:
                        return const SizedBox(height: 24);
                      case 4:
                        return _VolumeChart(stats: viewModel.sessionStats);
                      case 5:
                        return const SizedBox(height: 24);
                      case 6:
                        return _WeeklyMuscleSetsSection(
                          weeklyMuscleStats: viewModel.weeklyMuscleStats,
                        );
                      case 7:
                        return const SizedBox(height: 24);
                      case 8:
                        return const SizedBox(height: 24);
                      case 9:
                        return _SessionList(stats: viewModel.sessionStats);
                      case 10:
                        return const _DangerZone();
                      default:
                        return const SizedBox.shrink();
                    }
                  },
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout data yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
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
                            : theme.dividerColor.withValues(alpha: 0.3),
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
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    final last5 = stats.take(5).toList().reversed.toList();

    if (last5.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sessions (Last 5) — Sets per Workout',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: last5.length,
                itemBuilder: (context, index) {
                  final stat = last5[index];
                  final maxVolume = last5.map((s) => s.volumeKg).reduce((a, b) => a > b ? a : b);
                  final height = maxVolume > 0 ? (stat.volumeKg / maxVolume.toDouble()) * 120.0 : 0.0;
                  return SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
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

class _WeeklyMuscleSetsSection extends StatefulWidget {
  final List<WeeklyMuscleStats> weeklyMuscleStats;

  const _WeeklyMuscleSetsSection({required this.weeklyMuscleStats});

  @override
  State<_WeeklyMuscleSetsSection> createState() => _WeeklyMuscleSetsSectionState();
}

class _WeeklyMuscleSetsSectionState extends State<_WeeklyMuscleSetsSection> {
  String _selectedMuscle = 'All';

  List<String> get _muscleOptions => ['All', ...allMuscles];

  List<WeeklyMuscleStats> get _filteredStats {
    if (_selectedMuscle == 'All') return widget.weeklyMuscleStats;
    return widget.weeklyMuscleStats
        .where((s) => s.muscleName == _selectedMuscle)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = widget.weeklyMuscleStats.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Muscle Sets',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedMuscle,
          decoration: InputDecoration(
            hintText: 'Filter by muscle group...',
            prefixIcon: const Icon(Icons.filter_list),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _muscleOptions
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedMuscle = value);
          },
        ),
        const SizedBox(height: 12),
        if (!hasData)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No weekly muscle data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else if (_selectedMuscle == 'All')
          ...widget.weeklyMuscleStats
              .where((s) => s.totalSetsThisWeek > 0)
              .map((stat) => _WeeklyMuscleRow(stat: stat))
        else
          ..._filteredStats
              .map((stat) => _WeeklyMuscleRow(stat: stat)),
      ],
    );
  }
}

class _WeeklyMuscleRow extends StatelessWidget {
  final WeeklyMuscleStats stat;

  const _WeeklyMuscleRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(stat.muscleName),
        subtitle: Text(
          '${(stat.totalVolumeKgThisWeek / 1000).toStringAsFixed(1)} t',
        ),
        trailing: Text(
          '${stat.totalSetsThisWeek.toStringAsFixed(stat.totalSetsThisWeek == stat.totalSetsThisWeek.toInt() ? 0 : 1)} sets',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
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
        if (stats.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No results found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ...stats.take(10).map((stat) => _SessionRow(stat: stat)),
      ],
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    return const _DangerZoneCard();
  }
}

class _DangerZoneCard extends StatefulWidget {
  const _DangerZoneCard();

  @override
  State<_DangerZoneCard> createState() => _DangerZoneCardState();
}

class _DangerZoneCardState extends State<_DangerZoneCard> {
  bool _isDeleting = false;

  Future<void> _confirmAndClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your workout routines, workout sessions, and custom exercises. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final routineRepo = context.read<RoutineRepository>();
      final sessionRepo = context.read<SessionRepository>();
      final customExerciseRepo = context.read<CustomExerciseRepository>();
      final statsVm = context.read<StatsViewModel>();
      try {
        await routineRepo.clearAll();
        await sessionRepo.clearAll();
        await customExerciseRepo.clearAll();
        if (mounted) {
          statsVm.loadStats();
        }
      } catch (_) {}
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Card(
      color: errorColor.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: errorColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Deleting all data will permanently remove all workout routines, workout sessions, and custom exercises. This cannot be undone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _confirmAndClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Delete All Data',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
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
