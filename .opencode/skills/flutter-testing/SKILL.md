---
name: Testing
description: Write and run tests in test/ — view model unit tests, widget tests, and stub repositories. Use when adding coverage, fixing a failing test, or when a change under lib/ needs verification.
---

# Testing

`flutter_test` only. There is no `mockito`, no `mocktail`, and no `package:checks`
dependency in `pubspec.yaml`.

```bash
flutter test                                  # all
flutter test test/unit/workout_view_model_test.dart
flutter test --plain-name "createSession()"
flutter test --update-goldens                  # only if goldens exist (none currently)
```

## Layout

```
test/
  unit/routine_view_model_test.dart
  unit/stats_view_model_test.dart
  unit/workout_view_model_test.dart
  widget_test.dart
```

## How this project stubs repositories

No mocking library. Each test defines a private stub that **extends** the real repository
and overrides the methods it needs, backed by an in-memory list:

```dart
class _StubSessionRepository extends SessionRepository {
  final List<WorkoutSession> _sessions = [];

  @override
  Future<List<WorkoutSession>> getAllSessions() async => _sessions;

  @override
  Future<void> saveSession(WorkoutSession session) async => _sessions.add(session);
}
```

This works because the repositories are concrete classes with overridable methods, and it
keeps tests free of `Hive.initFlutter()` (which needs a real filesystem) — the overridden
methods never touch `HiveService`. Follow this pattern rather than introducing mockito.

- Use `late` + `setUp` to build the stub and the view model per test.
- Expose stub internals through extra getters (`WorkoutSet? get savedSession => _saved;`)
  so assertions do not reach into private fields.
- `RoutineViewModel.getRoutine` uses `.firstOrNull` on an `Iterable` — available from
  `package:collection` / `dart:core` extensions. `collection` is still in `pubspec.yaml`
  even though `lib/` does not import it.

## Arrange-Act-Assert

Keep the three phases visually separated and assert on public getters, never on private
fields:

```dart
test('completeSet() marks the set completed', () async {
  // Arrange
  final session = await viewModel.createSession(routine);
  // Act
  viewModel.completeSet(0, 0);
  // Assert
  expect(viewModel.session!.exercises.first.sets.first.completed, isTrue);
});
```

## ChangeNotifier testing

View models extend `ChangeNotifier` and can be tested with plain `test()` — no widget
harness needed. To assert notification behaviour, register a listener:

```dart
var notifications = 0;
viewModel.addListener(() => notifications++);
viewModel.cancelRest();
expect(notifications, 1);
```

Always `viewModel.dispose()` at teardown where a timer or listener is involved.
`WorkoutViewModel` starts a `Timer.periodic`; a test that calls `startSetRest` without
disposing will leave it running.

## Widget tests

For a screen, wrap in the real providers and pump:

```dart
await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WorkoutViewModel(repository: repo)),
    ],
    child: const MaterialApp(home: WorkoutActiveScreen(routineId: 'r1')),
  ),
);

expect(find.text('Resume Workout'), findsNothing);
await tester.tap(find.byIcon(Icons.check));
await tester.pump();
expect(find.byType(AlertDialog), findsOneWidget);
```

- Use `find.text`, `find.byKey`, `find.byIcon`; `findsOneWidget` / `findsNothing` /
  `findsNWidgets` for counts.
- `await tester.pump()` advances a frame; `pumpAndSettle()` for animations — but it will
  time out on a repeating `Timer` like the rest timer, so prefer `pump()` with explicit
  `Duration`s in `WorkoutViewModel` tests.
- Pass `MultiProvider` explicitly rather than mounting `WorkoutApp`; `WorkoutApp` calls
  `HiveService` indirectly through real repositories and the real `GoRouter` singleton is
  global state that leaks between tests.
- `tester.pumpWidget` with a router-driven app needs a fresh `GoRouter` per test.

## Migrating to `package:checks`

`AGENTS.md` points at a `dart-migrate-to-checks-package` skill. `package:checks` is **not**
a dependency; `checks` 0.3.2 requires sdk `^3.11.0` (compatible) and works with
`package:test` via `import 'package:test/scaffolding.dart'`.

To adopt it:

```bash
dart pub add --dev checks
```

then swap `expect(x, isTrue)` for `x.isTrue`, `x.contains(y)` for `y in x`,
`throwsA(isA<E>())` for `throwsE`, and `isNotNull` for `x.isNotNull`. Only worth doing as a
dedicated sweep across the whole suite — partial adoption buys nothing and
`expect(actual, matcher)` is still required for anything without a `checks` equivalent.
