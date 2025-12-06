import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

/// Post-processes generated files to mirror visibility annotations from the
/// source part file onto generated declarations. This is useful for generators
/// (Riverpod/Freezed/etc.) that emit code into part files where the original
/// annotation is not preserved on generated declarations.
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
    final generated = await buildStep.readInputAsString();
    final sourceAnnotation = await _extractSourceAnnotation(
      buildStep,
      generated,
    );

    if (sourceAnnotation == null) {
      return;
    }

    final updated = annotateContent(
      generated,
      sourceAnnotation,
      defaultVisibility,
    );
    if (updated != generated) {
      await buildStep.writeAsString(buildStep.inputId, updated);
      log.info(
        'more_visibility: copied $sourceAnnotation into ${buildStep.inputId.path}',
      );
    }
  }

  Future<String?> _extractSourceAnnotation(
    PostProcessBuildStep buildStep,
    String generatedContent,
  ) async {
    final partMatch = RegExp(
      'part of [\'"]([^\'"]+)[\'"];',
    ).firstMatch(generatedContent);
    if (partMatch == null) return null;

    final partPath = partMatch.group(1);
    if (partPath == null) return null;

    final sourcePath = p.normalize(
      p.join(p.dirname(buildStep.inputId.path), partPath),
    );
    final file = File(sourcePath);
    if (!await file.exists()) {
      return null;
    }

    final sourceContent = await file.readAsString();
    return _firstDeclarationAnnotation(sourceContent);
  }

  /// Returns the first @mprotected/@mdefault annotation that decorates a
  /// top-level declaration (not a library/part directive).
  String? _firstDeclarationAnnotation(String sourceContent) {
    final lines = sourceContent.split('\n');
    String? pendingAnnotation;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('@mprotected')) {
        pendingAnnotation = '@mprotected';
        continue;
      }
      if (line.startsWith('@mdefault')) {
        pendingAnnotation = '@mdefault';
        continue;
      }
      if (pendingAnnotation == null) continue;
      if (line.isEmpty || line.startsWith('//')) {
        continue;
      }
      if (line.startsWith('library') || line.startsWith('part ')) {
        // Skip file-level annotations; no need to copy for part files.
        pendingAnnotation = null;
        continue;
      }
      return pendingAnnotation;
    }
    return pendingAnnotation;
  }

  /// Injects the annotation after the `part of` directive (or after leading
  /// comments) if the generated file does not already contain visibility
  /// annotations.
  String annotateContent(
    String generatedContent,
    String sourceAnnotation,
    String fallbackVisibility,
  ) {
    if (generatedContent.contains('@mprotected') ||
        generatedContent.contains('@mdefault')) {
      return generatedContent;
    }

    final annotation = sourceAnnotation.isNotEmpty
        ? sourceAnnotation
        : (fallbackVisibility == 'mdefault' ? '@mdefault' : '@mprotected');

    final lines = generatedContent.split('\n');
    final buffer = StringBuffer();
    var inserted = false;

    for (var i = 0; i < lines.length; i++) {
      buffer.writeln(lines[i]);
      if (!inserted && lines[i].trim().startsWith('part of')) {
        buffer.writeln(annotation);
        inserted = true;
      }
    }

    if (!inserted) {
      // Fallback: insert after leading comments/shebangs.
      final altBuffer = StringBuffer();
      var index = 0;
      while (index < lines.length &&
          (lines[index].startsWith('#!') ||
              lines[index].trim().startsWith('//') ||
              lines[index].trim().isEmpty)) {
        altBuffer.writeln(lines[index]);
        index++;
      }
      altBuffer.writeln(annotation);
      for (; index < lines.length; index++) {
        altBuffer.writeln(lines[index]);
      }
      return altBuffer.toString();
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
