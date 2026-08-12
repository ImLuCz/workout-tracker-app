import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';
import 'package:workout_tracker_app/data/repositories/routine_repository.dart';
import 'package:workout_tracker_app/data/repositories/session_repository.dart';
import 'package:workout_tracker_app/data/services/hive_service.dart';
import 'package:workout_tracker_app/navigation/router.dart';
import 'package:workout_tracker_app/ui/core/theme.dart';
import 'package:workout_tracker_app/view_models/routine_view_model.dart';
import 'package:workout_tracker_app/view_models/stats_view_model.dart';
import 'package:workout_tracker_app/view_models/workout_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RoutineRepository>(
          create: (_) => RoutineRepository(),
        ),
        Provider<SessionRepository>(
          create: (_) => SessionRepository(),
        ),
        Provider<CustomExerciseRepository>(
          create: (_) => CustomExerciseRepository(),
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
            final vm = StatsViewModel(
              repository: context.read<SessionRepository>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => vm.loadStats());
            return vm;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Workout Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
