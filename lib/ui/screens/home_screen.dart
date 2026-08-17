import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndex();
  }

  void _updateIndex() {
    final location = GoRouterState.of(context).uri.path;
    int index = 0;
    if (location.startsWith('/routine')) {
      index = 1;
    } else if (location.startsWith('/exercise')) {
      index = 2;
    } else if (location.startsWith('/stats')) {
      index = 3;
    }
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTabTapped(int index) {
    final routes = <String>[
      '/',
      '/routine',
      '/exercise',
      '/stats',
    ];
    final target = routes[index];
    final current = GoRouterState.of(context).uri.path;
    if (target != current) {
      context.push(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkoutViewModel>();
    final hasActiveWorkout = viewModel.hasActiveWorkout;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 32),
              _QuickActions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: hasActiveWorkout
          ? _ResumeWorkoutBar(viewModel: viewModel)
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'Routines',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_run_outlined),
                  activeIcon: Icon(Icons.directions_run),
                  label: 'Exercises',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Workout Tracker',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ResumeWorkoutBar extends StatelessWidget {
  final WorkoutViewModel viewModel;

  const _ResumeWorkoutBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final routineId = viewModel.session!.routineId;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/workout?routineId=$routineId'),
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            'Resume Workout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkoutViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard(
              context,
              icon: Icons.play_arrow,
              label: 'Start Workout',
              color: const Color(0xFF667EEA),
              onTap: () => context.push('/routine'),
              enabled: !viewModel.hasActiveWorkout,
            ),
            const SizedBox(width: 12),
            _actionCard(
              context,
              icon: Icons.add_circle,
              label: 'Create Routine',
              color: const Color(0xFF667EEA),
              onTap: () => context.push('/routine/new'),
              enabled: true,
            ),

          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? color : theme.colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
