# Visibility rules

`dartv` introduces two annotations that mimic Java-style visibility:

- `@protected` — declarations are visible to the defining directory and any
  subdirectories.
- `@packagePrivate` — declarations are visible only to the defining directory.

## Where to place annotations

- **File-level**: place the annotation on the first directive (library/import/
  export/part) in the file. The rule becomes the default for all top-level
  declarations in that file.
- **Declaration-level**: place the annotation directly on a top-level
  declaration to override the file default.

`import 'package:dartv/dartv.dart' as dartv;` must appear before the metadata so
the annotation symbol is in scope. Example:

```dart
import 'package:dartv/dartv.dart' as dartv;

@dartv.protected // file-level
import 'dart:math';

final shared = sqrt(4); // inherits @protected

@dartv.packagePrivate
final onlyHere = 2;
```

## How violations are detected

- The analyzer records every annotated top-level declaration (functions,
  variables, classes, enums, typedefs, extensions, and constructors).
- When a resolved identifier refers to one of those declarations, `dartv`
  compares the referencing file's directory with the defining file's
  directory:
  - `@protected`: allowed in the same directory or any subdirectory.
  - `@packagePrivate`: allowed only in the same directory.
  - Same file is always allowed.
- Everything else is treated as public.
