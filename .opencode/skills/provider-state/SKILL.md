---
name: Provider State
description: Wire, read, and fix app state through package:provider and ChangeNotifier view models. Use when editing lib/main.dart, lib/view_models/, or any screen that calls context.watch / context.read / context.select.
---

# Provider State

`provider` 6.1.5+1 — already the latest release. No upgrade needed.

Layer split, per `AGENTS.md`:

- **App state** → `ChangeNotifier` subclasses in `lib/view_models/`, exposed via
  `ChangeNotifierProvider`.
- **Data services** (repositories) → plain `Provider` in `lib/main.dart`.
- **Ephemeral UI state** → local `State` + `setState`.

## Wiring

Everything is registered in one `MultiProvider` in `lib/main.dart`. Repositories first,
view models after, each reading its dependencies with `context.read` inside `create`:

```dart
Provider<RoutineRepository>(create: (_) => RoutineRepository()),
Provider<SessionRepository>(create: (_) => SessionRepository()),
Provider<CustomExerciseRepository>(create: (_) => CustomExerciseRepository()),
ChangeNotifierProvider(
  create: (context) => RoutineViewModel(
    repository: context.read<RoutineRepository>(),
  ),
),
```

Rules that matter:

- Order matters. A provider can only `read` providers declared *above* it.
- `create` is **lazy** by default — the callback runs on first lookup, not at startup.
  Pass `lazy: false` if a provider must do work eagerly (e.g. initial data load).
- `ChangeNotifierProvider(create:)` **disposes** the notifier for you. That is the correct
  form here — `WorkoutViewModel.dispose()` cancels its rest `Timer`, and provider guarantees
  the call.
- `ChangeNotifierProvider.value(value: x)` does **not** dispose `x`. Never use `.value` for
  a notifier you created and own; it silently leaks the timer in `WorkoutViewModel`.
- Use `Provider` (not `ChangeNotifierProvider`) for repositories — they are not listenable
  and wrapping them adds a pointless dispose hook.

## Choosing watch / read / select

| Call | Subscribes? | Use for |
|---|---|---|
| `context.watch<T>()` | yes, rebuilds on every `notifyListeners()` | values the widget renders |
| `context.read<T>()` | no | callbacks, `initState`, `dispose`, passing to another object |
| `context.select<T, R>((t) => t.field)` | yes, only when the selected value changes | one field out of a big view model |

```dart
// Whole model — fine for StatsViewModel/WorkoutViewModel, which change as a unit.
final viewModel = context.watch<WorkoutViewModel>();

// One field — stops the bottom nav from rebuilding on every rest-timer tick.
final hasActiveWorkout = context.select<WorkoutViewModel, bool>((vm) => vm.hasActiveWorkout);

// Handlers never subscribe.
onPressed: () => context.read<RoutineViewModel>().save(),
```

`router.dart:124` currently uses `context.watch<WorkoutViewModel>()` only to read
`hasActiveWorkout`. `context.select` is the tighter fit — the shell does not care about
the rest timer.

`context.select` computes a value on **every** notification. If the projection is
expensive, or you need several fields, use `Consumer`/`Selector` with a `child` so the
static subtree is not rebuilt:

```dart
Consumer<WorkoutViewModel>(
  builder: (context, vm, child) => Text('${vm.completedSets}'),
  child: const Icon(Icons.check),
)
```

- Never `context.watch` in `initState` — the provider is not guaranteed to be readable
  yet. Use `read`, or move the read into `build`.
- `context.watch<T?>()` (nullable) makes the lookup optional and avoids
  `ProviderNotFoundException` where a screen may be mounted in isolation (tests).
- `Provider.of<T>(context)` in `stats_screen.dart:31` is the long form of `context.watch`.
  Prefer the extension form for consistency.

## ViewModel conventions

- Private fields, public getters, no setters.
- `notifyListeners()` after every mutation.
- `dispose()` cancels timers/subscriptions, then `super.dispose()`.
- `ChangeNotifier` throws if you call `notifyListeners()` after `dispose()`. Async work
  that outlives the notifier needs a `disposed` flag guard.

### The `addPostFrameCallback` pattern

`main.dart:52` and `StatsScreen.initState` both use
`WidgetsBinding.instance.addPostFrameCallback` to kick off an initial load. It exists
because `notifyListeners()` during the first build throws. Prefer a direct call in
`initState`:

```dart
@override
void initState() {
  super.initState();
  context.read<StatsViewModel>().loadStats();   // no callback needed
}
```

`loadStats()` sets `_isLoading` and calls `notifyListeners()` synchronously — from
`initState` that is safe because no widget is currently building. Reserve
`addPostFrameCallback` for genuinely post-layout work. If you change this, `main.dart`'s
provider `create` also becomes a plain `ChangeNotifierProvider(create: ...)` and
`StatsScreen` no longer needs to reload on every mount.

## Debugging

- `ProviderNotFoundException` → the widget is above the provider, or the type argument is
  wrong (`context.watch` needs the type explicitly).
- Widget rebuilds when it should not → swap `watch` for `select`, or `Consumer` + `child`.
- "A ChangeNotifier was used after being disposed" → a timer or future is still firing;
  cancel it in `dispose()`.
- `provider_devtools_extension` exists for inspecting provider state in DevTools.
