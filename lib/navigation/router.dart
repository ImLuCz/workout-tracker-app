import 'package:go_router/go_router.dart';
import 'package:workout_tracker_app/ui/screens/exercise_list_screen.dart';
import 'package:workout_tracker_app/ui/screens/home_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_builder_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_detail_screen.dart';
import 'package:workout_tracker_app/ui/screens/routine_list_screen.dart';
import 'package:workout_tracker_app/ui/screens/stats_screen.dart';
import 'package:workout_tracker_app/ui/screens/workout_active_screen.dart';
import 'package:workout_tracker_app/ui/screens/workout_history_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'exercise',
          builder: (context, state) => const ExerciseListScreen(),
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
);
