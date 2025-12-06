# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`more_visibility` is a Dart package that implements Java-style visibility modifiers (`@mprotected` and `@mdefault`) for Dart projects through:
1. **Custom lint plugin** (`custom_lint_builder`) that enforces visibility rules at analysis time
2. **Post-process builder** (`build_runner`) that auto-annotates generated files (`.g.dart`, `.freezed.dart`, `.riverpod.dart`)

This is a monorepo containing two packages:
- `more_visibility/` - main custom_lint plugin and builder
- `more_visibility_annotation/` - annotation definitions (`@mprotected`, `@mdefault`)

## Common Commands

### Testing
```bash
# Run all tests (includes lint invocation and builder tests)
dart test

# Run custom_lint manually (useful for testing lint rules)
dart run custom_lint

# Run builder (processes generated files)
dart run build_runner build --delete-conflicting-outputs
```

### Development
```bash
# Get dependencies
dart pub get

# Analyze code
dart analyze
```

## Architecture

### Visibility Rule System

The core lint rule logic is in `lib/src/rules/more_visibility_rule.dart`:

1. **Annotation detection**: Uses `lib/src/utils/annotation_utils.dart` to extract `@mprotected`/`@mdefault` from:
   - Declaration-level metadata (functions, classes, etc.)
   - File-level metadata (library directives)
   - Library-level metadata (fallback)

2. **Scope calculation**: Directory-based validation using `path` package:
   - `@mprotected`: allows same directory and all subdirectories
   - `@mdefault`: allows only same directory (no subdirectories)

3. **Caching**: Uses `_FileAnnotationCache` in shared state to cache file-level annotations across multiple identifier checks, improving performance

### Builder System

The post-process builder (`lib/src/builders/annotate_generated_builder.dart`) runs after code generation:

1. **Input**: Generated files matching `*.g.dart`, `*.freezed.dart`, `*.riverpod.dart`
2. **Logic**:
   - Locates source part file
   - Extracts first declaration-level annotation from source
   - Inserts annotation after `part of` directive in generated file
   - Falls back to `build.yaml` default if no source annotation found
3. **Output**: Modified generated file with visibility annotation

Configuration in `build.yaml`:
- `targets.$default.builders` enables the builder
- `post_process_builders.more_visibility:auto_annotate` defines input extensions and fallback visibility

### Plugin Registration

The custom_lint plugin entry point is `lib/more_visibility.dart`:
- Exports `createPlugin()` which returns `MoreVisibilityPlugin`
- `MoreVisibilityPlugin` (in `lib/src/plugin.dart`) registers `MoreVisibilityRule`

## Key Implementation Details

### Visibility Enforcement

The lint checks happen on `SimpleIdentifier` nodes:
1. Skip identifiers in declaration context
2. Resolve element to top-level declaration
3. Check annotation on element, file, or library
4. Compare declaring directory vs. usage directory using `path.isWithin()`
5. Report violation if not allowed

### File vs. Declaration Annotations

- **Declaration-level**: Annotate individual functions/classes
- **File-level**: Annotate `library` directive (applies to all declarations unless overridden)
- **Priority**: Declaration-level > File-level > Library-level

### Generated File Handling

The builder only copies **declaration-level** annotations from source parts, not file-level annotations, because parts automatically share library metadata.

## Testing Notes

- `test/more_visibility_e2e_test.dart`: End-to-end lint invocation test
- `test/auto_annotate_builder_test.dart`: Builder behavior tests
- Example project in `example/` demonstrates allowed/blocked usage patterns

## Documentation

- `doc/visibility_rules.md`: Detailed rule specifications
- `doc/auto_annotation.md`: Builder options and integration
- `doc/usage.md`: Setup and usage patterns
