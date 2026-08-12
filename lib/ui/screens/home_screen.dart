import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkoutViewModel>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(
          context,
          Icons.fitness_center,
          'Workout',
          viewModel.hasActiveWorkout ? '/workout?routineId=active' : null,
          viewModel.hasActiveWorkout,
        ),
        _navItem(context, Icons.book, 'Routines', '/routine', false),
        _navItem(context, Icons.directions_run, 'Exercises', '/exercise', false),
        _navItem(context, Icons.bar_chart, 'Stats', '/stats', false),
      ],
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: route != null ? () => context.push(route) : null,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.cardTheme.color ?? theme.hoverColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : theme.colorScheme.onSurface,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
              color: const Color(0xFF4A5568),
              onTap: () => context.push('/exercise'),
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
