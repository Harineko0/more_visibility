import 'package:more_visibility/src/builders/annotate_generated_builder.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotateGeneratedBuilder', () {
    test('copies annotation from part source', () {
      const generated = '''
// GENERATED CODE
part of 'feature.dart';

class _\$Feature {}
''';

      final builder = AnnotateGeneratedBuilder(defaultVisibility: 'mprotected');

      final updated = builder.annotateContent(
        generated,
        '@mprotected',
        'mprotected',
      );

      expect(updated, contains("part of 'feature.dart';\n@mprotected"));
    });

    test('respects existing annotations', () {
      const original = '@mdefault\nclass A {}\n';
      final builder = AnnotateGeneratedBuilder(defaultVisibility: 'mprotected');

      final updated = builder.annotateContent(
        original,
        '@mprotected',
        'mprotected',
      );

      expect(updated, original);
    });
  });
}
