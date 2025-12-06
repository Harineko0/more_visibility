import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

/// Visibility levels supported by dartv.
enum VisibilityScope { public, protected, packagePrivate }

/// A single violation produced by the analyzer.
class VisibilityViolation {
  VisibilityViolation({
    required this.referencedName,
    required this.referencePath,
    required this.definingPath,
    required this.scope,
    required this.line,
    required this.column,
  });

  final String referencedName;
  final String referencePath;
  final String definingPath;
  final VisibilityScope scope;
  final int line;
  final int column;

  String describe({String? Function(String path)? pathFormatter}) {
    final format = pathFormatter ?? (p) => p;
    final scopeLabel = scope == VisibilityScope.protected
        ? 'protected (directory + subdirectories)'
        : 'package-private (directory only)';
    final location =
        '${format(referencePath)}:$line:$column uses $referencedName from ${format(definingPath)}';
    return '$location which is $scopeLabel';
  }
}

class _VisibilityRule {
  _VisibilityRule({
    required this.visibility,
    required this.definedIn,
    required this.name,
  });

  final VisibilityScope visibility;
  final String definedIn;
  final String name;
}

/// Analyzer that checks for visibility violations using dartv annotations.
class DartvAnalyzer {
  DartvAnalyzer({PhysicalResourceProvider? resourceProvider})
    : _resourceProvider = resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  final PhysicalResourceProvider _resourceProvider;

  Future<List<VisibilityViolation>> analyzePaths(List<String> targets) async {
    if (targets.isEmpty) {
      throw ArgumentError('Provide at least one path to analyze.');
    }

    final normalizedTargets = targets
        .map((t) => p.normalize(p.absolute(t)))
        .toList();
    final dartFiles = _collectDartFiles(normalizedTargets);
    if (dartFiles.isEmpty) {
      return [];
    }

    final collection = AnalysisContextCollection(
      includedPaths: normalizedTargets,
      resourceProvider: _resourceProvider,
    );

    final rules = <Element, _VisibilityRule>{};
    final results = <ResolvedUnitResult>[];

    for (final file in dartFiles) {
      final context = collection.contextFor(file);
      final result = await context.currentSession.getResolvedUnit(file);
      if (result is! ResolvedUnitResult) {
        continue;
      }

      results.add(result);
      _collectRules(result, rules);
    }

    final violations = <VisibilityViolation>[];
    for (final result in results) {
      final visitor = _UsageVisitor(
        result: result,
        rules: rules,
        onViolation: violations.add,
      );
      result.unit.accept(visitor);
    }

    return violations;
  }

  void _collectRules(
    ResolvedUnitResult result,
    Map<Element, _VisibilityRule> rules,
  ) {
    final fileDefault = _fileLevelVisibility(result.unit);

    for (final declaration in result.unit.declarations) {
      final visibility = _visibilityForDeclaration(
        declaration,
        fallback: fileDefault,
      );
      if (visibility == VisibilityScope.public) continue;

      _registerElement(
        declaration.declaredElement,
        visibility,
        result.path,
        rules,
      );

      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          _registerElement(
            variable.declaredElement,
            visibility,
            result.path,
            rules,
          );
        }
      }
    }
  }

  void _registerElement(
    Element? element,
    VisibilityScope visibility,
    String filePath,
    Map<Element, _VisibilityRule> rules,
  ) {
    if (element == null) return;

    final name = element.displayName;
    if (name.isEmpty) return;

    final rule = _VisibilityRule(
      visibility: visibility,
      definedIn: filePath,
      name: name,
    );

    rules[element] = rule;

    if (element is PropertyInducingElement) {
      if (element.getter case final getter?) {
        rules[getter] = rule;
      }
      if (element.setter case final setter?) {
        rules[setter] = rule;
      }
    }

    if (element is ClassElement) {
      for (final constructor in element.constructors) {
        rules[constructor] = rule;
      }
    }

    if (element is EnumElement) {
      for (final constructor in element.constructors) {
        rules[constructor] = rule;
      }
    }

    if (element is ExtensionTypeElement) {
      for (final constructor in element.constructors) {
        rules[constructor] = rule;
      }
    }
  }

  VisibilityScope _fileLevelVisibility(CompilationUnit unit) {
    for (final directive in unit.directives) {
      final scope = _visibilityFromMetadata(directive.metadata);
      if (scope != null) {
        return scope;
      }
    }
    return VisibilityScope.public;
  }

  VisibilityScope _visibilityForDeclaration(
    Declaration declaration, {
    required VisibilityScope fallback,
  }) {
    return _visibilityFromMetadata(declaration.metadata) ?? fallback;
  }

  VisibilityScope? _visibilityFromMetadata(NodeList<Annotation> metadata) {
    for (final annotation in metadata) {
      final name = _annotationName(annotation);
      switch (name) {
        case 'protected':
        case 'Protected':
          return VisibilityScope.protected;
        case 'packagePrivate':
        case 'PackagePrivate':
          return VisibilityScope.packagePrivate;
      }
    }
    return null;
  }

  String? _annotationName(Annotation annotation) {
    final identifier = annotation.name;
    if (identifier is PrefixedIdentifier) {
      return identifier.identifier.name;
    }
    return identifier.name;
  }

  List<String> _collectDartFiles(List<String> targets) {
    final files = <String>{};
    final ignoredDirectories = {'.dart_tool', '.git', 'build', '.pub-cache'};

    for (final target in targets) {
      final type = FileSystemEntity.typeSync(target, followLinks: true);
      if (type == FileSystemEntityType.directory) {
        final dir = Directory(target);
        final segments = <Directory>[dir];
        while (segments.isNotEmpty) {
          final current = segments.removeLast();
          for (final entity in current.listSync(followLinks: false)) {
            final name = p.basename(entity.path);
            if (entity is Directory) {
              if (ignoredDirectories.contains(name)) continue;
              segments.add(entity);
              continue;
            }
            if (entity is File && entity.path.endsWith('.dart')) {
              files.add(p.normalize(entity.absolute.path));
            }
          }
        }
      } else if (type == FileSystemEntityType.file &&
          target.toLowerCase().endsWith('.dart')) {
        files.add(p.normalize(p.absolute(target)));
      }
    }

    return files.toList()..sort();
  }
}

class _UsageVisitor extends RecursiveAstVisitor<void> {
  _UsageVisitor({
    required this.result,
    required this.rules,
    required this.onViolation,
  });

  final ResolvedUnitResult result;
  final Map<Element, _VisibilityRule> rules;
  final void Function(VisibilityViolation violation) onViolation;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (node.inDeclarationContext()) return;

    final element = node.staticElement;
    if (element == null) return;

    final rule = rules[element];
    if (rule == null) return;

    if (_isAllowed(rule.visibility, rule.definedIn, result.path)) return;

    final location = result.unit.lineInfo.getLocation(node.offset);
    onViolation(
      VisibilityViolation(
        referencedName: rule.name,
        referencePath: result.path,
        definingPath: rule.definedIn,
        scope: rule.visibility,
        line: location.lineNumber,
        column: location.columnNumber,
      ),
    );
  }

  bool _isAllowed(
    VisibilityScope scope,
    String definingPath,
    String referencePath,
  ) {
    if (definingPath == referencePath) return true;

    final definingDir = p.normalize(p.dirname(definingPath));
    final referenceDir = p.normalize(p.dirname(referencePath));

    switch (scope) {
      case VisibilityScope.public:
        return true;
      case VisibilityScope.protected:
        return definingDir == referenceDir ||
            p.isWithin(definingDir, referenceDir);
      case VisibilityScope.packagePrivate:
        return definingDir == referenceDir;
    }
  }
}
