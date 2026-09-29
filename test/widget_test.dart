import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/data/repositories/session_repository.dart';
import 'package:workout_tracker_app/navigation/router.dart';
import 'package:workout_tracker_app/ui/screens/routine_list_screen.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';
import 'package:workout_tracker_app/view_models/stats_view_model.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

import 'helpers/stub_repositories.dart';

/// Mirrors the provider graph of `WorkoutApp` in `lib/main.dart`, but with the
/// stub repositories, so no test ever reaches for a `HiveService` box.
///
/// The real `router` global is used on purpose: it is the route table the app
/// ships with, so this also covers the shell/nav scaffold around each screen.
Widget _buildTestApp() {
  return MultiProvider(
    providers: [
      Provider<RoutineRepository>(create: (_) => StubRoutineRepository()),
      Provider<SessionRepository>(create: (_) => StubSessionRepository()),
      Provider<CustomExerciseRepository>(
        create: (_) => StubCustomExerciseRepository(),
      ),
      ChangeNotifierProvider(
        create: (context) => RoutineViewModel(
          repository: context.read<RoutineRepository>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => WorkoutViewModel(
          repository: context.read<SessionRepository>(),
          customExerciseRepository: context.read<CustomExerciseRepository>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) {
          final viewModel = StatsViewModel(
            repository: context.read<SessionRepository>(),
          );
          viewModel.loadStats();
          return viewModel;
        },
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('home screen renders over the stub repositories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // All four strings are read from lib/ui/screens/home_screen.dart.
    expect(find.text('Workout Tracker'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('Create Routine'), findsOneWidget);
  });

  testWidgets('bottom navigation switches to the routines tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // `router` is a global singleton that outlives a single mounted tree, so
    // the location is reset below to keep this test independent of its order.
    await tester.tapAt(tester.getCenter(find.text('Routines')));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineListScreen), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
  });
}
