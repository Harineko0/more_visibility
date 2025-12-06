# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: analysis server plugin and builder entrypoints (`main.dart`, `auto_annotate_builder.dart`) plus rule logic under `lib/src/{builders,rules,utils}`.
- `more_visibility_annotation/`: published annotation package; keep it version-aligned with the plugin.
- `doc/`: how-to guides (`usage.md`, `visibility_rules.md`, `auto_annotation.md`).
- `example/`: minimal app demonstrating annotations and auto-annotation; good for manual sanity checks.
- `test/`: package:test suites (`auto_annotate_builder_test.dart`, `more_visibility_e2e_test.dart`). Add new suites in the same folder with `_test.dart` suffix.

## Build, Test, and Development Commands
- Install deps: `dart pub get` (run in both root and `more_visibility_annotation/` when dependencies change).
- Static analysis: `dart analyze` (root). CI treats visibility diagnostics as errors; keep the analyzer clean.
- Format: `dart format .` (root) and `dart format .` inside `more_visibility_annotation/` before sending a PR.
- Tests: `dart test` (root) runs unit + e2e coverage. For the sample app, `cd example && dart test`.
- Builder check (for downstream apps): `dart run build_runner build --delete-conflicting-outputs` to verify auto-annotation behavior.

## Coding Style & Naming Conventions
- Follow `package:lints/recommended` (see `analysis_options.yaml`); prefer small, composable functions.
- Dart defaults: 2-space indentation, trailing commas to aid formatting, `_` prefix for private members.
- Keep rule and builder utilities under `lib/src/` by concern; avoid public exports unless intended for package API.

## Testing Guidelines
- Framework: `package:test`. Keep tests hermetic; avoid network/file writes outside temp dirs.
- Name files with `_test.dart` and group cases with `group()`/`test()` describing the rule or builder scenario.
- Add fixtures in test resources or inline strings; assert diagnostics via matcher helpers already in use.
- Run `dart test` before PRs; add new cases for lint edge paths and builder regressions.

## Commit & Pull Request Guidelines
- Commits in history use short, imperative subjects (e.g., "Fix CI", "Migrate to analysis_server_plugin"). Follow that style; squash locally if noisy.
- PRs: include summary of behavior change, affected rules/builders, and links to related issues. Mention new commands/config flags if added. Screenshots are unnecessary; paste sample diagnostics when relevant.
- Keep changelog entries if user-facing behavior changes (mirror existing `CHANGELOG.md` format in each package).

## Security & Configuration Tips
- No network access is required for tests; keep tests offline-safe.
- When updating analyzer or build_runner versions, rerun `dart analyze` and `dart test` to catch API shifts.
- Prefer relative `path` usage and avoid hard-coded absolute paths in tests or builders.
