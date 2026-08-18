import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/constants/muscles.dart';
import 'package:workout_tracker_app/domain/models/stats.dart';
import 'package:workout_tracker_app/ui/screens/widgets/stats_widgets.dart';
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
      appBar: AppBar(title: const Text('Statistics'), automaticallyImplyLeading: false),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.sessionStats.isEmpty
              ? EmptyStats()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 11,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return OverallStats(stats: viewModel.overallStats ?? _emptyStats());
                      case 1:
                        return const SizedBox(height: 24);
                      case 2:
                        return WeekActivity(viewModel.sessionStats);
                      case 3:
                        return const SizedBox(height: 24);
                      case 4:
                        return VolumeChart(stats: viewModel.sessionStats);
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
                        return DangerZoneCard();
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
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedMuscle,
            decoration: InputDecoration(
              labelText: 'Filter by muscle group',
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
              .map((stat) => WeeklyMuscleRow(stat: stat))
        else
          ..._filteredStats
              .map((stat) => WeeklyMuscleRow(stat: stat)),
      ],
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
