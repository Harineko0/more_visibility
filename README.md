<div align="center">
<img src="https://img.shields.io/pub/v/more_visibility?label=pub&logo=dart&logoColor=white" alt="Pub">
<img src="https://github.com/Harineko0/more_visibility/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI">
<img src="https://img.shields.io/badge/dart-%E2%89%A53.10-blue" alt="Dart SDK">
<img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</div>

more_visibility
================

Analysis server plugin + post-process builder that brings Java-style "protected" and "default" visibility to Dart projects using the annotations `@mprotected` and `@mdefault`.

What it does
------------
- `@mprotected`: declaration/file is usable from the same directory and any subdirectories.
- `@mdefault`: declaration/file is usable **only** from the same directory.
- Lint powered by `analysis_server_plugin` catches violations at analysis time in IDEs and `dart analyze`.
- Post-process builder automatically stamps generated files (Riverpod, Freezed, etc.) with a file-level annotation so they obey the same visibility rules.

Requirements
------------
- Dart SDK 3.10.0 or later (Flutter SDK 3.38.0 or later)

Quick start
-----------
1. Add dependencies:
```yaml
dependencies:
  more_visibility_annotation: ^0.1.0
dev_dependencies:
  more_visibility: ^0.1.3 # analysis server plugin
  build_runner: any # if you want the auto-annotation builder
```
2. Enable the plugin in `analysis_options.yaml`:
```yaml
plugins:
  more_visibility: ^0.1.3
```
Or for local development:
```yaml
plugins:
  more_visibility:
    path: path/to/more_visibility
```
3. Annotate code:
```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected // usable from lib/ and lib/**
final shared = 1;

@mdefault // usable only inside this directory
final local = 2;
```
4. Run the lints:
```
dart analyze
```
Or your IDE will automatically show violations as you code.

Configuring severity levels
----------------------------
By default, visibility violations are reported as **errors**. You can change the severity level in your `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    # Change all visibility violations to warnings
    more_visibility_protected: warning
    more_visibility_module_default: warning

    # Or set to info (won't fail CI)
    more_visibility_protected: info
    more_visibility_module_default: info

    # Or ignore completely
    more_visibility_protected: ignore
    more_visibility_module_default: ignore
```

Available severity levels:
- `error` (default) - Causes analysis to fail
- `warning` - Shown as warning, doesn't fail analysis by default
- `info` - Informational only
- `ignore` - Suppresses the diagnostic

File-level annotations
----------------------
Annotate an entire file to give every declaration the same visibility:
```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected
library feature_auth;

// Everything in this file inherits the @mprotected rule.
```

Auto-annotating generated files
-------------------------------
Add the post-process builder so generated files copy the declaration-level visibility from their source part:
```yaml
# build.yaml in your app/repo
targets:
  $default:
    builders:
      more_visibility:auto_annotate:
        enabled: true

post_process_builders:
  more_visibility:auto_annotate:
    options:
      visibility: mprotected # fallback if source has no annotated declaration
```
Then run:
```
dart run build_runner build --delete-conflicting-outputs
```
The builder inserts `@mprotected` (or `@mdefault`) at the top of matching generated files (`*.g.dart`, `*.freezed.dart`, `*.riverpod.dart`) unless they are already annotated.
The builder copies the first declaration-level `@mprotected`/`@mdefault` from the source part file into the generated file (after `part of`), so generated declarations share the same visibility. File-level annotations are not copied because parts share library metadata automatically.

Example project
---------------
See `example/` for a minimal project showing allowed/blocked usages and how the lint reports violations.

Testing
-------
Run the package tests, which include an end-to-end lint invocation and builder coverage:
```
dart test
```

More info
---------
- `docs/usage.md`: setup steps and idioms
- `docs/visibility_rules.md`: rule details and edge cases
- `docs/auto_annotation.md`: builder options and integration notes
