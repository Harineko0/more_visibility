import 'dart:io';

import 'package:dartv/dartv.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DartvAnalyzer', () {
    late Directory workspace;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp('dartv_unit_test_');
    });

    tearDown(() async {
      await workspace.delete(recursive: true);
    });

    test('honors file-level and declaration-level annotations', () async {
      final libDir = Directory(p.join(workspace.path, 'lib'))..createSync();
      File(p.join(libDir.path, 'source.dart')).writeAsStringSync('''
import 'package:dartv/dartv.dart' as dartv;

@dartv.protected
import 'dart:math';

final shared = sqrt(4);

@dartv.packagePrivate
final secret = 2;
''');

      final okDir = Directory(p.join(libDir.path, 'ok'))..createSync();
      File(p.join(okDir.path, 'use_shared.dart')).writeAsStringSync('''
import '../source.dart';

final value = shared + 1;
''');

      final badDir = Directory(p.join(libDir.path, 'violating'))..createSync();
      File(p.join(badDir.path, 'use_secret.dart')).writeAsStringSync('''
import '../source.dart';

final value = secret;
''');

      final analyzer = DartvAnalyzer();
      final violations = await analyzer.analyzePaths([workspace.path]);

      expect(violations, hasLength(1));
      expect(
        p.relative(violations.single.referencePath, from: workspace.path),
        p.join('lib', 'violating', 'use_secret.dart'),
      );
      expect(violations.single.scope, VisibilityScope.packagePrivate);
    });
  });
}
