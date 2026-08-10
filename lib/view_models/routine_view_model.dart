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

  Future<List<WorkoutRoutine>> loadRoutines() async {
    _isLoading = true;
    notifyListeners();
    try {
      _routines = await _repository.getAllRoutines();
      return _routines;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void addExercise(Exercise exercise) {
    _exercises.add(RoutineExercise(
      id: _uuid.v4(),
      exercise: exercise,
      order: _exercises.length,
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

  void _reorder() {
    _exercises = _exercises
        .map((e) => e.copyWith(order: _exercises.indexOf(e)))
        .toList();
  }

  Future<String?> save() async {
    if (_name.trim().isEmpty) return null;
    final routine = WorkoutRoutine(
      id: _uuid.v4(),
      name: _name.trim(),
      exercises: _exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveRoutine(routine);
    _exercises = [];
    _name = '';
    await loadRoutines();
    notifyListeners();
    return routine.id;
  }

  Future<void> delete(String id) async {
    await _repository.deleteRoutine(id);
    await loadRoutines();
  }
}
