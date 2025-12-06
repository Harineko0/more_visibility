import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../utils/annotation_utils.dart';

class MoreVisibilityRule extends DartLintRule {
  MoreVisibilityRule() : super(code: _baseCode);

  static const _baseCode = LintCode(
    name: 'more_visibility',
    problemMessage:
        'This declaration is not visible from the current file or directory.',
    correctionMessage:
        'Limit usage to files in the same directory (for @mdefault) or the same directory and subdirectories (for @mprotected).',
    url: 'https://pub.dev/packages/more_visibility',
  );

  static const _protectedCode = LintCode(
    name: 'more_visibility_protected',
    problemMessage:
        '`{0}` is @mprotected; only files in the same directory or subdirectories may access it. Declared at {1}.',
    correctionMessage:
        'Move the usage under the declaring directory or remove @mprotected.',
    url: 'https://pub.dev/packages/more_visibility',
  );

  static const _defaultCode = LintCode(
    name: 'more_visibility_module_default',
    problemMessage:
        '`{0}` is @mdefault; only files in the same directory may access it. Declared at {1}.',
    correctionMessage:
        'Move the usage into the same directory or drop @mdefault.',
    url: 'https://pub.dev/packages/more_visibility',
  );

  static final _cacheKey = Object();

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final cache =
        context.sharedState.putIfAbsent(_cacheKey, () => _FileAnnotationCache())
            as _FileAnnotationCache;

    context.registry.addCompilationUnit((node) {
      cache.capture(node);
    });

    context.registry.addSimpleIdentifier((node) {
      _checkIdentifier(node, reporter, cache);
    });
  }

  void _checkIdentifier(
    SimpleIdentifier node,
    ErrorReporter reporter,
    _FileAnnotationCache cache,
  ) {
    if (node.inDeclarationContext()) return;
    final element = node.staticElement;
    if (element == null) return;

    final rootElement = _topLevelElement(element);
    if (rootElement == null) return;

    final declSource = rootElement.source;
    if (declSource == null || declSource.fullName.isEmpty) return;

    final useUnit = node.root is CompilationUnit
        ? node.root as CompilationUnit
        : null;
    final useSource = useUnit?.declaredElement?.source;
    if (useSource == null) return;

    if (useSource.fullName == declSource.fullName) return;

    final elementVisibility =
        visibilityFromAnnotations(rootElement.metadata) ??
        cache.visibilityForPath(declSource.fullName) ??
        visibilityFromAnnotations(rootElement.library?.metadata ?? const []);

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
        ? _defaultCode
        : _protectedCode;

    reporter.reportErrorForNode(code, node, [name, declDir]);
  }

  Element? _topLevelElement(Element element) {
    Element current = element;
    if (current is PropertyAccessorElement) {
      current = current.variable;
    }
    while (current.enclosingElement != null &&
        current.enclosingElement is! CompilationUnitElement) {
      current = current.enclosingElement!;
    }
    return current.enclosingElement is CompilationUnitElement ? current : null;
  }
}

class _FileAnnotationCache {
  final _byPath = HashMap<String, VisibilityKind?>();

  void capture(CompilationUnit unit) {
    final path = unit.declaredElement?.source.fullName;
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
