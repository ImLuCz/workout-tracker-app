---
name: Architecture and Conventions
description: Where code goes and how it is shaped — layer boundaries, model/view-model/repository rules, and the workflow for adding a screen, model, or view model. Use when starting any structural change or unsure which directory a file belongs in.
---

# Architecture and Conventions

Read `AGENTS.md` for the canonical description. This skill adds the decision rules and
flags the parts of it that are stale.

## Layer boundaries

| Directory | May depend on | Must not |
|---|---|---|
| `lib/domain/models` | nothing but `dart:*` | import Flutter or any package except `uuid` |
| `lib/data/repositories` | models, `hive_service` | import `provider`, `go_router`, or `lib/ui` |
| `lib/data/services` | Hive | know about models |
| `lib/view_models` | models, repositories, `provider` | import `lib/ui` or `lib/navigation` |
| `lib/ui/**` | everything above | contain business logic or touch `HiveService` |
| `lib/navigation` | screens, view models | hold state that belongs in a view model |

The dependency arrow points one way, downward. A repository importing `provider` or a
screen reading `HiveService` directly is a bug even if it compiles.

## Models

- `const` constructor, all `final`, `copyWith`.
- `fromJson`/`toJson` only where data crosses the persistence boundary: the repositories
  and `CustomExercise`. Other models are serialised by the repository that owns them
  (`SessionRepository._sessionExerciseToJson` and friends).
- Computed values are getters, not fields: `WorkoutSet.isLogged`, `WorkoutSession.totalVolume`,
  `WorkoutStats.avgVolumePerSession`.
- `copyWith` on a model that wraps another (`RoutineExercise.copyWith(exerciseId:)`)
  rebuilds a minimal `Exercise` rather than taking one — keep that shape, callers rely on
  it.

## View models

- `ChangeNotifier` subclass, private fields + public getters, `notifyListeners()` on every
  mutation, `dispose()` for timers.
- One view model per concern: `RoutineViewModel`, `WorkoutViewModel`, `StatsViewModel`.
  Do not add a fourth unless it owns genuinely separate state.
- `lib/constants/` holds shared constants — `rest.dart` (`defaultRestSeconds` = 90,
  `maxRestSeconds` = 1800) and `muscles.dart`. Magic numbers belong here, not inline.
  Hard-coded `90` still appears in `session_repository.dart:106`; use the constant.

## Naming and files

- `snake_case` files and directories, `PascalCase` classes, `_` prefix for private
  implementation classes.
- One top-level class per file unless they are tightly coupled private helpers
  (`_StatsComputeResult` + `_WeeklyMuscleAccumulator` in `stats_view_model.dart`).
- Screen fragments go in `lib/ui/screens/widgets/<screen>_widgets.dart`, not a new top-level
  file.

## Adding things

**A screen** — create `lib/ui/screens/<name>_screen.dart`, add a `GoRoute` under the `/`
route in `router.dart`, navigate with `context.push` (detail) or `context.go` (tab).
See the `go-router-navigation` skill for the route table.

**A model** — create in `lib/domain/models/`, add `(de)serialisation` to the owning
repository, open a new box in `HiveService` only if the data is genuinely new storage,
add a `Provider` in `main.dart` if it needs a repository.

**A view model** — create in `lib/view_models/` extending `ChangeNotifier`, add a
`ChangeNotifierProvider` in `main.dart`, read with `context.watch`/`read`/`select`.
See the `provider-state` skill.

## Before finishing

```bash
dart format .
flutter analyze
flutter test
```

All three clean. `flutter analyze` is the gate — `flutter_lints` 6.0.0 plus the project
config will catch unused imports, missing `const`, and `BuildContext` across async gaps.

## Stale bits in AGENTS.md

Known inaccuracies — trust the code over the doc:

- It lists `dart-use-pattern-matching`, `dart-use-primary-constructors`, and
  `dart-migrate-to-checks-package` as skills. Those do not exist. The equivalents are
  covered by `dart-modern` and `flutter-testing` here.
- It says `intl` and `collection` are "no longer dependencies". They are still in
  `pubspec.yaml` (as direct deps) but imported nowhere in `lib/`.
- It says `fl_chart` is used for the stats screen. It is declared but never imported —
  the chart is hand-built.
- It describes `hive_generator` as an active codegen dependency. No annotations exist, so
  it generates nothing.
- It omits `build_runner` and `hive_generator` from the Key Dependencies table despite
  both being dev dependencies.
