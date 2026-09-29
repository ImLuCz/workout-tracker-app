---
name: Flutter UI
description: Build and change widgets, screens, themes, forms, and dialogs in this Flutter app. Use for anything under lib/ui/ — layout, state, theming, Material 3, lists, bottom sheets, input handling, or rendering/performance issues.
---

# Flutter UI

Framework rules for `lib/ui/`. Read `AGENTS.md` first for the layer boundaries — this
skill covers *how* to build the widgets, not where they go.

**Toolchain:** Flutter 3.47.x stable / Dart 3.13.4. `pubspec.lock` floor is Flutter
`>=3.38.4`, Dart `>=3.12.2`. Lints come from `flutter_lints` 6.0.0 via
`analysis_options.yaml`; `avoid_print`, `use_build_context_synchronously`,
`use_key_in_widget_constructors`, `sort_child_properties_last`, and
`sized_box_for_whitespace` are all active. Run `flutter analyze` before declaring work done.

## Widget construction

- `StatelessWidget` by default. `StatefulWidget` only when there is real local state.
- `const` constructors everywhere possible — the formatter and `prefer_const_constructors`
  will flag non-const subtrees, and `const` is what lets Flutter skip rebuild work.
- `super.key`, not positional keys.
- Break large `build()` methods into private widget classes (`_ExerciseCard`). Never build
  a large tree inline in a method.
- Reusable components live in `lib/ui/screens/widgets/*_widgets.dart`, one file per screen
  area. Do not add a fourth top-level screen file for a fragment.

## Lifecycle and rebuild scope

- `setState` must be synchronous. Never `await` inside it.
- Call `super.dispose()` last in `dispose()`.
- `TextEditingController` created in `State` **must** be disposed in `dispose()`.
  `lib/ui/screens/widgets/routine_builder_widgets.dart` and
  `workout_active_widgets.dart` hold these; check new fields are disposed too.
- Sync a controller against an externally-changed model in `didUpdateWidget`, not in
  `initState` — `initState` runs before inherited widgets are readable.
- `WidgetsBinding.instance.addPostFrameCallback` is the escape hatch for notifying after
  the first frame (used by `StatsScreen.initState` and the `StatsViewModel` provider).
  Prefer a direct `context.read<ViewModel>().load()` in `initState` when that is all you
  need.

## Material 3

`useMaterial3` has defaulted to `true` since Flutter 3.16 and is slated for removal.
`lib/ui/core/theme.dart` still sets it explicitly — leave it, it is harmless and documents
intent. Do not reintroduce Material 2 widgets or `ThemeData` color properties that were
removed in 3.19 (`errorColor`, `backgroundColor`, `bottomAppBarColor`).

Component themes use the `*ThemeData` classes. `theme.dart` already does
`cardTheme: CardThemeData(...)`; the old `CardTheme`/`DialogTheme`/`TabBarTheme` types
were replaced and will not compile.

- Seed color is `0xFF4A5568` for both light and dark via `colorSchemeSeed`.
- Read colors from `Theme.of(context).colorScheme`, never hard-coded literals, unless
  the literal is the theme's own definition.
- `Color.withOpacity` is deprecated → `color.withValues(alpha: x)` (already used
  throughout `stats_widgets.dart`).
- `theme.dividerColor` in `stats_widgets.dart:109` predates the `ColorScheme` move; prefer
  `colorScheme.outlineVariant` for new code.

The bottom nav in `lib/navigation/router.dart` is still the Material 2
`BottomNavigationBar`. That works, but `NavigationBar` + `NavigationDestination` is the
Material 3 equivalent. If you touch the shell, do not silently mix the two.

## Lists

- `ListView.builder` for anything unbounded. Never `ListView(children: [...])` over a
  collection.
- `ListView` with `NeverScrollableScrollPhysics` inside a sheet is correct when the sheet
  itself scrolls; keep `shrinkWrap: true` with it.
- Prefer `prototypeItem:` on `ListView.builder` when rows are uniform height — it improves
  scroll performance measurably.

## Forms and input

- `FilteringTextInputFormatter` for numeric fields. Weight accepts decimals:
  `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))` (see
  `workout_active_widgets.dart:283`). Integers use `.digitsOnly`.
- Commit values on `onEditingComplete` and dismiss focus on `onTapOutside`.
- Validate with `TextFormField` + `Form` + `GlobalKey<FormState>`; the key is typed
  `GlobalKey<FormState>`, not `GlobalKey<YourState>`.
- `use_build_context_synchronously` is enforced. After any `await`, guard with
  `if (!context.mounted) return;` before touching `context`. `routine_builder_screen.dart:50`
  shows the correct pattern.

## Dialogs, sheets, snackbars

- `showModalBottomSheet` with `isScrollControlled: true`, and pad the bottom by
  `MediaQuery.of(ctx).viewInsets.bottom` so the keyboard does not cover inputs. Wrap in
  `SafeArea`.
- `StatefulBuilder` is the accepted way to hold local state inside a sheet
  (`exercise_manager_screen.dart:326`). Do not reach for a full `StatefulWidget` here.
- `showDialog` with `AlertDialog` for destructive actions, returning `bool?` and checking
  the result. Note `AlertDialog` already wraps title/content in a scroll view — do not add
  your own `SingleChildScrollView` inside `content`.
- Snackbars go through `ScaffoldMessenger.of(context)`, never a bare `Scaffold.of(context)`.

## Performance

- Keep `build()` free of heavy computation. If a list computes `max`/`reduce` per row,
  hoist it out of the builder.
- Pass the invariant subtree as `child` to `ListenableBuilder` / `AnimatedBuilder` so it
  is not rebuilt on every tick.
- Localize `setState` to the smallest subtree that needs it; a `setState` in a screen
  root rebuilds the whole screen.
- Do not capture `BuildContext` in closures passed to long-lived handlers; it leaks.

## Commands

```bash
flutter analyze          # must be clean
flutter test
flutter run
```
