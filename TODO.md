# TODO

Issues found while auditing the codebase against current documentation (Sept 2026).
Each entry states the problem, why it matters, and a concrete fix.

Ordered roughly by value-per-effort. Items 1–4 are small and safe; 5–7 are real
behavioural bugs; 8–11 are larger and worth their own commits.

---

## 1. Remove dead dependencies

**Problem.** `fl_chart`, `build_runner`, `hive_generator`, `intl`, and `collection` are all
declared in `pubspec.yaml` but imported nowhere in `lib/`. `AGENTS.md` previously claimed
`fl_chart` powered the stats chart (it does not — `VolumeChart` is hand-built from
`Container`s) and that `intl`/`collection` had been removed (they are still there).

**Why.** Every unused entry costs resolution time and misleads the next reader about how
the app works.

**Fix.** Delete all five from `pubspec.yaml`, run `flutter pub get`. Keep `fl_chart` only
if item 9 is planned — in which case bump it to `^1.2.0` at the same time.

```bash
# remove: fl_chart, intl, collection (dependencies)
#         build_runner, hive_generator (dev_dependencies)
flutter pub get
flutter analyze && flutter test
```

---

## 2. Delete `HiveBoxKeys`

**Problem.** `lib/data/services/hive_service.dart:4` declares `HiveBoxKeys.exercises =
'exercises'`, but the real box is `custom_exercises`. The class is referenced nowhere.

**Why.** A misleading constant is worse than no constant — it invites a future caller to
open a second, wrong box.

**Fix.** Delete the `HiveBoxKeys` class entirely.

---

## 3. Replace hard-coded `90` with `defaultRestSeconds`

**Problem.** `lib/constants/rest.dart` defines `defaultRestSeconds = 90` and
`maxRestSeconds = 1800`, but the literal `90` is repeated in seven places:

- `lib/data/repositories/routine_repository.dart:87`
- `lib/data/repositories/session_repository.dart:106,109`
- `lib/domain/models/routine_exercise.dart:15`
- `lib/domain/models/workout_session.dart:59`
- `lib/view_models/routine_view_model.dart:59`

`WorkoutViewModel._restTarget` also holds the string `'90'`.

**Why.** Changing the default rest time requires seven edits, and missing one produces
silently inconsistent records.

**Fix.** Import `package:workout_tracker_app/constants/rest.dart` in each file and use
`defaultRestSeconds`. For `_restTarget`, consider storing an `int` and formatting on
display rather than parsing a string.

---

## 4. Modernise `theme.dividerColor` usages

**Problem.** Four call sites use `Theme.of(context).dividerColor`:
`home_screen.dart:114`, `stats_widgets.dart:109,129,236`.

**Why.** `dividerColor` predates the Material `ColorScheme` role split and is on the
deprecation path. It also ignores the seed colour, so the divider does not track the
theme.

**Fix.** Replace with `colorScheme.outlineVariant`:

```dart
// before
theme.dividerColor.withValues(alpha: 0.3)
// after
theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
```

---

## 5. Tab switches destroy screen state

**Problem.** `lib/navigation/router.dart` uses a single `ShellRoute` wrapping
`BottomNavigationBar`. All four tabs are children of the `/` `GoRoute`, so switching tabs
replaces the route — every screen is rebuilt. Anything in-progress is lost: a half-typed
routine name, a scrolled exercise list, a selected muscle filter.

`_NavScaffold` also derives its index in `didChangeDependencies` + `setState`, manually
reimplementing what `StatefulShellRoute` does natively.

**Why.** This is the most user-visible defect in the app. Users lose work by tapping a tab.

**Fix.** Migrate to `StatefulShellRoute.indexedStack`, which keeps an independent
`Navigator` per branch:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      _NavScaffold(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'exercise', builder: (_, __) => const ExerciseManagerScreen()),
          GoRoute(path: 'workout', builder: (c, s) =>
              WorkoutActiveScreen(routineId: s.uri.queryParameters['routineId'] ?? '')),
          GoRoute(path: 'history', builder: (_, __) => const WorkoutHistoryScreen()),
        ]),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/routine', builder: (_, __) => const RoutineListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (c, s) =>
              RoutineBuilderScreen(routineId: s.uri.queryParameters['editId'])),
        ]),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/exercise', builder: (_, __) => const ExerciseManagerScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    ]),
  ],
)
```

Then in `_NavScaffold`:

```dart
NavigationBar(
  selectedIndex: navigationShell.currentIndex,
  onDestinationSelected: (i) => navigationShell.goBranch(i),
  destinations: const [ /* NavigationDestination x4 */ ],
)
```

Delete `_NavTab`, `_NavTab.fromLocation`, and the `didChangeDependencies` block — the
branch index is now provided directly.

**Watch out for:** `/exercise` and `/history` appear in different branches, so the same
screen can be pushed in two branches. Decide whether `history` belongs under Home (as
today) or gets its own tab, and make the route paths unique across the whole tree.

---

## 6. `RoutineViewModel` mutates its list in place

**Problem.** `_exercises` is a `List` mutated directly:

- `addExercise` — `_exercises.add(...)` (`routine_view_model.dart:60`)
- `removeExercise` — `_exercises.removeWhere(...)` (`:71`)
- `moveExercise` — `removeAt` + `insert` (`:78-79`)

**Why.** `AGENTS.md` and the project skill both state view models must replace lists, not
mutate them. In-place mutation is also the reason `removeExercise` calls `_reorder()`,
which rebuilds every `order` index on every single deletion — O(n) work plus a full
reallocation for a one-item change.

**Fix.** Use copy-and-replace:

```dart
void addExercise(Exercise exercise, {int restSeconds = defaultRestSeconds, int setsCount = 3}) {
  _exercises = [
    ..._exercises,
    RoutineExercise(
      id: _uuid.v4(),
      exercise: exercise,
      order: _exercises.length,
      restSeconds: restSeconds,
      setsCount: setsCount,
    ),
  ];
  notifyListeners();
}

void removeExercise(String exerciseId) {
  _exercises = [
    for (final (i, e) in _exercises.indexed)
      if (e.id != exerciseId) e.copyWith(order: _exercises.length - 1 - i),
  ];
  notifyListeners();
}
```

For `moveExercise`, build the new order first, then assign once. Consider making
`_exercises` an unmodifiable view (`UnmodifiableListView`) so the invariant is enforced by
the type rather than by discipline.

---

## 7. Narrow the provider subscriptions

**Problem.** Two widgets `watch` an entire view model but read one field:

- `lib/navigation/router.dart:124` — `context.watch<WorkoutViewModel>()` for
  `hasActiveWorkout`
- `lib/ui/screens/home_screen.dart:53` — `context.watch<WorkoutViewModel>()` for quick
  actions

**Why.** `WorkoutViewModel` notifies once per second while the rest timer runs. The nav
shell and home quick actions rebuild 60×/minute for a value that changes rarely.

**Fix.**

```dart
final hasActiveWorkout =
    context.select<WorkoutViewModel, bool>((vm) => vm.hasActiveWorkout);
```

If the widget needs several fields, use `Consumer<WorkoutViewModel>` with a `child` for
the static subtree.

---

## 8. Remove the `addPostFrameCallback` workaround

**Problem.** Six sites defer work with `addPostFrameCallback` because
`notifyListeners()` during a build throws:

- `lib/main.dart:52` — initial `StatsViewModel.loadStats()`
- `lib/ui/screens/stats_screen.dart:19` — reload on mount
- `lib/ui/screens/routine_builder_screen.dart:25` — `startEdit(routine)`
- `lib/view_models/routine_view_model.dart:35,41` — notify after `loadRoutines()`

**Why.** The deferral is unnecessary in every case, and in two of them it causes a
duplicated load. `main.dart` kicks off `loadStats()` at startup *and* `StatsScreen.initState`
loads it again on every mount. `RoutineViewModel.loadRoutines()` also notifies twice per
call, which is a wasted rebuild.

**Fix.**

- `main.dart` → plain `ChangeNotifierProvider(create: (context) => StatsViewModel(...))`.
  The `MultiProvider` `create` runs before any widget builds, so a direct `loadStats()`
  there is safe.
- `stats_screen.dart` → `context.read<StatsViewModel>().loadStats();` directly in
  `initState`, or drop it entirely once the provider does the initial load and add a
  pull-to-refresh for subsequent visits.
- `routine_builder_screen.dart` → the `addPostFrameCallback` guards a
  `Provider.of(..., listen: false)`; `context.read` in `initState` is equivalent and
  simpler. Note this screen also calls `Provider.of<RoutineViewModel>(context)` *and*
  `context.read<RoutineViewModel>()` on adjacent lines (`:26` and `:27`) — collapse to one.
- `routine_view_model.dart:35,41` → set `_isLoading`, `await` the repository, then
  `notifyListeners()` once in the `finally`. A loading flag set and cleared within one
  synchronous turn does not need an intermediate notification.

---

## 9. `go_router` 14.8.1 → 18.0.2

**Problem.** Four majors behind.

**Why.** 15.0.0 made URLs **case sensitive** — after upgrading, `/Stats` stops matching
`/stats`. Any deep link or external navigation with the wrong casing 404s. This is the
only breaking change with user-visible effect.

**Fix.** Do it as a dedicated commit, testing case sensitivity first.

1. `flutter pub upgrade go_router` and read the migration guides for 15, 16, and 17.
2. Audit for hard-coded locations: `context.go('/stats')`, `context.push('/routine?id=$id')`
   in `router.dart:119` and `routine_builder_screen.dart:38`. All are lowercase and
   consistent with their `GoRoute` paths, so no change should be needed — verify.
3. Set `debugLogDiagnostics: true` on the `GoRouter` while testing, then remove it.
4. Add an `errorBuilder`. There is none today, so an unmatched URL currently shows the
   default error page. Consider a route to the Home tab instead.
5. Note that 17.0.0 changed `ShellRoute` observer notification, and 18.0.0 requires
   Flutter `>=3.44` (satisfied — the lock floor is 3.38.4) and migrates to `material_ui`.

**Do this before or after item 5, not with it** — combining a navigation-shell rewrite
with a router major upgrade makes bisecting a regression painful.

---

## 10. `hive` → `hive_ce`

**Problem.** `hive` 2.2.3 and `hive_flutter` 1.1.0 are the final releases, published June
2022, from an archived repository. Their SDK constraint (`>=2.12.0 <3.0.0`) is only
satisfiable because pub reinterprets the upper bound as `<4.0.0`.

**Why.** No upstream fixes, and no Dart 3 declaration. It works today, but the position
only degrades.

**Fix.** `hive_ce` / `hive_ce_flutter` 2.20.x (sdk `^3.4.0`) is API-compatible for
everything this app uses — the box API is unchanged, so the migration is mostly an import
swap:

```dart
// lib/data/services/hive_service.dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';  // was: hive_flutter
```

```bash
flutter pub remove hive hive_flutter hive_generator
flutter pub add hive_ce:^2.20.1
flutter pub add hive_ce_flutter:^2.4.0
```

Existing on-disk boxes keep their names and JSON-string values, so no data migration is
required. Run the app against real data afterwards to confirm.

Only do this if you also want the DevTools inspector or isolate support. If the app is
staying JSON-string-based (see item 1), the current setup is stable and this can wait.

---

## 11. Adopt the real `fl_chart` (optional)

**Problem.** `VolumeChart` (`stats_widgets.dart:10-73`) hand-builds a bar chart from
`Container`s, and declares `fl_chart` as a dependency it never uses.

**Why.** Hand-rolling works for five bars, but the current version has no axis labels, no
tooltips, and no scale — a session with 0 volume renders a zero-height bar that is
indistinguishable from missing data.

**Fix.** Only if charts are becoming more complex. Bump to `^1.2.0` (0.68 → 1.x changed
several APIs: `BarChartRodData.toY` is now required, `getTitlesWidget` has a new
signature, tooltips use `getTooltipColor` callbacks). Wrap in a `SizedBox` for height, set
`minY: 0`, and read all colours from `Theme.of(context).colorScheme` so the chart follows
light/dark.

Otherwise delete `fl_chart` per item 1 and keep the hand-rolled version.

---

## Also worth knowing

Not filed as tasks, but worth recording:

- **No `errorBuilder` on the router.** A bad URL shows the default error page. Add one if
  deep linking matters.
- **`BottomNavigationBar` is Material 2.** `NavigationBar` + `NavigationDestination` is the
  Material 3 equivalent. Handle it as part of item 5 — do not mix the two.
- **`_showAddExerciseSheet` is a pass-through** (`routine_builder_screen.dart:42`) that
  only calls `_showCustomExercisesPicker`. Inline it.
- **`test/widget_test.dart` pumps `WorkoutApp` directly**, which builds the real
  `MultiProvider` with real repositories reaching for `HiveService` boxes that were never
  opened. It passes only because the smoke test never triggers a repository call. Mount
  explicit providers with stubs instead — see the `flutter-testing` skill.
- **`flutter_lints` catches `avoid_print`**, so use `debugPrint` for any diagnostics.
