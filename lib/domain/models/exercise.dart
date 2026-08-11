/// Represents a single exercise from the WorkoutDB API.
class Exercise {
  final String id;
  final String name;
  final String category; // e.g. "Chest", "Back", "Quads"
  final String? description;
  final String? equipment; // e.g. "barbell", "dumbbell", "body weight"
  final String? target; // e.g. "pectorals"
  final List<String>? secondaryMuscles;
  final List<String>? instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.equipment,
    this.target,
    this.secondaryMuscles,
    this.instructions,
  });

  Exercise copyWith({
    String? name,
    String? category,
    String? description,
    String? equipment,
    String? target,
    List<String>? secondaryMuscles,
    List<String>? instructions,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      target: target ?? this.target,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
    );
  }

  /// Serialises to JSON for local caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'equipment': equipment,
      'target': target,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
    };
  }

  /// Deserialises from JSON (used by the cache).
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'strength',
      description: json['description'] as String?,
      equipment: json['equipment'] as String?,
      target: json['target'] as String?,
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
