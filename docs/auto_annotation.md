# Auto-annotation of generated files

Generated code (Freezed, Riverpod, JsonSerializable, etc.) often lands in `*.g.dart` or related files. To keep visibility consistent, the `more_visibility` post-process builder inserts a file-level annotation for you.

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
      visibility: mprotected # or mdefault
```

Then run:
```
dart run build_runner build --delete-conflicting-outputs
```

## Behavior
- If the file already contains `@mprotected` or `@mdefault`, nothing changes.
- Otherwise the annotation is inserted at the top of the file (after any shebang/comments).
- Default visibility is `mprotected`; set `visibility: mdefault` to change it.

## Customizing targets
You can extend `input_extensions` in your own `build.yaml` to cover other generators (e.g. `.gen.dart`).
