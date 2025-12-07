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

class MoreVisibilityModuleDefaultRule extends AnalysisRule {
  MoreVisibilityModuleDefaultRule()
    : super(
        name: _code.name,
        description:
            'Enforces directory-scoped visibility via @mdefault annotations.',
      );

  late DiagnosticReporter _reporter;

  @override
  set reporter(DiagnosticReporter value) {
    super.reporter = value;
    _reporter = value;
  }

  static const _code = LintCode(
    'more_visibility_module_default',
    '`{0}` is @mdefault; only files in the same directory may access it. Declared at {1}.',
    correctionMessage:
        'Move the usage into the same directory or drop @mdefault.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

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

  final MoreVisibilityModuleDefaultRule rule;
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

    // Only check for @mdefault violations
    if (elementVisibility != VisibilityKind.moduleDefault) return;

    final declDir = p.normalize(p.dirname(declSource.fullName));
    final useDir = p.normalize(p.dirname(useSource.fullName));

    // @mdefault: only same directory
    final allowed = declDir == useDir;

    if (allowed) return;

    final name = rootElement.displayName.isEmpty
        ? 'this symbol'
        : rootElement.displayName;

    // Report using the specific diagnostic code
    rule.reportViolation(node, MoreVisibilityModuleDefaultRule._code, [
      name,
      declDir,
    ]);
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
