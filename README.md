<div align="center">
<img src="https://img.shields.io/pub/v/more_visibility?label=pub&logo=dart&logoColor=white" alt="Pub">
<img src="https://github.com/Harineko0/more_visibility/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI">
<img src="https://img.shields.io/badge/dart-%E2%89%A53.10-blue" alt="Dart SDK">
<img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</div>

more_visibility
================

Analysis server plugin + post-process builder that provides enhanced visibility control for Dart projects:
- Java-style "protected" and "default" visibility using `@mprotected` and `@mdefault` annotations
- Directory-private enforcement for underscore-prefixed directories (e.g., `_components`, `_hooks`)

## Table of contents
- [Getting started](#getting-started)
- [Annotations](#annotations)
- [Directory-private](#directory-private)
- [Configuring severity and disabling](#configuring-severity-and-disabling)
- [Ignoring the rule](#ignoring-the-rule)
- [Auto-annotating generated files](#auto-annotating-generated-files)
- [Example project](#example-project)
- [Testing](#testing)

What it does
------------
- `@mprotected`: declaration/file is usable from the same directory and any subdirectories.
- `@mdefault`: declaration/file is usable **only** from the same directory.
- **Directory-private** (automatic): underscore-prefixed directories like `_components` or `_hooks` are only accessible from files at the same package depth.
  - Example: `lib/pages/_components/button.dart` can be imported by `lib/pages/page.dart` or `lib/pages/_hooks/use_foo.dart`, but NOT by `lib/bar.dart` or `lib/pages/profile/page.dart`.
- Analysis rule powered by `analysis_server_plugin` catches violations at analysis time in IDEs and `dart analyze`.
- Post-process builder automatically stamps generated files (Riverpod, Freezed, etc.) with a file-level annotation so they obey the same visibility rules.

Requirements
------------
- Dart SDK 3.10.0 or later (Flutter SDK 3.38.0 or later)

Getting started
---------------
1. Add dependencies:
```yaml
dependencies:
  more_visibility_annotation: ^0.1.0
dev_dependencies:
  more_visibility: ^0.1.3 # analysis server plugin
  build_runner: any # if you want the auto-annotation builder
```
2. Include the preset analysis options (enables the plugin, diagnostics on as errors by default):
```yaml
include: package:more_visibility/more_visibility.yaml
```
If you already include another lint bundle, copy the plugin block from `lib/all_visibility_rules.yaml` into your own `analysis_options.yaml`.

Annotations
-----------
Mark declarations or files to scope their visibility:
```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected // usable from lib/ and lib/**
final shared = 1;

@mdefault // usable only inside this directory
final local = 2;
```

Directory-private
-----------------
Files in underscore-prefixed directories (like `_components`, `_hooks`, `_utils`) are automatically restricted to files at the same package depth. **No annotations required** — this rule is enforced automatically.

### How it works
A file inside a private directory can only be imported by files whose "package directory" (the path before any `_*` directory) matches.

### Examples

**Project structure:**
```
lib/
├── bar.dart
└── pages/
    ├── page.dart
    ├── _components/
    │   └── button.dart
    ├── _hooks/
    │   └── use_something.dart
    └── profile/
        └── page.dart
```

**Allowed imports:**
```dart
// lib/pages/page.dart
import '_components/button.dart'; // ✅ Same depth (lib/pages/)

// lib/pages/_hooks/use_something.dart
import '../_components/button.dart'; // ✅ Same depth (lib/pages/)
```

**Blocked imports:**
```dart
// lib/bar.dart
import 'pages/_components/button.dart'; // ❌ Different depth (lib/ vs lib/pages/)

// lib/pages/profile/page.dart
import '../_components/button.dart'; // ❌ Different depth (lib/pages/profile/ vs lib/pages/)
```

### Error severity
The `directory_private` rule defaults to **error** severity and will fail CI builds. Configure in `analysis_options.yaml`:
```yaml
analyzer:
  errors:
    directory_private: warning # or info, or ignore
```

Configuring severity and disabling
----------------------------------
Visibility violations default to **errors** (configured in `lib/more_visibility.yaml`). Override per project:

```yaml
analyzer:
  errors:
    # Change visibility violations to warnings
    directory_private: warning
    more_visibility_protected: warning
    more_visibility_module_default: warning

    # Or set to info (won't fail CI)
    directory_private: info
    more_visibility_protected: info
    more_visibility_module_default: info

    # Or ignore completely
    directory_private: ignore
    more_visibility_protected: ignore
    more_visibility_module_default: ignore

plugins:
  more_visibility:
    diagnostics:
      # Disable individual rules
      directory_private: false
      more_visibility_protected: false
      more_visibility_module_default: false
```

Ignoring the rule
-----------------
Use analysis ignores when you need an escape hatch:

```dart
// ignore_for_file: directory_private, more_visibility_protected, more_visibility_module_default

// ignore: directory_private
import 'pages/_components/button.dart'; // bypass directory-private check

// ignore: more_visibility_protected
final value = exposedFromSibling;
```

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
