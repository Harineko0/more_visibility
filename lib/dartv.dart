library dartv;

/// Annotation definitions for dartv visibility rules.
export 'src/annotations.dart';

/// Analyzer helpers for programmatic access (the CLI uses the same code).
export 'src/visibility_analyzer.dart'
    show DartvAnalyzer, VisibilityViolation, VisibilityScope;
