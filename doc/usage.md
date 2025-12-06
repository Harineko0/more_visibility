# Usage

## Install
```yaml
dependencies:
  more_visibility_annotation: ^0.1.0
dev_dependencies:
  more_visibility: ^0.1.3
```

## Enable the plugin
`analysis_options.yaml`:
```yaml
include: package:more_visibility/more_visibility.yaml
```
This enables the plugin and turns on the diagnostics as errors by default.

## Annotate declarations
- `@mprotected`: usable from the declaration’s directory and its subdirectories.
- `@mdefault`: usable only from the declaration’s directory.

```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected
final shared = 1;

@mdefault
final local = 2;
```

## Annotate a file
Place the annotation above the library or first directive to apply it to every top-level declaration:
```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected
library feature_profile;

final profileCache = <String, String>{}; // inherits @mprotected
```

## Run the lints
```
dart analyze
```
Or rely on your IDE’s analysis server integration.

## Configure severity
```yaml
analyzer:
  errors:
    more_visibility_protected: warning
    more_visibility_module_default: warning
plugins:
  more_visibility:
    diagnostics:
      more_visibility: false # disable entirely
```

## Typical violations
- Accessing an `@mdefault` symbol from a subdirectory.
- Accessing an `@mprotected` symbol from a parent or sibling directory.
- Accessing any annotated symbol without importing `package:more_visibility_annotation/more_visibility_annotation.dart` in the declaring file.
