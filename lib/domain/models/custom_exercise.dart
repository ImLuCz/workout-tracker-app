/// Represents a custom exercise created by the user.
class CustomExercise {
  final String id;
  final String name;
  final String? description;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String? referencePicturePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomExercise({
    required this.id,
    required this.name,
    this.description,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    this.referencePicturePath,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomExercise copyWith({
    String? name,
    String? description,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    String? equipment,
    String? referencePicturePath,
  }) {
    return CustomExercise(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      referencePicturePath: referencePicturePath ?? this.referencePicturePath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryMuscles': primaryMuscles.join(', '),
      'secondaryMuscles': secondaryMuscles.join(', '),
      'equipment': equipment,
      'referencePicturePath': referencePicturePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomExercise.fromJson(Map<String, dynamic> data) {
    // Handle both old String format and new List format
    dynamic pm = data['primaryMuscles'];
    List<String> parsedPrimary;
    if (pm is List) {
      parsedPrimary = pm.map((e) => (e as String).trim()).where((s) => s.isNotEmpty).toList();
    } else if (pm is String) {
      parsedPrimary = pm.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else {
      parsedPrimary = [];
    }

    dynamic sm = data['secondaryMuscles'];
    List<String> parsedSecondary;
    if (sm is List) {
      parsedSecondary = sm.map((e) => (e as String).trim()).where((s) => s.isNotEmpty).toList();
    } else if (sm is String) {
      parsedSecondary = sm.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else {
      parsedSecondary = [];
    }

    return CustomExercise(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      primaryMuscles: parsedPrimary,
      secondaryMuscles: parsedSecondary,
      equipment: data['equipment'] as String? ?? '',
      referencePicturePath: data['referencePicturePath'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}

/// Stats tracked for a custom exercise.
class CustomExerciseStats {
  final int totalWorkouts;
  final double totalVolumeKg;
  final double personalBestKg;

  const CustomExerciseStats({
    required this.totalWorkouts,
    required this.totalVolumeKg,
    required this.personalBestKg,
  });

  factory CustomExerciseStats.empty() =>
      const CustomExerciseStats(totalWorkouts: 0, totalVolumeKg: 0.0, personalBestKg: 0.0);
}
