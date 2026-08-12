# Workout Tracker — Agent Guide

## Overview

A Flutter workout tracking app for logging routines, exercises, and workout sessions.
Data is persisted locally with **Hive**. State is managed with **Provider** (ChangeNotifier).
Navigation is handled by **GoRouter**.

---

## Architecture

```
lib/
  main.dart                  # App entry point, Provider setup, Hive init
  navigation/
    router.dart              # GoRouter configuration
  ui/
    core/
      theme.dart             # Light/dark ThemeData
    screens/                 # Top-level screens (Stateless or Stateful)
  view_models/               # ChangeNotifier providers (MVVM view models)
  domain/
    models/                  # Plain data classes (immutability, copyWith)
  data/
    repositories/            # CRUD over Hive boxes
    services/
      hive_service.dart      # Hive box initialization & accessors
  constants/
    muscles.dart             # Shared muscle group list
```

### Layer responsibilities

| Layer | What lives here |
|---|---|
| `domain/models` | Immutable data classes, `copyWith`, `fromJson`/`toJson` |
| `data/repositories` | Hive read/write, JSON serialisation of entities |
| `data/services` | Cross-cutting concerns (Hive init) |
| `view_models` | `ChangeNotifier` subclasses that own app state |
| `ui/screens` | Presentation-only widgets, no business logic |
| `navigation` | Declarative route table |

---

## State Management

- **App state** → `ChangeNotifier` subclasses in `view_models/`, exposed via `ChangeNotifierProvider`.
- **Data services** (repositories) → `Provider` (non-listening) in `main.dart`.
- **Ephemeral UI state** → local `State` classes (`setState`).

ViewModels are wired in `main.dart` inside `MultiProvider`:

```dart
ChangeNotifierProvider(create: (context) => RoutineViewModel(repository: context.read<RoutineRepository>())),
```

Screens read view models with `context.watch<ViewModel>()` or `context.read<ViewModel>()`.

---

## Data Layer

### Hive Boxes

Three boxes are opened at app start in `HiveService.init()`:

| Box name | Key type | Value type | Contents |
|---|---|---|---|
| `routines` | `String` (id) | `String` (JSON) | `WorkoutRoutine` |
| `sessions` | `String` (id) | `String` (JSON) | `WorkoutSession` |
| `custom_exercises` | `String` (id) | `String` (JSON) | `CustomExercise` |

Values are JSON-encoded strings. Repositories handle encoding/decoding.

### Repository pattern

Each entity has a dedicated repository (`RoutineRepository`, `SessionRepository`, `CustomExerciseRepository`) with:

- `getAll*()` → `Future<List<T>>`
- `get*()` → `T?`
- `save*()` → `Future<void>`
- `delete*()` → `Future<void>`

---

## Domain Models

All models are **immutable** with `const` constructors and `copyWith` methods.

| Model | Key fields |
|---|---|
| `Exercise` | `id`, `name`, `category`, `description`, `equipment`, `target`, `secondaryMuscles`, `instructions` |
| `RoutineExercise` | `id`, `exercise`, `order`, `restSeconds`, `setsCount` |
| `WorkoutRoutine` | `id`, `name`, `exercises`, `createdAt`, `updatedAt` |
| `WorkoutSet` | `id`, `weightKg`, `reps`, `completed`, `completedAt` |
| `SessionExercise` | `routineExercise`, `sets`, `restSeconds`, `primaryMuscles`, `secondaryMuscles` |
| `WorkoutSession` | `id`, `routineId`, `routineName`, `startTime`, `endTime`, `exercises` |
| `CustomExercise` | `id`, `name`, `primaryMuscles`, `secondaryMuscles`, `equipment`, `createdAt`, `updatedAt` |
| `WorkoutStats` | `totalVolumeKg`, `totalSessions`, `totalSets`, `totalCompletedSets`, `sessionStats` |
| `SessionStat` | `date`, `routineName`, `volumeKg`, `completedSets`, `totalSets`, `duration` |
| `MuscleStats` | `muscleName`, `totalWorkouts`, `totalSets`, `completedSets`, `totalVolumeKg`, `heaviestWeightKg` |
| `WeeklyMuscleStats` | `muscleName`, `totalSetsThisWeek`, `totalVolumeKgThisWeek` |

### Model conventions

- Use `const` constructors where possible.
- All fields are `final`.
- Provide `copyWith` for any class whose instances are mutated indirectly.
- `fromJson`/`toJson` only where data crosses the persistence boundary (repositories and `CustomExercise`).

---

## Routing

Defined in `lib/navigation/router.dart` using `GoRouter`:

```
/                       → HomeScreen
  /exercise             → ExerciseManagerScreen
  /routine              → RoutineListScreen
  /routine?id=<id>      → RoutineDetailScreen(routineId)
  /routine/new          → RoutineBuilderScreen(routineId: null)
  /routine/new?editId=<id> → RoutineBuilderScreen(routineId: editId)
  /workout?routineId=<id> → WorkoutActiveScreen(routineId)
  /stats                → StatsScreen
  /history              → WorkoutHistoryScreen
```

- Query parameters are used for passing IDs (e.g. `?routineId=xxx`).
- Short-lived screens (active workout) use `Navigator.push` with `MaterialPageRoute` instead of GoRouter where appropriate.

---

## Theming

Theme is defined in `lib/ui/core/theme.dart` as two `ThemeData` objects (`lightTheme` / `darkTheme`).

- Seed color: `#4A5568` (slate grey) for light, `#667EEA` (periwinkle) for dark accent buttons.
- Scaffold background: `#F8F9FA` (light) / `#1A1A2E` (dark).
- Cards: flat (elevation 0), 12px rounded corners, subtle border.
- Font: `'Inter'`.
- `themeMode: ThemeMode.system` — follows OS setting.

---

## Conventions for New Code

### File naming
- `snake_case` for all files and directories.
- One top-level class per file unless classes are tightly coupled private helpers.

### Class naming
- `PascalCase` for classes.
- Private implementation classes use `_` prefix (e.g. `_ExerciseCard`).

### Widgets
- Prefer `StatelessWidget` unless state is needed.
- Break large `build()` methods into small private widget classes.
- Use `const` constructors wherever possible.

### ViewModels
- Extend `ChangeNotifier`.
- Private state fields with public getters (no setters).
- Call `notifyListeners()` after every state mutation.
- Use `WidgetsBinding.instance.addPostFrameCallback` for one-off async work that needs to notify after the first frame.

### Async / error handling
- Use `try/catch/finally` with `notifyListeners()` in `finally`.
- Repository methods swallow parse errors silently (`catch (_)`) — data integrity is assumed at the repository boundary.

### Immutability
- Never mutate a model directly; always use `copyWith` to produce a new instance.
- ViewModels should replace (not mutate) their internal lists/maps.

### UI patterns
- Empty states: show a centered icon + text when lists are empty.
- Lists: use `ListView.builder` for long lists.
- Bottom sheets: use `showModalBottomSheet` with `isScrollControlled: true` and account for keyboard insets.
- Confirmations: use `showDialog` with `AlertDialog` for destructive actions.

### Input fields
- Use `FilteringTextInputFormatter` for numeric inputs (`digitsOnly` or `RegExp(r'^\d*\.?\d*')`).
- Handle `onEditingComplete` and `onTapOutside` to commit values.
- Sync `TextEditingController` in `didUpdateWidget` when the model changes externally.

### Testing
- Widget tests live in `test/` (use `flutter test`).
- Use `package:checks` for assertions when available (see `dart-migrate-to-checks-package` skill).
- Follow Arrange-Act-Assert pattern.

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management & DI |
| `go_router` | Declarative routing |
| `hive` / `hive_flutter` | Local persistence |
| `fl_chart` | Charts (stats screen) |
| `intl` | Date/time formatting |
| `uuid` | ID generation |
| `collection` | Collection utilities |

---

## Common Tasks

### Adding a new screen
1. Create `lib/ui/screens/<screen_name>_screen.dart`.
2. Add route in `lib/navigation/router.dart`.
3. Add navigation call (e.g. `context.push('/path')`) from an existing screen.

### Adding a new model
1. Create the model in `lib/domain/models/`.
2. Add repository methods in `lib/data/repositories/`.
3. Open a new Hive box in `HiveService` if the data is new.
4. Add a `Provider` entry in `main.dart` if the repository needs injection.

### Adding a new view model
1. Create `lib/view_models/<name>_view_model.dart` extending `ChangeNotifier`.
2. Add a `ChangeNotifierProvider` in `main.dart`.
3. Use `context.watch<ViewModel>()` or `context.read<ViewModel>()` in screens.

### Migrating existing code to modern Dart
- Use `dart-use-pattern-matching` skill for `switch` expressions.
- Use `dart-use-primary-constructors` skill for constructor simplification.
- Use `dart-migrate-to-checks-package` skill for assertion modernisation.
