# Usage

## Install
```yaml
dependencies:
  more_visibility_annotation: ^0.1.0
dev_dependencies:
  more_visibility: ^0.1.10
```

## Enable the plugin
`analysis_options.yaml`:
```yaml
include: package:more_visibility/more_visibility.yaml
```
This enables the plugin and turns on the diagnostics as errors by default.

## Directory-private (automatic)

Create directories with underscore prefixes to automatically enforce same-depth access:

```
lib/
├── pages/
│   ├── page.dart           # ✅ Can import _components/button.dart
│   ├── _components/
│   │   └── button.dart     # Private to lib/pages/ depth
│   └── profile/
│       └── page.dart       # ❌ Cannot import _components/button.dart
```

No annotations needed — the `directory_private` rule is enforced automatically for any directory starting with `_`.

**Note:** This rule only applies to application code (your project's `lib/`, `test/`, etc.). Dependencies in `.pub-cache` or `.dart-tool` are excluded from enforcement.

## Annotate declarations
- `@mprotected`: usable from the declaration's directory and its subdirectories.
- `@mdefault`: usable only from the declaration's directory.

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
    directory_private: warning           # default: error
    more_visibility_protected: warning   # default: error
    more_visibility_module_default: warning # default: error
plugins:
  more_visibility:
    diagnostics:
      directory_private: false              # disable directory-private rule
      more_visibility_protected: false      # disable @mprotected rule
      more_visibility_module_default: false # disable @mdefault rule
```

## Typical violations

### directory_private violations
- Importing a file from a `_*` directory at a different package depth.
- Example: `lib/bar.dart` importing `lib/pages/_components/button.dart`.

### Annotation-based violations
- Accessing an `@mdefault` symbol from a subdirectory.
- Accessing an `@mprotected` symbol from a parent or sibling directory.
- Accessing any annotated symbol without importing `package:more_visibility_annotation/more_visibility_annotation.dart` in the declaring file.
