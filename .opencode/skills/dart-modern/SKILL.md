---
name: Dart Language
description: Write or modernise Dart code — records, pattern matching, sealed classes, switch expressions, constructors, immutability, and the formatter/analyzer/fix tooling. Use for changes under lib/domain/, lib/view_models/, or when `dart analyze` reports style or language-version issues.
---

# Dart Language

**Toolchain:** Dart 3.13.4 shipped with Flutter 3.47.x. `pubspec.yaml` declares
`environment: sdk: ^3.12.2`, so the **language version is 3.12**.

That single number gates what you may write:

| Feature | Language version | Available here |
|---|---|---|
| Records, patterns, sealed classes, `switch` expressions | 3.0 | yes |
| Dot shorthands (`.running`, `.parse(...)`, `.new()`) | 3.10 | yes |
| Private named parameters (`{required this._x}`) | 3.12 | yes |
| Primary constructors (`class Point(var int x, var int y);`) | 3.13 | **no** |

`AGENTS.md` references a `dart-use-primary-constructors` skill. **Primary constructors
require language version 3.13 and will not compile under this `pubspec.yaml`.** Do not
apply them unless the SDK constraint is raised first. The same applies to `dart format`
output changes gated on 3.13.

## Modernise old code with

**Pattern matching / switch expressions.** Replace `if/else` chains that dispatch on a
type or a tagged value:

```dart
// Before
String label;
if (state is Loading) {
  label = 'Loading';
} else if (state is Ready) {
  label = (state as Ready).name;
} else {
  label = 'Unknown';
}

// After
final label = switch (state) {
  Loading() => 'Loading',
  Ready(name: final n) => n,
  Error() => 'Unknown',
};
```

Mark a base class `sealed` when its subtypes are all in the same library — the compiler
then enforces exhaustiveness, and adding a subtype becomes a compile error at every
non-exhaustive `switch`. This is the single highest-value change in this codebase's
domain models.

**Records** for multi-value returns instead of writing a throwaway class:
`Map<String, (int sets, double volume)>`, or `({String name, int count})` when names
matter. Destructure with `final (a, b) = ...` or `final (:name, :count) = ...`.

**Dot shorthands** (3.10) where the target type is inferable:
`final status = .running;`, `final n = .parse(text);`, `final map = .new()`.

**Private named parameters** (3.12) to drop the manual initializer list:

```dart
// Before
class RoutineViewModel extends ChangeNotifier {
  RoutineViewModel({required RoutineRepository repository})
      : _repository = repository;
  final RoutineRepository _repository;
}

// After (3.12+)
class RoutineViewModel extends ChangeNotifier {
  RoutineViewModel({required this._repository});
  final RoutineRepository _repository;
}
```

## Immutability rules for this repo

- Domain models: `const` constructor, all `final` fields, `copyWith`.
- `copyWith` returns a new instance; never mutate a field of an existing model.
- View models replace lists and maps wholesale (`_exercises = _exercises.map(...).toList()`),
  never `add`/`remove` in place on a list a widget is holding. `RoutineViewModel` currently
  violates this in `addExercise`/`removeExercise`/`moveExercise` — if you are editing those,
  switch them to copy-and-replace.
- `fromJson`/`toJson` belong to repositories and `CustomExercise` only, per `AGENTS.md`.
  Nullable fields get a `??` default in `fromJson` so old records still load.

## Tooling

```bash
dart format .                       # tall style (language version >= 3.7)
dart format --output=none --set-exit-if-changed .   # CI check
dart analyze                        # or: flutter analyze
dart fix --apply                    # bulk-apply analyzer fixes
dart pub outdated                   # current vs upgradable vs resolvable vs latest
```

- `dart format --fix` was removed. Use `dart fix` for mechanical fixes.
- `--line-length` is deprecated → `--page-width`. Set `formatter: page_width:` in
  `analysis_options.yaml` rather than passing flags.
- Run `dart format` on every file you touch; the tall style is not optional and CI
  checks it.
- Optional strictness (not currently enabled, add deliberately):
  `analyzer: language: strict-casts: true, strict-raw-types: true` in
  `analysis_options.yaml`.

## Errors and async

- `try`/`catch`/`finally`, with the state reset in `finally` so a throw cannot leave a
  view model stuck in `_isLoading = true`.
- Repositories swallow parse errors deliberately (`catch (_)` in
  `session_repository.dart:47`) — data integrity is assumed at that boundary. Do not
  "improve" this to rethrow without understanding why.
- `unawaited` / `discarded_futures` are not enabled, but do not leave floating futures in
  new code.
