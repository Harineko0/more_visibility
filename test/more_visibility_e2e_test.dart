import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('custom lint integration', () {
    test('flags protected/default violations in the example project', () async {
      final pubGet = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: 'example');
      expect(
        pubGet.exitCode,
        0,
        reason: 'Failed to pub get example: ${pubGet.stderr}',
      );

      final result = await Process.run('dart', [
        'run',
        'custom_lint',
      ], workingDirectory: 'example');

      final output =
          ((result.stdout as String?) ?? '') +
          ((result.stderr as String?) ?? '');

      expect(
        result.exitCode,
        anyOf(0, 1),
        reason: 'custom_lint failed to run: $output',
      );

      expect(
        output,
        contains('more_visibility_module_default'),
        reason: 'Expected @mdefault violation in output.\n$output',
      );
      expect(
        output,
        contains('more_visibility_protected'),
        reason: 'Expected @mprotected violation in output.\n$output',
      );
    });
  });
}
