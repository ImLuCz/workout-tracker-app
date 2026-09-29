---
name: Build Runner and Codegen
description: Run and troubleshoot build_runner / hive_generator, and add Dart code generation. Use for `dart run build_runner build`, generated-file problems, builder config in build.yaml, or deciding whether codegen is warranted at all.
---

# build_runner and Codegen

`build_runner` 2.4.13 and `hive_generator` 2.0.1 are **dev dependencies that currently
generate nothing.** There is no `build.yaml`, no `*.g.dart` file, and no `@HiveType` /
`@HiveField` / `@GenerateAdapters` annotation anywhere in `lib/`.

Latest: `build_runner` 2.16.1 (sdk `^3.11.0`).

Check before doing anything:

```bash
grep -rn "HiveType\|HiveField\|@GenerateAdapters\|part '.*\.g\.dart'" lib/
ls build.yaml
```

No hits means codegen is dormant. Persistence is done with hand-written JSON in the
repositories — see the `hive-persistence` skill.

## Commands

```bash
dart run build_runner build      # one-shot generation
dart run build_runner watch      # regenerate on save (dev loop)
dart run build_runner clean      # clear the build cache
```

- `build` is the one to run for a commit. `watch` is for while you iterate.
- After changing an annotation or a generated model's fields, re-run `build` before
  analyzing — a stale `.g.dart` produces confusing errors in files that look untouched.
- `--delete-conflicting-outputs` is only needed if you hit a
  "conflicting outputs" error, which means a previously generated file is in the way.

## `build.yaml`

```yaml
targets:
  $default:
    builders:
      hive_generator:
        options:
          adapter_name_prefix: ''
        generate_for:
          - lib/domain/models/*.dart
```

`generate_for` is the useful knob: it restricts a builder to specific paths so it does
not run across the whole tree. `options` vary per builder — always check the builder's
own docs before adding keys.

## If you do adopt adapters

The generated `TypeAdapter`s use **permanent integer `typeId`s**. Once a `typeId` ships to
a user's device it can never be reused or renumbered — old data becomes undecodable.
Pick ids deliberately, never auto-increment casually, and keep a written record in the
model file.

`hive_generator` is the unmaintained 2.0.1 that pairs with the frozen `hive` 2.2.3. The
maintained path is `hive_ce_generator` (1.11.3) with `hive_ce`, which replaces per-field
annotations with a single `@GenerateAdapters` on a registry class. Adopting that means
migrating the storage layer — see `hive-persistence`. Do not start it inside an unrelated
feature.

## Recommendation for this repo

The JSON-string approach already works and has no codegen step. If the decision is to
stay on it, **delete `build_runner` and `hive_generator` from `pubspec.yaml`** — two dev
dependencies that cost a resolution and generate nothing are worse than no entries at
all. That is a one-line change plus a `flutter pub get`; do it as its own commit.
