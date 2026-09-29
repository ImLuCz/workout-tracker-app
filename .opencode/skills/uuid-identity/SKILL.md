---
name: UUID Identity
description: Generate and handle entity IDs. Use when creating a routine, session, or exercise, or when a model field is an id.
---

# UUID Identity

`uuid` 4.6.0 — current latest, no upgrade needed. SDK `>=3.0.0 <4.0.0`.

## Usage in this project

One `Uuid` instance per class, as a `final` field, then `v4()`:

```dart
class RoutineViewModel extends ChangeNotifier {
  final _uuid = const Uuid();

  // ...
  id: _uuid.v4(),
}
```

`const Uuid()` allocates nothing and is safe as a field initializer. Do **not** write
`const Uuid().v4()` at each call site (as `CustomExerciseRepository.generateId()` does) —
hoist it to a field for consistency. `Uuid.v4()` uses a cryptographically strong
`CryptoRNG` by default, so no `V4Options` is needed anywhere in this app.

## Rules

- UUIDs are the **Hive box keys** for `routines`, `sessions`, and `custom_exercises`.
  A generated id must be stable for the life of the record — never regenerate one on
  update. `RoutineViewModel.save()` correctly reuses `_editingId` and only calls
  `_uuid.v4()` for new records; preserve that.
- `WorkoutSet` also gets a uuid per set, so a session can grow many of them. Generating
  one per set is fine at this scale.
- IDs are `String` throughout — models, repository parameters, and route query
  parameters. Do not introduce a `UuidValue` type in one layer only.
- v4 is correct for this app. Do not switch to v7 (time-ordered) for "sortability" —
  `SessionRepository` already sorts by `startTime`, not by id.
- Never `parse` an id that came from the app itself. If you must validate untrusted
  input, `UuidParsing.isValidUUID(value)` exists, but ids arrive from our own routes and
  repositories.

## Where they are generated

| Place | What gets an id |
|---|---|
| `RoutineViewModel.addExercise` | `RoutineExercise` |
| `RoutineViewModel.save` | `WorkoutRoutine` (new only) |
| `WorkoutViewModel.createSession` | `WorkoutSession` |
| `WorkoutViewModel._defaultSetsForExercise` | each `WorkoutSet` |
| `CustomExerciseRepository.generateId` | `CustomExercise` |

Any new stored entity needs a uuid field plus a generator call in its view model or
repository.
