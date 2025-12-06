import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartv/dartv.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'dartv',
    'Visibility checker for @protected and @packagePrivate annotations.',
  )..addCommand(_AnalyzeCommand());

  try {
    final code = await runner.run(arguments) ?? 0;
    exit(code);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(e.usage);
    exit(64);
  }
}

class _AnalyzeCommand extends Command<int> {
  _AnalyzeCommand() {
    argParser.addFlag(
      'quiet',
      abbr: 'q',
      help: 'Suppress success output; only print violations.',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Analyze a file or directory tree for dartv visibility violations.';

  @override
  Future<int> run() async {
    if (argResults == null || argResults!.rest.isEmpty) {
      throw UsageException('Provide a file or directory path.', usage);
    }

    final targets = argResults!.rest;
    final analyzer = DartvAnalyzer();
    final violations = await analyzer.analyzePaths(targets);

    if (violations.isEmpty) {
      if (!(argResults!['quiet'] as bool)) {
        stdout.writeln('No visibility issues found.');
      }
      return 0;
    }

    stdout.writeln('Found ${violations.length} visibility violation(s):');
    final cwd = Directory.current.path;
    String formatPath(String path) => p.relative(path, from: cwd);
    for (final violation in violations) {
      stdout.writeln(' - ${violation.describe(pathFormatter: formatPath)}');
    }

    return 1;
  }
}
