Contributing
============

Thanks for helping improve `more_visibility`!

How to work locally
-------------------
- Install dependencies: `dart pub get` (and `dart pub get` in `example/`).
- Format before sending changes: `dart format .`.
- Run tests: `dart test`.
- Run the lint against the example to verify rule output: `dart run custom_lint --path example`.

Guidelines
----------
- Keep changes small and focused (single responsibility).
- Prefer clear, minimal diagnostics; avoid noisy output.
- Add tests for new behaviors (unit + e2e when possible).
- Update docs (README, docs/*.md) when behavior or setup changes.

Releases
--------
- Update `CHANGELOG.md`.
- Bump the version in `pubspec.yaml`.
