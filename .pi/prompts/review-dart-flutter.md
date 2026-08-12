---
description: |
  Comprehensive review of Dart/Flutter projects for best practices, mobile quality,
  and design consistency. Use when asked to review, audit, or evaluate a Flutter
  codebase. Accepts an optional path argument (defaults to cwd).
argument-hint: "[path]"
---

Review the Dart/Flutter project at `${1:-.}` thoroughly. Produce a structured report
covering the areas below. Be specific — cite file paths, line numbers, and concrete
examples from the code. End with an actionable prioritised fix list.
If sub-agents are available, delegate all tasks to them.

## 0 — Project Scan

Before diving in, gather context:

1. Read `pubspec.yaml` — note Flutter/Dart SDK constraints, key dependencies, and
   whether the project uses `flutter_lints`, `flutter_secure_storage`, `go_router`,
   `provider`/`riverpod`/`bloc`, `hive`/`isar`/`sqflite`, `freezed`/`json_serializable`, etc.
2. Read the project's `AGENTS.md` if it exists — follow its conventions exactly.
3. List the top-level `lib/` structure to understand the architecture at a glance.
4. Check `analysis_options.yaml` for enabled lints and strictness settings.
5. Check `test/` coverage — how many test files exist, are they under `test/unit/`,
   `test/widget/`, `test/integration/`?

## 1 — Architecture & Layering

Verify the project respects clean boundaries:

- **UI / Logic / Data separation** — screens should not contain business logic or
  direct data access. ViewModels (or controllers) own state; repositories own data.
- **Model immutability** — domain models should be immutable (`final` fields,
  `copyWith`, `const` constructors). No direct mutation.
- **Repository pattern** — data access is abstracted behind repository interfaces;
  screens never call a database or HTTP client directly.
- **Dependency injection** — dependencies are injected (constructor injection,
  `Provider`, `get_it`), not instantiated with `new` inside widgets.
- **No god classes** — screens, ViewModels, and repositories should each have a
  single clear responsibility. Flag anything over ~300 lines.

## 2 — Dart Code Quality

Check for modern, idiomatic Dart:

- **Null safety** — no `!` abuse, no `dynamic` where a type is known, no
  unnecessary `?` on fields that are always set.
- **Pattern matching** — `switch` expressions used instead of long `if/else` chains
  or manual type checks with `is`/`as`.
- **Primary constructors** — classes use primary constructor syntax where possible
  (`class Foo(this.bar)` instead of declaring fields separately).
- **Collection & record usage** — records used for simple tuples instead of custom
  two-field classes; `collection` package used where appropriate.
- **`checks` package** — test assertions use `package:checks` instead of
  repeated `expect(..., equals(...))`.
- **`async`/`await`** — no raw `.then()` chains; `async`/`await` with
  `try/catch/finally` used consistently.
- **`const` everywhere** — widgets, `const` constructors, and compile-time
  constants used aggressively to enable const-folded widgets.
- **No `print`** — no bare `print()` calls; logging uses a proper logger or is
  stripped in release builds.

## 3 — Flutter UI & Widget Practices

- **`StatelessWidget` preference** — stateful widgets are used only when local
  mutable state is required; otherwise `StatelessWidget`.
- **Widget decomposition** — large `build()` methods are broken into private
  helper widgets (`_Header`, `_ItemCard`, etc.), not a single 200-line method.
- **`const` constructors** — widgets use `const` where all children are also const.
- **`ListView.builder`** — long lists use `ListView.builder`, not `ListView`
  with a built children list (avoids building off-screen widgets).
- **Keys** — lists with dynamic children use appropriate keys (`ValueKey`,
  `ObjectKey`) — no missing keys on `ListView.builder` children.
- **No context abuse** — `BuildContext` is not stored or used across async gaps.
- **`didUpdateWidget`** — `TextEditingController` and other disposable resources
  are synced in `didUpdateWidget` and disposed in `dispose`.

## 4 — Mobile-First Concerns

- **Touch targets** — all interactive widgets have a minimum 48×48 logical pixel
  touch target (use `Padding`, `InkWell`, or `GestureDetector` with sizing).
- **Responsive layout** — the UI adapts to different screen sizes using
  `LayoutBuilder`, `MediaQuery`, `Expanded`/`Flexible`, or `breakpoints`.
  Flag any hardcoded `Width`/`Height` that would break on smaller screens.
- **Keyboard handling** — text input screens use `SingleChildScrollView` or
  `KeyboardDismissing` wrappers so content is not obscured.
- **Bottom sheets** — `showModalBottomSheet` uses `isScrollControlled: true`
  and accounts for keyboard insets via `MediaQuery.viewInsets.bottom`.
- **Image handling** — images use proper caching (`cached_network_image` or
  similar), include `fit`, and handle load failures with placeholders.
- **Performance** — expensive computations are wrapped in `compute()`; lists
  are paged or lazy-loaded; no heavy work on the UI thread.
- **Accessibility** — semantic labels on icons/buttons without text;
  `Semantics` widget used where appropriate; contrast ratios checked against
  the app's theme colours.

## 5 — Design System & Theming Consistency

- **Single theme source** — all colours, typography, and spacing come from
  `ThemeData` or a dedicated theme file; no magic string colours in widgets.
- **Dark mode support** — the app defines both light and dark themes and uses
  `Theme.of(context).colorScheme` instead of hardcoded colours.
- **Consistent spacing** — a shared spacing scale (e.g. 4px/8px/12px/16px/24px)
  is used everywhere; no arbitrary pixel values like `padding: const EdgeInsets.all(13)`.
- **Consistent typography** — text styles come from `Theme.of(context).textTheme`
  or a shared `TextStyles` class.
- **Component library** — repeated UI patterns (cards, buttons, input fields)
  are extracted into shared components in `lib/ui/core/` rather than duplicated.

## 6 — State Management

- **ViewModel pattern** — state lives in `ChangeNotifier` (or equivalent)
  ViewModels; screens are thin presentational layers.
- **No state in widgets** — screens do not own app-level state via `setState`;
  only ephemeral UI state (e.g. controller text, animation controller) lives
  in widget `State`.
- **Proper notification** — `notifyListeners()` is called after every state
  mutation; async operations use `try/catch/finally` with notification in
  `finally`.
- **No stale data** — ViewModels re-fetch or refresh data when navigating back
  to a screen (via `WidgetsBindingObserver` or route listeners).

## 7 — Data Layer

- **Repository abstraction** — all persistence and API calls go through
  repositories; no direct Hive/SQLite/HTTP calls from ViewModels or screens.
- **Error swallowing** — repository methods catch and handle errors gracefully;
  they do not propagate raw exceptions to the UI layer.
- **JSON serialisation** — `fromJson`/`toJson` is consistent; generated code
  (e.g. `json_serializable`) is kept in sync; hand-written serialisation is
  DRY and tested.
- **Migration safety** — local storage migrations handle old data formats
  gracefully; no crashes on app update.

## 8 — Routing

- **Declarative routing** — routes are defined in a central router file
  (e.g. `go_router`), not scattered `Navigator.push` calls.
- **Route safety** — deep links and back-navigation are handled; routes
  guard sensitive screens if authentication is required.
- **Query parameters** — IDs and config are passed via query parameters,
  not by leaking state between routes.

## 9 — Testing

- **Unit tests** — ViewModels and repositories have unit tests covering
  success, failure, and edge cases.
- **Widget tests** — key screens have widget tests verifying rendering and
  user interactions (taps, text input).
- **Test structure** — tests follow Arrange-Act-Assert; mocks are used for
  external dependencies.
- **Coverage** — critical paths (state mutations, data transforms, error
  handling) have ≥ 80% branch coverage.

## 10 — Security & Privacy

- **No hardcoded secrets** — API keys, tokens, or passwords are not committed
  to source control.
- **Secure storage** — sensitive data (auth tokens, PII) uses
  `flutter_secure_storage` or equivalent, not shared preferences.
- **Network security** — HTTPS is enforced; certificate pinning is used for
  sensitive endpoints if applicable.
- **User data** — personal data is not logged; analytics are opt-in.

---

## Output Format

Produce the report in this structure:

```
# Review: <project-name>

## Executive Summary
<2-3 sentences: overall health, biggest wins, biggest risks>

## Scores
| Area | Rating (1-5) | Notes |
|---|---|---|
| Architecture | ⭐⭐⭐⭐ | … |
| Code Quality | ⭐⭐⭐ | … |
| Mobile Readiness | ⭐⭐⭐⭐ | … |
| Design Consistency | ⭐⭐⭐ | … |
| Testing | ⭐⭐ | … |

## Findings

### 🔴 Critical (fix before shipping)
- `lib/foo/bar.dart:42` — <issue> — <why it matters> — <fix>

### 🟡 Warnings (fix soon)
- …

### 🟢 Suggestions (nice to have)
- …

## Prioritised Fix List
1. [Critical] …
2. [Critical] …
3. [Warning] …
```

Rating scale: ⭐⭐⭐⭐⭐ = excellent, ⭐⭐⭐ = acceptable with caveats, ⭐ = needs work.
