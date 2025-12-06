import 'package:more_visibility/src/builders/annotate_generated_builder.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotateGeneratedBuilder', () {
    test('adds annotation when missing', () {
      const original = '// generated file\nclass A {}\n';
      final builder = AnnotateGeneratedBuilder(defaultVisibility: 'mprotected');

      final updated = builder.annotateContent(original, 'mprotected');

      expect(updated, contains('@mprotected'));
      expect(updated, startsWith('// generated file\n@mprotected'));
    });

    test('respects existing annotations', () {
      const original = '@mdefault\nclass A {}\n';
      final builder = AnnotateGeneratedBuilder(defaultVisibility: 'mprotected');

      final updated = builder.annotateContent(original, 'mprotected');

      expect(updated, original);
    });
  });
}
