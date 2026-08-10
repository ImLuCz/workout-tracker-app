import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker_app/domain/models/routine_exercise.dart';
import 'package:workout_tracker_app/domain/models/workout_routine.dart';
import 'package:workout_tracker_app/domain/models/exercise.dart';

import '../../data/repositories/routine_repository.dart';

/// Manages routine creation, editing, and exercise selection.
class RoutineViewModel extends ChangeNotifier {
  RoutineViewModel({required RoutineRepository repository})
      : _repository = repository;

  final RoutineRepository _repository;
  final _uuid = const Uuid();

  List<RoutineExercise> _exercises = [];
  List<RoutineExercise> get exercises => _exercises;

  List<WorkoutRoutine> _routines = [];
  List<WorkoutRoutine> get routines => _routines;

  String _name = '';
  String get name => _name;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _editingId;
  String? get editingId => _editingId;

  Future<List<WorkoutRoutine>> loadRoutines() async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      _routines = await _repository.getAllRoutines();
      return _routines;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void startEdit(WorkoutRoutine routine) {
    _editingId = routine.id;
    _name = routine.name;
    _exercises = List<RoutineExercise>.from(routine.exercises);
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void addExercise(Exercise exercise, {int restSeconds = 90, int setsCount = 3}) {
    _exercises.add(RoutineExercise(
      id: _uuid.v4(),
      exercise: exercise,
      order: _exercises.length,
      restSeconds: restSeconds,
      setsCount: setsCount,
    ));
    notifyListeners();
  }

  void removeExercise(String exerciseId) {
    _exercises.removeWhere((e) => e.id == exerciseId);
    _reorder();
    notifyListeners();
  }

  void moveExercise(int from, int to) {
    if (from < 0 || to < 0 || from >= _exercises.length || to >= _exercises.length) return;
    final item = _exercises.removeAt(from);
    _exercises.insert(to, item);
    _reorder();
    notifyListeners();
  }

  void updateExerciseRestSeconds(String exerciseId, int restSeconds) {
    _exercises = _exercises.map((e) {
      if (e.id == exerciseId) {
        return e.copyWith(restSeconds: restSeconds);
      }
      return e;
    }).toList();
    notifyListeners();
  }

  void updateExerciseSetsCount(String exerciseId, int setsCount) {
    _exercises = _exercises.map((e) {
      if (e.id == exerciseId) {
        return e.copyWith(setsCount: setsCount);
      }
      return e;
    }).toList();
    notifyListeners();
  }

  void _reorder() {
    _exercises = _exercises
        .map((e) => e.copyWith(order: _exercises.indexOf(e)))
        .toList();
  }

  Future<String?> save() async {
    if (_name.trim().isEmpty) return null;
    final routine = WorkoutRoutine(
      id: _editingId ?? _uuid.v4(),
      name: _name.trim(),
      exercises: _exercises,
      createdAt: _editingId != null
          ? (_repository.getRoutine(_editingId!)?.createdAt ?? DateTime.now())
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveRoutine(routine);
    _exercises = [];
    _name = '';
    _editingId = null;
    await loadRoutines();
    notifyListeners();
    return routine.id;
  }

  Future<void> delete(String id) async {
    await _repository.deleteRoutine(id);
    await loadRoutines();
  }
}
