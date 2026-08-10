/// Represents a single exercise in the database.
class Exercise {
  final String id;
  final String name;
  final String category;
  final String? description;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
  });

  Exercise copyWith({String? name, String? category, String? description}) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}
