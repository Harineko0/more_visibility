# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`more_visibility` is a Dart package that implements Java-style visibility modifiers (`@mprotected` and `@mdefault`) for Dart projects through:
1. **Analysis server plugin** (`analysis_server_plugin`) that enforces visibility rules at analysis time
2. **Post-process builder** (`build_runner`) that auto-annotates generated files (`.g.dart`, `.freezed.dart`, `.riverpod.dart`)

This is a monorepo containing two packages:
- `more_visibility/` - main analysis server plugin and builder
- `more_visibility_annotation/` - annotation definitions (`@mprotected`, `@mdefault`)

## Requirements

- Dart SDK 3.10.0 or later (Flutter SDK 3.38.0 or later)
- The `analysis_server_plugin` package requires Dart 3.10+

## Common Commands

### Testing
```bash
# Run all tests (includes analyzer invocation and builder tests)
dart test

# Run analyzer manually (useful for testing lint rules)
dart analyze

# Run builder (processes generated files)
dart run build_runner build --delete-conflicting-outputs
```

### Development
```bash
# Get dependencies (requires Dart SDK 3.10.0+)
dart pub get

# Analyze code
dart analyze
```

## Architecture

### Plugin Entry Point

The plugin entry point is `lib/main.dart` (required by `analysis_server_plugin`):
- Exports a top-level `plugin` variable of type `Plugin`
- `MoreVisibilityPlugin` extends `Plugin` and registers rules via `register()`
- Rules are registered as warnings (enabled by default)

### Visibility Rule System

The core lint rule logic is in `lib/src/rules/more_visibility_rule.dart`:

1. **Rule Structure**:
   - `MoreVisibilityRule` extends `AnalysisRule` (from `analysis_server_plugin`)
   - Implements `registerNodeProcessors()` to register AST node visitors
   - Uses a `_Visitor` class extending `SimpleAstVisitor` to process nodes

2. **Annotation detection**: Uses `lib/src/utils/annotation_utils.dart` to extract `@mprotected`/`@mdefault` from:
   - Declaration-level metadata (functions, classes, etc.)
   - File-level metadata (library directives)
   - Library-level metadata (fallback)

3. **Scope calculation**: Directory-based validation using `path` package:
   - `@mprotected`: allows same directory and all subdirectories
   - `@mdefault`: allows only same directory (no subdirectories)

4. **Caching**: Uses `_FileAnnotationCache` per-visitor instance to cache file-level annotations, improving performance

5. **Error Reporting**: Uses `RuleContext.reportError()` with `getNodeLocation()` to report violations

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

### User Configuration

Users enable the plugin in `analysis_options.yaml`:
```yaml
plugins:
  more_visibility: ^0.1.3
```

After changing plugin configuration, the Dart Analysis Server must be restarted.

## Key Implementation Details

### Visibility Enforcement

The lint checks happen via visitor pattern:
1. `_Visitor` registers processors for `CompilationUnit` and `SimpleIdentifier` nodes
2. `visitCompilationUnit()` captures file-level annotations in cache
3. `visitSimpleIdentifier()` checks each identifier usage:
   - Skip identifiers in declaration context
   - Resolve element to top-level declaration
   - Check annotation on element, file, or library
   - Compare declaring directory vs. usage directory using `path.isWithin()`
   - Report violation via `RuleContext.reportError()` if not allowed

### File vs. Declaration Annotations

- **Declaration-level**: Annotate individual functions/classes
- **File-level**: Annotate `library` directive (applies to all declarations unless overridden)
- **Priority**: Declaration-level > File-level > Library-level

### Generated File Handling

The builder only copies **declaration-level** annotations from source parts, not file-level annotations, because parts automatically share library metadata.

## Testing Notes

- `test/more_visibility_e2e_test.dart`: End-to-end analyzer invocation test using `dart analyze`
- `test/auto_annotate_builder_test.dart`: Builder behavior tests
- Example project in `example/` demonstrates allowed/blocked usage patterns
- Tests require Dart SDK 3.10.0+ due to `analysis_server_plugin` dependency

## Documentation

- `doc/visibility_rules.md`: Detailed rule specifications
- `doc/auto_annotation.md`: Builder options and integration
- `doc/usage.md`: Setup and usage patterns
