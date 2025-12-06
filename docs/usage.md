# Usage

## Install
```yaml
dependencies:
  more_visibility: ^0.1.0
dev_dependencies:
  custom_lint: any
```

## Enable the plugin
`analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - custom_lint
```

## Annotate declarations
- `@mprotected`: usable from the declaration’s directory and its subdirectories.
- `@mdefault`: usable only from the declaration’s directory.

```dart
import 'package:more_visibility/annotations.dart';

@mprotected
final shared = 1;

@mdefault
final local = 2;
```

## Annotate a file
Place the annotation above the library or first directive to apply it to every top-level declaration:
```dart
import 'package:more_visibility/annotations.dart';

@mprotected
library feature_profile;

final profileCache = <String, String>{}; // inherits @mprotected
```

## Run the lints
```
dart run custom_lint
```

## Typical violations
- Accessing an `@mdefault` symbol from a subdirectory.
- Accessing an `@mprotected` symbol from a parent or sibling directory.
- Accessing any annotated symbol without importing `package:more_visibility/annotations.dart` in the declaring file.
