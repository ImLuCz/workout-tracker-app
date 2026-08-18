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

enum _NavTab {
  home,
  routines,
  exercises,
  stats;

  static const _values = <_NavTab>[home, routines, exercises, stats];

  static int _index(_NavTab tab) => _values.indexWhere((e) => e == tab);

  static _NavTab? fromLocation(String location) {
    if (location == '/' || location.startsWith('/workout') || location.startsWith('/history')) {
      return _NavTab.home;
    }
    if (location.startsWith('/routine')) return _NavTab.routines;
    if (location.startsWith('/exercise')) return _NavTab.exercises;
    if (location.startsWith('/stats')) return _NavTab.stats;
    return null;
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return _NavScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'exercise',
              builder: (context, state) => const ExerciseManagerScreen(),
            ),
            GoRoute(
              path: 'routine',
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
            GoRoute(
              path: 'workout',
              builder: (context, state) {
                final routineId = state.uri.queryParameters['routineId'] ?? '';
                return WorkoutActiveScreen(routineId: routineId);
              },
            ),
            GoRoute(
              path: 'stats',
              builder: (context, state) => const StatsScreen(),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => const WorkoutHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _NavScaffold extends StatefulWidget {
  final Widget child;
  const _NavScaffold({required this.child});

  @override
  State<_NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<_NavScaffold> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndex();
  }

  void _updateIndex() {
    final location = GoRouterState.of(context).uri.path;
    final tab = _NavTab.fromLocation(location);
    final index = tab != null ? _NavTab._index(tab) : 0;
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTabTapped(int index) {
    final routes = <String>['/', '/routine', '/exercise', '/stats'];
    context.push(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkoutViewModel>();
    final hasActiveWorkout = viewModel.hasActiveWorkout;

    return Scaffold(
      body: widget.child,
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
