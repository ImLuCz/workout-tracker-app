import 'package:workout_tracker_app/domain/models/exercise.dart';

/// Pre-populated exercise database with ~100 exercises.
final List<Exercise> exerciseDatabase = [
  // Chest
  Exercise(id: 'c1', name: 'Barbell Bench Press', category: 'Chest'),
  Exercise(id: 'c2', name: 'Incline Barbell Bench Press', category: 'Chest'),
  Exercise(id: 'c3', name: 'Decline Barbell Bench Press', category: 'Chest'),
  Exercise(id: 'c4', name: 'Dumbbell Bench Press', category: 'Chest'),
  Exercise(id: 'c5', name: 'Incline Dumbbell Bench Press', category: 'Chest'),
  Exercise(id: 'c6', name: 'Dumbbell Fly', category: 'Chest'),
  Exercise(id: 'c7', name: 'Cable Fly', category: 'Chest'),
  Exercise(id: 'c8', name: 'Chest Push-Up', category: 'Chest'),
  Exercise(id: 'c9', name: 'Decline Push-Up', category: 'Chest'),
  Exercise(id: 'c10', name: 'Close-Grip Bench Press', category: 'Chest'),
  Exercise(id: 'c11', name: 'Weighted Chest Push-Up', category: 'Chest'),
  Exercise(id: 'c12', name: 'Machine Chest Press', category: 'Chest'),
  Exercise(id: 'c13', name: 'Cable Crossover', category: 'Chest'),
  Exercise(id: 'c14', name: 'Pec Deck', category: 'Chest'),
  Exercise(id: 'c15', name: 'Landmine Press', category: 'Chest'),

  // Back
  Exercise(id: 'b1', name: 'Pull-Up', category: 'Back'),
  Exercise(id: 'b2', name: 'Chin-Up', category: 'Back'),
  Exercise(id: 'b3', name: 'Barbell Row', category: 'Back'),
  Exercise(id: 'b4', name: 'Inverted Row', category: 'Back'),
  Exercise(id: 'b5', name: 'Dumbbell Row', category: 'Back'),
  Exercise(id: 'b6', name: 'Lat Pulldown', category: 'Back'),
  Exercise(id: 'b7', name: 'Seated Cable Row', category: 'Back'),
  Exercise(id: 'b8', name: 'T-Bar Row', category: 'Back'),
  Exercise(id: 'b9', name: 'Straight-Arm Pulldown', category: 'Back'),
  Exercise(id: 'b10', name: 'Face Pull', category: 'Back'),
  Exercise(id: 'b11', name: 'Single-Arm Dumbbell Row', category: 'Back'),
  Exercise(id: 'b12', name: 'Close-Grip Lat Pulldown', category: 'Back'),
  Exercise(id: 'b13', name: 'Machine Row', category: 'Back'),
  Exercise(id: 'b14', name: 'Chest-Supported Row', category: 'Back'),
  Exercise(id: 'b15', name: 'Deadlift', category: 'Back'),

  // Shoulders
  Exercise(id: 's1', name: 'Overhead Press', category: 'Shoulders'),
  Exercise(id: 's2', name: 'Military Press', category: 'Shoulders'),
  Exercise(id: 's3', name: 'Arnold Press', category: 'Shoulders'),
  Exercise(id: 's4', name: 'Lateral Raise', category: 'Shoulders'),
  Exercise(id: 's5', name: 'Front Raise', category: 'Shoulders'),
  Exercise(id: 's6', name: 'Reverse Fly', category: 'Shoulders'),
  Exercise(id: 's7', name: 'Upright Row', category: 'Shoulders'),
  Exercise(id: 's8', name: 'Shrugs', category: 'Shoulders'),
  Exercise(id: 's9', name: 'Pike Push-Up', category: 'Shoulders'),
  Exercise(id: 's10', name: 'Handstand Push-Up', category: 'Shoulders'),
  Exercise(id: 's11', name: 'Dumbbell Shoulder Press', category: 'Shoulders'),
  Exercise(id: 's12', name: 'Machine Shoulder Press', category: 'Shoulders'),
  Exercise(id: 's13', name: 'Cable Lateral Raise', category: 'Shoulders'),
  Exercise(id: 's14', name: 'Behind-Head Press', category: 'Shoulders'),

  // Biceps
  Exercise(id: 'bi1', name: 'Barbell Curl', category: 'Biceps'),
  Exercise(id: 'bi2', name: 'Dumbbell Curl', category: 'Biceps'),
  Exercise(id: 'bi3', name: 'Hammer Curl', category: 'Biceps'),
  Exercise(id: 'bi4', name: 'Preacher Curl', category: 'Biceps'),
  Exercise(id: 'bi5', name: 'Cable Curl', category: 'Biceps'),
  Exercise(id: 'bi6', name: 'Concentration Curl', category: 'Biceps'),
  Exercise(id: 'bi7', name: 'Chin-Up', category: 'Biceps'),
  Exercise(id: 'bi8', name: 'Incline Dumbbell Curl', category: 'Biceps'),
  Exercise(id: 'bi9', name: 'Spider Curl', category: 'Biceps'),
  Exercise(id: 'bi10', name: 'EZ-Bar Curl', category: 'Biceps'),
  Exercise(id: 'bi11', name: 'Cross-Body Hammer Curl', category: 'Biceps'),

  // Triceps
  Exercise(id: 'tr1', name: 'Triceps Pushdown', category: 'Triceps'),
  Exercise(id: 'tr2', name: 'Overhead Triceps Extension', category: 'Triceps'),
  Exercise(id: 'tr3', name: 'Skull Crusher', category: 'Triceps'),
  Exercise(id: 'tr4', name: 'Dips', category: 'Triceps'),
  Exercise(id: 'tr5', name: 'Close-Grip Bench Press', category: 'Triceps'),
  Exercise(id: 'tr6', name: 'Diamond Push-Up', category: 'Triceps'),
  Exercise(id: 'tr7', name: 'Triceps Kickback', category: 'Triceps'),
  Exercise(id: 'tr8', name: 'Overhead Dumbbell Extension', category: 'Triceps'),
  Exercise(id: 'tr9', name: 'JM Press', category: 'Triceps'),
  Exercise(id: 'tr10', name: 'Machine Triceps Extension', category: 'Triceps'),

  // Legs - Quads
  Exercise(id: 'q1', name: 'Barbell Squat', category: 'Quads'),
  Exercise(id: 'q2', name: 'Front Squat', category: 'Quads'),
  Exercise(id: 'q3', name: 'Goblet Squat', category: 'Quads'),
  Exercise(id: 'q4', name: 'Leg Press', category: 'Quads'),
  Exercise(id: 'q5', name: 'Bulgarian Split Squat', category: 'Quads'),
  Exercise(id: 'q6', name: 'Lunge', category: 'Quads'),
  Exercise(id: 'q7', name: 'Walking Lunge', category: 'Quads'),
  Exercise(id: 'q8', name: 'Leg Extension', category: 'Quads'),
  Exercise(id: 'q9', name: 'Sissy Squat', category: 'Quads'),
  Exercise(id: 'q10', name: 'Hack Squat', category: 'Quads'),
  Exercise(id: 'q11', name: 'Wall Sit', category: 'Quads'),
  Exercise(id: 'q12', name: 'Jump Squat', category: 'Quads'),
  Exercise(id: 'q13', name: 'Step-Up', category: 'Quads'),

  // Legs - Hamstrings
  Exercise(id: 'h1', name: 'Romanian Deadlift', category: 'Hamstrings'),
  Exercise(id: 'h2', name: 'Leg Curl', category: 'Hamstrings'),
  Exercise(id: 'h3', name: 'Nordic Hamstring Curl', category: 'Hamstrings'),
  Exercise(id: 'h4', name: 'Stiff-Leg Deadlift', category: 'Hamstrings'),
  Exercise(id: 'h5', name: 'Good Morning', category: 'Hamstrings'),
  Exercise(id: 'h6', name: 'Single-Leg Romanian Deadlift', category: 'Hamstrings'),
  Exercise(id: 'h7', name: 'Glute-Ham Raise', category: 'Hamstrings'),
  Exercise(id: 'h8', name: 'Seated Leg Curl', category: 'Hamstrings'),

  // Legs - Glutes
  Exercise(id: 'g1', name: 'Hip Thrust', category: 'Glutes'),
  Exercise(id: 'g2', name: 'Glute Bridge', category: 'Glutes'),
  Exercise(id: 'g3', name: 'Cable Kickback', category: 'Glutes'),
  Exercise(id: 'g4', name: 'Sumo Squat', category: 'Glutes'),
  Exercise(id: 'g5', name: 'Bulgarian Split Squat', category: 'Glutes'),
  Exercise(id: 'g6', name: 'Step-Up', category: 'Glutes'),
  Exercise(id: 'g7', name: 'Donkey Kick', category: 'Glutes'),
  Exercise(id: 'g8', name: 'Fire Hydrant', category: 'Glutes'),

  // Legs - Calves
  Exercise(id: 'ca1', name: 'Standing Calf Raise', category: 'Calves'),
  Exercise(id: 'ca2', name: 'Seated Calf Raise', category: 'Calves'),
  Exercise(id: 'ca3', name: 'Leg Press Calf Raise', category: 'Calves'),
  Exercise(id: 'ca4', name: 'Single-Leg Calf Raise', category: 'Calves'),

  // Core
  Exercise(id: 'co1', name: 'Plank', category: 'Core'),
  Exercise(id: 'co2', name: 'Crunch', category: 'Core'),
  Exercise(id: 'co3', name: 'Sit-Up', category: 'Core'),
  Exercise(id: 'co4', name: 'Leg Raise', category: 'Core'),
  Exercise(id: 'co5', name: 'Dead Bug', category: 'Core'),
  Exercise(id: 'co6', name: 'Mountain Climber', category: 'Core'),
  Exercise(id: 'co7', name: 'Bicycle Crunch', category: 'Core'),
  Exercise(id: 'co8', name: 'Hanging Knee Raise', category: 'Core'),
  Exercise(id: 'co9', name: 'Ab Wheel Rollout', category: 'Core'),
  Exercise(id: 'co10', name: 'Cable Crunch', category: 'Core'),

  // Full Body / Compound
  Exercise(id: 'f1', name: 'Clean and Press', category: 'Full Body'),
  Exercise(id: 'f2', name: 'Snatch', category: 'Full Body'),
  Exercise(id: 'f3', name: 'Thruster', category: 'Full Body'),
  Exercise(id: 'f4', name: 'Turkish Get-Up', category: 'Full Body'),
  Exercise(id: 'f5', name: 'Squat to Press', category: 'Full Body'),
  Exercise(id: 'f6', name: 'Clean Pull', category: 'Full Body'),
];

/// Returns exercises matching the search query, case-insensitive.
List<Exercise> searchExercises(String query) {
  if (query.trim().isEmpty) return exerciseDatabase;
  final lower = query.toLowerCase();
  return exerciseDatabase
      .where((e) =>
          e.name.toLowerCase().contains(lower) ||
          e.category.toLowerCase().contains(lower))
      .toList();
}

/// Returns all unique categories.
List<String> getExerciseCategories() {
  final categories = <String>{};
  for (final e in exerciseDatabase) {
    categories.add(e.category);
  }
  return categories.toList()..sort();
}
