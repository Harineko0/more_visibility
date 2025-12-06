# Architecture

`dartv` follows a small, focused pipeline:

1. Collect Dart files from the provided paths (skipping build, .git, and
   .dart_tool).
2. Build an `AnalysisContextCollection` and request resolved units.
3. Pass 1: record annotated declarations with their paths and visibility.
   Constructors and accessors are aliased to the same rule to catch all uses.
4. Pass 2: visit every `SimpleIdentifier` and, when it resolves to a tracked
   element, compare directories to decide if the use is allowed.
5. Return a list of `VisibilityViolation` objects; the CLI formats them and
   exits with `1` when non-empty.

## Key types

- `DartvAnalyzer`: orchestrates the two-pass analysis.
- `VisibilityScope`: enum for public/protected/packagePrivate.
- `VisibilityViolation`: output shape with paths, positions, and scope.

## CLI

The CLI is a thin wrapper built with `args.CommandRunner`. It supports one
command, `analyze`, and a `--quiet` flag. The CLI reuses the library analyzer
for consistency.
