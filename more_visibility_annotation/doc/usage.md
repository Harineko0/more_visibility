# Usage

```yaml
dependencies:
  more_visibility_annotation: ^0.1.0
```

```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

@mprotected
class Shared {}

@mdefault
final local = 0;
```

Pair this with the `more_visibility` custom lint in your main project to enforce directory-scoped visibility.
