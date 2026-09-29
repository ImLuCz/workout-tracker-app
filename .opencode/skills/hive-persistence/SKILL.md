---
name: Hive Persistence
description: Read and write local data through Hive boxes and the repository layer. Use for changes under lib/data/, new stored entities, box lifecycle, JSON (de)serialisation, or schema/migration questions.
---

# Hive Persistence

`hive` 2.2.3 + `hive_flutter` 1.1.0.

**These are the last published versions of both packages** (June 2022) and the original
repo is archived. They still work — this app is on Dart 3 and it runs — but there is no
upstream maintenance, and their `environment: sdk: ">=2.12.0 <3.0.0"` constraint is
reinterpreted by pub as `>=2.12.0 <4.0.0`. Treat the dependency as frozen.

The maintained community fork is **`hive_ce` / `hive_ce_flutter`** (2.20.x, sdk `^3.4.0`),
which adds isolate support, a DevTools inspector, and a unified `@GenerateAdapters`
annotation. Migration is mostly an import swap (`package:hive/hive.dart` →
`package:hive_ce/hive_ce.dart`) since the box API is unchanged. Do not migrate as a side
effect of an unrelated change; propose it separately.

## Current storage shape

Three boxes, opened once in `HiveService.init()` (`lib/data/services/hive_service.dart`):

| Box | Key | Value | Holds |
|---|---|---|---|
| `routines` | `String` (uuid v4) | JSON `String` | `WorkoutRoutine` |
| `sessions` | `String` (uuid v4) | JSON `String` | `WorkoutSession` |
| `custom_exercises` | `String` (uuid v4) | JSON `String` | `CustomExercise` |

Boxes are typed `Box<dynamic>` and hold **JSON-encoded strings**, not Hive `TypeAdapter`s.
Serialisation is hand-written in the repositories.

Note `HiveBoxKeys` in `hive_service.dart` declares `exercises = 'exercises'` while the
actual box is `custom_exercises`. The constant is unused dead code — delete it rather than
"fixing" it.

## Layers

`domain/models` (immutable, `copyWith`) → `data/repositories` (JSON + box access) →
`data/services/hive_service.dart` (box handles). Repositories never expose `Box` to callers;
screens and view models only see the typed methods.

Every repository follows the same shape:

```dart
Future<List<T>> getAll*()          // newest-first where order matters
T?                get*(String id)  // sync read
Future<void>      save*(T entity)
Future<void>      delete*(String id)
Future<void>      clearAll()
```

`SessionRepository` adds `getLastCompletedSessionForRoutine(routineId)`, used to carry
forward the previous weights/reps into a new session. That is a domain rule — keep it on
the repository, not in the view model.

## Rules when touching this layer

- `HiveService.init()` runs once in `main()` before `runApp`, awaited. A new box means a
  new `static late Box<dynamic>` plus a getter plus an `openBox` line — all three.
- `box.get(key) as String?` then `jsonDecode` then `_fromJson`. Always guard the cast and
  the parse.
- Parse failures are **deliberately swallowed** with `debugPrint`
  (`session_repository.dart:47`). One corrupt record must not take down the whole list.
  Preserve that behaviour; do not convert it to a rethrow.
- Numeric fields round-trip as `num`, so read with `(data['weightKg'] as num?)?.toDouble() ?? 0.0`.
  A raw `as double` will throw on a value that came back as `int`.
- `DateTime` is stored as `toIso8601String()` and read with `DateTime.parse`. Never store
  epoch millis — the existing records are ISO strings.
- Nullable fields need a `??` default in `fromJson` so records written before a field
  existed still load.
- Adding a field is safe (old records get the default). **Renaming or removing one is a
  breaking data change** — write both keys on save, or bump and migrate.

## Adapters vs JSON strings

The project stores JSON strings, so `hive_generator` and `build_runner` are declared in
`pubspec.yaml` but **currently generate nothing** — there are no `@HiveType`/`@HiveField`
annotations anywhere in `lib/`. Two valid directions:

- **Stay with JSON strings** (current). Simple, human-inspectable, no codegen step.
  Prefer this unless there is a concrete reason to move.
- **Move to `TypeAdapter`s** with `@HiveType(typeId: N)` and
  `dart run build_runner build`. Faster for large collections and gives typed boxes, but
  `typeId`s are permanent — once assigned, never renumber, or old data becomes
  undecodable. Requires a schema-version story the current setup does not have.

Do not start a codegen migration inside an unrelated feature. The `build_runner` /
`hive_generator` entries in `pubspec.yaml` are currently dead weight; remove them if you
confirm the JSON approach is final.

## What Hive does not give you

No queries, no indexes, no relationships. `getAllSessions()` iterates every key and
`jsonDecode`s each value — fine at this data volume, and the reason `StatsViewModel` can
compute weekly muscle stats in memory. If session counts grow into the thousands, this
becomes the bottleneck to revisit, not the box layer.

## Watch streams

`box.watch()` (broadcast `Stream<void>`, fires on any change) and `box.watchKey(key)`
exist if a screen ever needs to react to writes without a manual reload. Current code
relies on explicit `loadX()` calls after mutations instead — keep that, it is easier to
follow.
