import 'package:dartv/dartv.dart';

@protected
import 'dart:math';

// Visible to this directory and subdirectories because of the file-level
// @protected above.
final sharedCounter = sqrt(4);

// Visible only to this directory.
@packagePrivate
final hiddenValue = 42;

void main() {
  print(
    'Protected sample: $sharedCounter, package-private sample: $hiddenValue',
  );
}
