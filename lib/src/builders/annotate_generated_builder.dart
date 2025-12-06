import 'dart:async';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

/// Post-processes generated files to stamp them with a file-level annotation
/// so the custom lint understands their intended visibility.
class AnnotateGeneratedBuilder implements PostProcessBuilder {
  AnnotateGeneratedBuilder({required this.defaultVisibility});

  final String defaultVisibility;

  @override
  Iterable<String> get inputExtensions => const [
    '.g.dart',
    '.freezed.dart',
    '.riverpod.dart',
  ];

  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) async {
    final content = await buildStep.readInputAsString();
    final updated = annotateContent(content, defaultVisibility);
    if (updated != content) {
      await buildStep.writeAsString(buildStep.inputId, updated);
      log.info(
        'more_visibility: added @$defaultVisibility to ${buildStep.inputId.path}',
      );
    }
  }

  /// Injects the annotation at the very top of a Dart file, after a shebang or
  /// header comment if one exists.
  String annotateContent(String content, String visibility) {
    if (content.contains('@mprotected') || content.contains('@mdefault')) {
      return content;
    }

    final lines = content.split('\n');
    final buffer = StringBuffer();
    var index = 0;

    // Preserve shebangs and leading comments.
    while (index < lines.length &&
        (lines[index].startsWith('#!') ||
            lines[index].trim().startsWith('//') ||
            lines[index].trim().isEmpty)) {
      buffer.writeln(lines[index]);
      index++;
    }

    final annotationLine = visibility == 'mdefault'
        ? '@mdefault'
        : '@mprotected';
    buffer.writeln(annotationLine);

    for (; index < lines.length; index++) {
      buffer.writeln(lines[index]);
    }

    return buffer.toString();
  }
}

/// Convenience helper to resolve a readable directory path from an asset ID.
String enclosingDir(AssetId id) {
  final parts = p.split(id.path);
  if (parts.isEmpty) return '.';
  return p.joinAll(parts.take(parts.length - 1));
}
