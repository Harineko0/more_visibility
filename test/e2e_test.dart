import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('dartv analyze CLI reports violations', () async {
    final workspace = await Directory.systemTemp.createTemp('dartv_e2e_');
    addTearDown(() => workspace.delete(recursive: true));
    final libDir = Directory(p.join(workspace.path, 'lib'))..createSync();

    File(p.join(libDir.path, 'rules.dart')).writeAsStringSync('''
import 'package:dartv/dartv.dart' as dartv;

@dartv.packagePrivate
final internalToken = 'secret';
''');

    final nested = Directory(p.join(libDir.path, 'nested'))..createSync();
    File(p.join(nested.path, 'use_rules.dart')).writeAsStringSync('''
import '../rules.dart';

void leak() {
  print(internalToken);
}
''');

    final result = await Process.run('dart', [
      'run',
      'bin/dartv.dart',
      'analyze',
      workspace.path,
    ], workingDirectory: Directory.current.path);

    expect(result.exitCode, 1);
    expect(result.stdout.toString(), contains('Found 1 visibility violation'));
    expect(result.stdout.toString(), contains('use_rules.dart'));
  });
}
