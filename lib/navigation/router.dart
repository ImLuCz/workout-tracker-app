import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/ui/screens/exercise_manager_screen.dart';
import 'package:workout_tracker_app/ui/screens/home_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_builder_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_detail_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_list_screen.dart';
import 'package:workout_tracker_app/ui/screens/stats_screen.dart';
import 'package:workout_tracker_app/ui/screens/workout_active_screen.dart';
import 'package:workout_tracker_app/ui/screens/workout_history_screen.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

/// Routes are grouped into four branches, one per bottom-nav destination.
/// Each branch keeps its own [Navigator], so switching tabs preserves the
/// state of the screens underneath (scroll offsets, half-typed text, the
/// selected muscle filter) instead of rebuilding them.
///
/// Expanded paths, all unique: `/`, `/workout`, `/history`, `/routine`,
/// `/routine/new`, `/exercise`, `/stats`.
final GoRouter router = GoRouter(
  initialLocation: '/',
  // go_router matches paths case-sensitively by default and exposes no
  // caseSensitive option. Every route path and every navigation call site in
  // this app is lowercase, so /Stats correctly falls through to errorBuilder
  // instead of resolving to the stats tab.
  errorBuilder: (context, state) => const _RouteNotFoundScreen(),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _NavScaffold(navigationShell: navigationShell),
      branches: [
        // 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'workout',
                  builder: (context, state) {
                    final routineId = state.uri.queryParameters['routineId'] ?? '';
                    return WorkoutActiveScreen(routineId: routineId);
                  },
                ),
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const WorkoutHistoryScreen(),
                ),
              ],
            ),
          ],
        ),
        // 1 — Routines
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/routine',
              builder: (context, state) {
                final id = state.uri.queryParameters['id'];
                return id == null
                    ? const RoutineListScreen()
                    : RoutineDetailScreen(routineId: id);
              },
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) {
                    final editId = state.uri.queryParameters['editId'];
                    return RoutineBuilderScreen(routineId: editId);
                  },
                ),
              ],
            ),
          ],
        ),
        // 2 — Exercises
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exercise',
              builder: (context, state) => const ExerciseManagerScreen(),
            ),
          ],
        ),
        // 3 — Stats
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _NavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _NavScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // Select rather than watch: WorkoutViewModel notifies once a second while
    // the rest timer runs, and the shell only needs this one boolean.
    final hasActiveWorkout =
        context.select<WorkoutViewModel, bool>((vm) => vm.hasActiveWorkout);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hasActiveWorkout
          ? const _ResumeWorkoutBar()
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.book_outlined),
                  selectedIcon: Icon(Icons.book),
                  label: 'Routines',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_run_outlined),
                  selectedIcon: Icon(Icons.directions_run),
                  label: 'Exercises',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
              ],
            ),
    );
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'This page does not exist',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeWorkoutBar extends StatelessWidget {
  const _ResumeWorkoutBar();

  @override
  Widget build(BuildContext context) {
    // Narrow select on the id only — the shell already decided there is an
    // active session, so this only re-renders when the session changes.
    final routineId = context.select<WorkoutViewModel, String?>(
      (vm) => vm.session?.routineId,
    );
    if (routineId == null) return const SizedBox.shrink();

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
