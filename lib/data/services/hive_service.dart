import 'package:hive_flutter/hive_flutter.dart';

/// Hive box keys for data persistence.
class HiveBoxKeys {
  static const String exercises = 'exercises';
  static const String routines = 'routines';
  static const String sessions = 'sessions';
}

/// Manages Hive box initialization.
class HiveService {
  static late Box<dynamic> _routinesBox;
  static late Box<dynamic> _sessionsBox;
  static late Box<dynamic> _customExercisesBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _routinesBox = await Hive.openBox<dynamic>('routines');
    _sessionsBox = await Hive.openBox<dynamic>('sessions');
    _customExercisesBox = await Hive.openBox<dynamic>('custom_exercises');
  }

  static Box<dynamic> get routinesBox => _routinesBox;
  static Box<dynamic> get sessionsBox => _sessionsBox;
  static Box<dynamic> get customExercisesBox => _customExercisesBox;
}
