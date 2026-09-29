---
name: GoRouter Navigation
description: Add, change, or debug routes and navigation in lib/navigation/router.dart. Use for new screens, query-parameter passing, bottom-nav tab mapping, deep links, back-button behaviour, or go_router upgrade work.
---

# GoRouter Navigation

`go_router` **14.8.1** is pinned. The current release is **18.0.2**, so this app is
several majors behind — see the upgrade section before assuming a newer API exists.

Everything lives in one top-level `final GoRouter router` in `lib/navigation/router.dart`,
passed to `MaterialApp.router(routerConfig: router)`.

## Route table as it stands

```
/                            ShellRoute → _NavScaffold
  exercise                   ExerciseManagerScreen
  routine                    RoutineListScreen          (no `id` query)
  routine?id=<id>            RoutineDetailScreen
    new                      RoutineBuilderScreen       (`?editId=` to edit)
  workout?routineId=<id>     WorkoutActiveScreen
  stats                      StatsScreen
  history                    WorkoutHistoryScreen
```

Child paths are declared **relative** (`'routine'`, not `'/routine'`) because they are
nested under the `/` `GoRoute`. A leading slash on a child is allowed as of 14.2.9 but
stays wrong for this tree.

## Reading parameters

Since 10.0, `GoRouterState` exposes a single `Uri`; the old `location` /
`queryParameters` getters are gone.

```dart
GoRoute(
  path: 'workout',
  builder: (context, state) {
    final routineId = state.uri.queryParameters['routineId'] ?? '';
    return WorkoutActiveScreen(routineId: routineId);
  },
)
```

This project passes **IDs as query parameters**, not path segments. Keep that convention —
`/routine?id=` and `/workout?routineId=` are the established shape. Reach for a path
parameter (`'routine/:id'` → `state.pathParameters['id']`) only for new, genuinely
hierarchical resources; mixing styles in one tab makes deep links confusing.

Never use `state.uri.toString()` to test a location. Compare `state.uri.path`, as
`_NavTab.fromLocation` already does.

## Navigating

```dart
context.go('/stats');                     // replace the stack — tab switches
context.push('/routine/new?editId=$id');  // push on top — detail → sub-screen
context.pop();                            // back
final ok = await context.push<bool>('/confirm');  // await a result
```

- **Tab navigation uses `go`, not `push`.** `_onTabTapped` does this correctly. Using
  `push` for a bottom-nav tab stacks tabs on each other and breaks the back button.
- **Detail → sub-screen uses `push`**, so back returns to the list.
- Always URL-encode interpolated values, or build the location with
  `Uri(path: ..., queryParameters: ...).toString()`.
- `go` and `push` are the current names. `replace` was renamed `pushReplacement` in 6.0.

## The bottom-nav shell

`_NavScaffold` derives its index in `didChangeDependencies` and calls `setState`. That
works, but it is a manual reimplementation of what `StatefulShellRoute` does natively.

`StatefulShellRoute.indexedStack` is the purpose-built API: it keeps an independent
`Navigator` per tab, so scroll positions and in-progress text fields survive tab switches.
`_NavTab.fromLocation` (a string-prefix match) would collapse into per-branch routing, and
tab taps become `navigationShell.goBranch(index)`.

The current single-`ShellRoute` design also means each tab switch destroys and rebuilds
every screen. That is visible in practice: the exercise picker and routine builder lose
their state. Migrating to `StatefulShellRoute` is the fix, and it is a contained change —
one `GoRouter`, four `StatefulShellBranch`es, `goBranch` in `_onTabTapped`.

## Reactive navigation

- `GoRouterState.of(context)` inside `build` re-registers a dependency, so the widget
  rebuilds on location change. Prefer this over the `didChangeDependencies` + `setState`
  dance.
- `GoRouter.of(context)` throws when there is no router; `GoRouter.maybeOf(context)` does
  not — useful in shared widgets used outside the app shell.
- `refreshListenable` accepts a `Listenable` and re-runs `redirect` when it fires. A
  `ChangeNotifier` view model can be passed directly.

## Errors

- `errorBuilder` is not set. An unmatched URL currently shows the default error page. Add
  one if deep linking matters.
- `debugLogDiagnostics: true` prints the route tree and matching — the fastest way to
  diagnose a 404 on a nested path.
- Redirect loops throw after a fixed limit; `redirect` is re-evaluated until it returns
  `null`, so always make progress toward a terminal route.

## Upgrading 14 → 18

Not a version bump. Relevant breaking changes:

- **15.0.0** — URLs are **case sensitive**. `/Stats` stops matching `/stats`. Adds a
  `caseSensitive` field to `GoRoute` (default `true`). There is **no** matching parameter on
  the `GoRouter` constructor — passing one is a compile error.
- **16.0.0** — `GoRouteData` breaking changes; only matters if `go_router_builder` is
  adopted.
- **17.0.0** — `ShellRoute` / `StatefulShellRoute` navigating now notifies GoRouter
  observers by default; `notifyRootObserver` is the escape hatch.
- **16.3.0** — top-level `onEnter` returning `Allow` / `Block` / `Block.then(...)`.
- **18.0.0** — requires Flutter `>=3.44` / Dart `>=3.12` (satisfied here), migrates to
  `material_ui` / `cupertino_ui`.
- Route `metadata` (17.5.0) and `TypedQueryParameter` (17.1–17.2) are opt-in.

Do the upgrade in its own commit, after reading the official migration guides for 15, 16,
and 17. Fix case-sensitivity fallout first — it is the only one that changes user-visible
URL matching.
