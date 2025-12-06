import 'package:build/build.dart';

import 'src/builders/annotate_generated_builder.dart';

/// Post-process builder that injects a file-level `@mprotected` annotation into
/// generated Dart files to keep visibility expectations consistent.
PostProcessBuilder annotateGenerated(BuilderOptions options) {
  return AnnotateGeneratedBuilder(
    defaultVisibility: options.config['visibility'] as String? ?? 'mprotected',
  );
}
