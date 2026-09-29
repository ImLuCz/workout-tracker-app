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
    router.dart              # GoRouter config (StatefulShellRoute with a NavigationBar)
  ui/
    core/
      theme.dart             # Light/dark ThemeData (Material 3)
    screens/
      widgets/               # Reusable widget components for screens
      *_screen.dart          # Top-level screens (Stateless or Stateful)
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
ChangeNotifierProvider(create: (context) => WorkoutViewModel(repository: context.read<SessionRepository>(), customExerciseRepository: context.read<CustomExerciseRepository>())),
ChangeNotifierProvider(create: (context) => StatsViewModel(repository: context.read<SessionRepository>())),
```

`StatsViewModel.loadStats()` is called directly in its provider `create`.

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
- `clearAll()` → `Future<void>`

`SessionRepository` also provides `getLastCompletedSessionForRoutine()` (used to carry forward last weights/reps).

---

## Domain Models

All models are **immutable** with `const` constructors and `copyWith` methods.

| Model | Key fields |
|---|---|
| `Exercise` | `id`, `name`, `category`, `description?`, `equipment?`, `target?`, `secondaryMuscles?`, `instructions?` |
| `RoutineExercise` | `id`, `exercise`, `order`, `restSeconds`, `setsCount`; `copyWith` takes `exerciseId` (rebuilds a minimal `Exercise`) |
| `WorkoutRoutine` | `id`, `name`, `exercises`, `createdAt`, `updatedAt?` |
| `WorkoutSet` | `id`, `weightKg`, `reps`, `completed`, `completedAt?`, `isLogged` (getter) |
| `SessionExercise` | `routineExercise`, `sets`, `restSeconds`, `primaryMuscles`, `secondaryMuscles`, `totalWeight` (getter) |
| `WorkoutSession` | `id`, `routineId`, `routineName`, `startTime`, `endTime?`, `exercises`, `isFinished`/`totalVolume`/`totalSets`/`completedSets` (getters) |
| `CustomExercise` | `id`, `name`, `description?`, `primaryMuscles`, `secondaryMuscles`, `equipment`, `referencePicturePath?`, `createdAt`, `updatedAt` |
| `CustomExerciseStats` | `totalWorkouts`, `totalVolumeKg`, `personalBestKg`; `getStats()` returns empty until extended from sessions |
| `WorkoutStats` | `totalVolumeKg`, `totalSessions`, `totalSets`, `totalCompletedSets`, `sessionStats`, `avgVolumePerSession`/`completionRate` (getters) |
| `SessionStat` | `date`, `routineName`, `volumeKg`, `completedSets`, `totalSets`, `duration`, `fromSession` (factory) |
| `WeeklyMuscleStats` | `muscleName`, `totalSetsThisWeek`, `totalVolumeKgThisWeek` |

### Model conventions

- Use `const` constructors where possible.
- All fields are `final`.
- Provide `copyWith` for any class whose instances are mutated indirectly.
- `fromJson`/`toJson` only where data crosses the persistence boundary (repositories and `CustomExercise`).
- Nullable fields use `?` and default to sensible values in `fromJson`.

---

## Routing

Defined in `lib/navigation/router.dart` using `GoRouter` with a `StatefulShellRoute.indexedStack`
that wraps a Material 3 `NavigationBar` (or a resume workout bar when an active session exists).
Each tab is a `StatefulShellBranch` with its own `Navigator`, so switching tabs preserves the state
of the screens underneath.

Branch order (the index maps to the nav destinations): **0 Home, 1 Routines, 2 Exercises, 3 Stats**.

```
Branch 0 (Home)      /                            → HomeScreen
                       /workout?routineId=<id>     → WorkoutActiveScreen(routineId)
                       /history                    → WorkoutHistoryScreen
Branch 1 (Routines)  /routine                     → RoutineListScreen
                       /routine?id=<id>           → RoutineDetailScreen(routineId)
                         /routine/new              → RoutineBuilderScreen(routineId: null)
                         /routine/new?editId=<id>  → RoutineBuilderScreen(routineId: editId)
Branch 2 (Exercises) /exercise                    → ExerciseManagerScreen
Branch 3 (Stats)     /stats                       → StatsScreen
```

- Expanded route paths must be **globally unique** across all branches. A screen must not be
  registered twice, or `go_router` throws at runtime.
- Query parameters are used for passing IDs (e.g. `?routineId=xxx`).
- Tab switching uses `navigationShell.goBranch(i, initialLocation: i == currentIndex)`, **not**
  `context.push` — `push` would pile routes onto the stack and defeat state preservation.
- The active workout screen is navigated via GoRouter (`/workout?...`) rather than `Navigator.push`.
- `caseSensitive: true` is set explicitly: `go_router` 15 made URL matching case sensitive, and
  every path in this app is lowercase.
- An `errorBuilder` returns `_RouteNotFoundScreen` for unmatched URLs.
- When an active session exists the nav bar is replaced by a "Resume Workout" bar
  (`WorkoutViewModel.hasActiveWorkout`).

---

## Theming

Theme is defined in `lib/ui/core/theme.dart` as two `ThemeData` objects (`lightTheme` / `darkTheme`) using Material 3 (`useMaterial3: true`).

- Seed color: `#4A5568` (slate grey) for both light and dark (`colorSchemeSeed`).
- Cards: flat (elevation 0), 12px rounded corners, subtle border.
- `themeMode: ThemeMode.system` — follows OS setting.

(Dark accent is the same slate grey, not perwinkle; no custom Inter font family is applied.)

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
- Do **not** reach for `addPostFrameCallback` to dodge a "notify during build" error. `context.read`
  is non-subscribing and therefore legal in `initState`; a provider's `create` runs before any
  listener can be attached, so a synchronous `notifyListeners()` there is a no-op; and a loading
  flag toggled within one async turn needs no intermediate notification. Every `addPostFrameCallback`
  in this codebase was removed for these reasons.

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

| Package | Version | Purpose |
|---|---|---|
| `provider` | 6.1.5+1 | State management & DI |
| `go_router` | 17.5.0 | Declarative routing. 18.x requires Flutter >= 3.44, which this project does not yet satisfy |
| `hive` / `hive_flutter` | 2.2.3 / 1.1.0 | Local persistence (unmaintained; `hive_ce` is the maintained fork) |
| `uuid` | 4.6.0 | ID generation |

`fl_chart`, `build_runner`, `hive_generator`, `intl` and `collection` were removed as unused. The
`VolumeChart` in `stats_widgets.dart` is hand-built from `Container`s, not from a charting library.

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
- See the `dart-modern` skill for `switch` expressions, sealed classes, records, and
  constructor simplification. Note: primary constructors need language version 3.13 and
  the `pubspec.yaml` SDK constraint (`^3.12.2`) does not enable them yet.
- See the `flutter-testing` skill for the `package:checks` assertion migration.

---

## Project Skills

Skills live in `.opencode/skills/` and are loaded on demand. Load the one matching the
area you are changing:

| Skill | Covers |
|---|---|
| `project-architecture` | Layer boundaries, model/view-model rules, adding screens/models/view models |
| `flutter-ui` | Widgets, lifecycle, Material 3, lists, forms, sheets, performance |
| `dart-modern` | Records, patterns, sealed classes, `switch` expressions, immutability, tooling |
| `provider-state` | `MultiProvider` wiring, `watch`/`read`/`select`, `ChangeNotifier` lifecycle |
| `go-router-navigation` | Route table, query params, shell/nav, go vs push, 17 → 18 upgrade |
| `hive-persistence` | Boxes, repository layer, JSON serialisation, schema changes, `hive_ce` migration |
| `fl-chart-graphs` | Chart API for the stats screen. `fl_chart` is no longer a dependency; the chart is hand-built |
| `build-runner-codegen` | **Obsolete** — `build_runner`/`hive_generator` were removed; there are no annotations in `lib/` |
| `uuid-identity` | `Uuid.v4()` usage and id stability rules |
| `flutter-testing` | Unit/widget tests, stub repositories, `package:checks` migration |
