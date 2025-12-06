# dartv

`dartv` is a tiny static analyzer that adds Java-style visibility boundaries to
Dart code using two annotations:

- `@protected`: declarations are visible to the defining directory **and** its
  subdirectories.
- `@packagePrivate`: declarations are visible only to the defining directory.

Run `dartv analyze <path>` to flag imports or references that violate those
rules.

## Install

Add the dependency (local path or git until published):

```bash
dart pub add dartv
```

## How it works

1. Add the annotations to a file or declaration.
2. Run the CLI against a directory or file tree.
3. Violations are reported with file/line/column and a non-zero exit code.

File-level annotations are applied to metadata on directives (imports, exports,
parts, library). Declaration-level annotations override the file default.

```dart
import 'package:dartv/dartv.dart' as dartv;

@dartv.protected // file default: visible to this dir + subdirs
import 'dart:math';

final publicWithinTree = sqrt(4); // inherits @protected

@dartv.packagePrivate
final privateToFolder = 2; // visible only to this folder
```

## CLI

```bash
dart run bin/dartv.dart analyze path/to/lib
```

- `--quiet` / `-q` silences the success message.
- Exit code `0` when clean, `1` when violations exist, `64` on invalid usage.

Example output:

```
Found 1 visibility violation(s):
 - lib/nested/use_rules.dart:3:8 uses internalToken from lib/rules.dart which is package-private (directory only)
```

## Library API

You can embed the analyzer:

```dart
import 'package:dartv/dartv.dart';

final analyzer = DartvAnalyzer();
final violations = await analyzer.analyzePaths(['lib']);
```

See `doc/` for rule details and architecture notes.
