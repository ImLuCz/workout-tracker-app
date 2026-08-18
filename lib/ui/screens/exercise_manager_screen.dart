import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_app/constants/muscles.dart';
import 'package:workout_tracker_app/data/repositories/custom_exercise_repository.dart';
import 'package:workout_tracker_app/domain/models/custom_exercise.dart';

class ExerciseManagerScreen extends StatefulWidget {
  const ExerciseManagerScreen({super.key});

  @override
  State<ExerciseManagerScreen> createState() => _ExerciseManagerScreenState();
}

class _ExerciseManagerScreenState extends State<ExerciseManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<CustomExercise> _getFilteredExercises(List<CustomExercise> all) {
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((e) {
      return e.name.toLowerCase().contains(query) ||
          e.primaryMuscles.any((m) => m.toLowerCase().contains(query)) ||
          e.equipment.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteExercise(CustomExercise exercise) async {
    final repo = context.read<CustomExerciseRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await repo.deleteExercise(exercise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Manager'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Exercises'),
            Tab(text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyExercisesTab(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onFilteredExercises: _getFilteredExercises,
            onDelete: _deleteExercise,
          ),
          const _CreateExerciseTab(),
        ],
      ),
    );
  }
}

class _MyExercisesTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<CustomExercise> Function(List<CustomExercise>) onFilteredExercises;
  final Future<void> Function(CustomExercise) onDelete;

  const _MyExercisesTab({
    required this.searchController,
    required this.searchQuery,
    required this.onFilteredExercises,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomExercise>>(
      future: context.read<CustomExerciseRepository>().getAllExercises(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final exercises = snapshot.data ?? [];
        final filtered = onFilteredExercises(exercises);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ExerciseCard(
                            exercise: exercise,
                            onDelete: () => onDelete(exercise),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CreateExerciseTab extends StatefulWidget {
  const _CreateExerciseTab();

  @override
  State<_CreateExerciseTab> createState() => _CreateExerciseTabState();
}

class _CreateExerciseTabState extends State<_CreateExerciseTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  final Set<String> _selectedPrimaryMuscles = {};
  final Set<String> _selectedSecondaryMuscles = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPrimaryMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one primary muscle')),
      );
      return;
    }

    setState(() => _saving = true);

    final repository = context.read<CustomExerciseRepository>();
    final exercise = CustomExercise(
      id: repository.generateId(),
      name: _nameController.text.trim(),
      primaryMuscles: _selectedPrimaryMuscles.toList(),
      secondaryMuscles: _selectedSecondaryMuscles.toList(),
      equipment: _equipmentController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.saveExercise(exercise);

    if (mounted) {
      setState(() {
        _nameController.clear();
        _equipmentController.clear();
        _selectedPrimaryMuscles.clear();
        _selectedSecondaryMuscles.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise "${exercise.name}" created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => _saving = false);
  }

  Widget _muscleChipSection(
    String label,
    Set<String> selected,
    ValueChanged<Set<String>> onChanged,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        InkWell(
          onTap: () => _showMuscleSelector(
            context,
            label,
            selected,
            onChanged,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.inputDecorationTheme.border!.borderSide.color),
              borderRadius: BorderRadius.circular(12),
              color: theme.inputDecorationTheme.fillColor,
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                if (selected.isEmpty) ...[
                  Text(
                    'Select muscles...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: selected.map((muscle) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: FilterChip(
                              label: Text(muscle),
                              selected: false,
                              onSelected: null,
                              selectedColor: theme.colorScheme.primaryContainer,
                              checkmarkColor: theme.colorScheme.onPrimaryContainer,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMuscleSelector(
    BuildContext context,
    String title,
    Set<String> selected,
    ValueChanged<Set<String>> onChanged,
  ) {
    final controller = TextEditingController(text: '');
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search muscles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setModalState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: allMuscles
                        .where((muscle) => muscle
                            .toLowerCase()
                            .contains(controller.text.toLowerCase()))
                        .map((muscle) {
                      final isSelected = selected.contains(muscle);
                      return ListTile(
                        title: Text(muscle),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer,
                        onTap: () {
                          final result = Set<String>.from(selected);
                          if (isSelected) {
                            result.remove(muscle);
                          } else {
                            result.add(muscle);
                          }
                          onChanged(result);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Custom Barbell Curl',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Exercise name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _muscleChipSection(
              'Primary Muscles *',
              _selectedPrimaryMuscles,
              (value) => setState(() {
                    _selectedPrimaryMuscles.clear();
                    _selectedPrimaryMuscles.addAll(value);
                  }),
            ),
            const SizedBox(height: 16),
            _muscleChipSection(
              'Secondary Muscles',
              _selectedSecondaryMuscles,
              (value) => setState(() {
                    _selectedSecondaryMuscles.clear();
                    _selectedSecondaryMuscles.addAll(value);
                  }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _equipmentController,
              decoration: const InputDecoration(
                labelText: 'Equipment',
                hintText: 'e.g., Barbell, Dumbbell',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No custom exercises yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switch to "Create New" tab to add your first exercise',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final CustomExercise exercise;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
  });

  Widget _muscleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...exercise.primaryMuscles.map(
                        (m) => _muscleTag(m, theme.colorScheme.primary),
                      ),
                      if (exercise.equipment.isNotEmpty)
                        ...exercise.equipment.split(',').map(
                          (e) => _muscleTag(e.trim(), theme.colorScheme.tertiary),
                        ),
                    ],
                  ),
                  if (exercise.secondaryMuscles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Also: ${exercise.secondaryMuscles.join(', ')}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
