# Auto-annotation of generated files

Generated code (Freezed, Riverpod, JsonSerializable, etc.) often lands in `*.g.dart` or related files. To keep visibility consistent, the `more_visibility` post-process builder copies the first declaration-level visibility annotation (`@mprotected` or `@mdefault`) from the source part file into the generated file so generated declarations share the same scope. File-level annotations are not copied (the analyzer already shares library-level annotations across parts).

**Note:** The auto-annotation builder only handles `@mprotected` and `@mdefault` annotations. The `directory_private` rule is enforced automatically based on directory names (no annotations needed), so generated files in `_*` directories are automatically subject to the same depth restrictions.

## Enable
Add to your project’s `build.yaml`:
```yaml
post_process_builders:
  more_visibility:auto_annotate:
    import: "package:more_visibility/auto_annotate_builder.dart"
    builder_factory: "annotateGenerated"
    input_extensions:
      - ".g.dart"
      - ".freezed.dart"
      - ".riverpod.dart"
    options:
      visibility: mprotected # fallback if no declaration-level annotation found
```

Then run:
```
dart run build_runner build --delete-conflicting-outputs
```

## Behavior
- Looks for the first declaration-level `@mprotected`/`@mdefault` in the source part file.
- If found and the generated file has no visibility annotation, the builder inserts that annotation just after the `part of` directive.
- If no declaration-level annotation is found, the builder uses the configured fallback (`visibility`, default `mprotected`).
- File-level annotations (`@mprotected` above `library` or `part`) are **not** copied because Dart parts already share library metadata.

## Customizing targets
You can extend `input_extensions` in your own `build.yaml` to cover other generators (e.g. `.gen.dart`).
