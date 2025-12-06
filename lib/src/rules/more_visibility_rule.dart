import 'dart:collection';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:path/path.dart' as p;

import '../utils/annotation_utils.dart';

class MoreVisibilityRule extends AnalysisRule {
  MoreVisibilityRule()
    : super(
        name: 'more_visibility',
        description:
            'Enforces directory-scoped visibility via @mprotected and @mdefault annotations.',
      );

  late DiagnosticReporter _reporter;

  @override
  set reporter(DiagnosticReporter value) {
    super.reporter = value;
    _reporter = value;
  }

  static const _baseCode = LintCode(
    'more_visibility',
    'This declaration is not visible from the current file or directory.',
    correctionMessage:
        'Limit usage to files in the same directory (for @mdefault) or the same directory and subdirectories (for @mprotected).',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _protectedCode = LintCode(
    'more_visibility_protected',
    '`{0}` is @mprotected; only files in the same directory or subdirectories may access it. Declared at {1}.',
    correctionMessage:
        'Move the usage under the declaring directory or remove @mprotected.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _defaultCode = LintCode(
    'more_visibility_module_default',
    '`{0}` is @mdefault; only files in the same directory may access it. Declared at {1}.',
    correctionMessage:
        'Move the usage into the same directory or drop @mdefault.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => _baseCode;

  // Cache is now per-file instead of shared across all files
  // This is managed by the visitor instance

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }

  /// Helper method to report violations with specific diagnostic codes.
  void reportViolation(
    AstNode node,
    DiagnosticCode code,
    List<Object> arguments,
  ) {
    if (!node.isSynthetic) {
      _reporter.atNode(node, code, arguments: arguments);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final MoreVisibilityRule rule;
  final RuleContext context;
  final _cache = _FileAnnotationCache();

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _cache.capture(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _checkIdentifier(node);
  }

  void _checkIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) return;
    final element = node.element;
    if (element == null) return;

    final rootElement = _topLevelElement(element);
    if (rootElement == null) return;

    final declSource = rootElement.firstFragment.libraryFragment?.source;
    if (declSource == null || declSource.fullName.isEmpty) return;

    final useUnit = node.root is CompilationUnit
        ? node.root as CompilationUnit
        : null;
    final useSource = useUnit?.declaredFragment?.source;
    if (useSource == null) return;

    if (useSource.fullName == declSource.fullName) return;

    final elementVisibility =
        visibilityFromAnnotations(rootElement.metadata.annotations) ??
        _cache.visibilityForPath(declSource.fullName) ??
        visibilityFromAnnotations(
          rootElement.library?.metadata.annotations ?? const [],
        );

    if (elementVisibility == null) return;

    final declDir = p.normalize(p.dirname(declSource.fullName));
    final useDir = p.normalize(p.dirname(useSource.fullName));

    final allowed = switch (elementVisibility) {
      VisibilityKind.protected =>
        declDir == useDir || p.isWithin(declDir, useDir),
      VisibilityKind.moduleDefault => declDir == useDir,
    };

    if (allowed) return;

    final name = rootElement.displayName.isEmpty
        ? 'this symbol'
        : rootElement.displayName;
    final code = elementVisibility == VisibilityKind.moduleDefault
        ? MoreVisibilityRule._defaultCode
        : MoreVisibilityRule._protectedCode;

    // Report using the specific diagnostic code (not the base code)
    rule.reportViolation(node, code, [name, declDir]);
  }

  Element? _topLevelElement(Element element) {
    Element current = element;
    if (current is PropertyAccessorElement) {
      current = current.variable;
    }
    while (current.enclosingElement != null &&
        current.enclosingElement is! LibraryElement) {
      current = current.enclosingElement!;
    }
    return current.enclosingElement is LibraryElement ? current : null;
  }
}

class _FileAnnotationCache {
  final _byPath = HashMap<String, VisibilityKind?>();

  void capture(CompilationUnit unit) {
    final path = unit.declaredFragment?.source.fullName;
    if (path == null) return;
    _byPath[path] = _annotationFromUnit(unit);
  }

  VisibilityKind? visibilityForPath(String path) => _byPath[path];

  VisibilityKind? _annotationFromUnit(CompilationUnit unit) {
    for (final directive in unit.directives) {
      if (directive is LibraryDirective) {
        final libVisibility = visibilityFromNodeMetadata(directive.metadata);
        if (libVisibility != null) return libVisibility;
      }
    }

    for (final directive in unit.directives) {
      final visibility = visibilityFromNodeMetadata(directive.metadata);
      if (visibility != null) {
        final tokenBefore = directive.beginToken;
        if (_isAtFileStart(tokenBefore)) {
          return visibility;
        }
      }
    }
    return null;
  }

  bool _isAtFileStart(Token token) {
    return token.offset == 0;
  }
}
