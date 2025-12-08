import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:path/path.dart' as p;

class DirectoryPrivateRule extends AnalysisRule {
  DirectoryPrivateRule()
    : super(
        name: _code.name,
        description:
            'Enforces directory-private visibility for underscore-prefixed directories.',
      );

  late DiagnosticReporter _reporter;

  @override
  set reporter(DiagnosticReporter value) {
    super.reporter = value;
    _reporter = value;
  }

  static const _code = LintCode(
    'directory_private',
    '`{0}` is in a private directory `{1}`; only files at the same depth may access it.',
    correctionMessage:
        'Move the usage to the same directory depth or move the declaration outside the private directory.',
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

  final DirectoryPrivateRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // No-op: we don't need to cache anything for directory-private checks
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

    // Check if the declared file is in a private directory (underscore-prefixed)
    final privateDirectoryInfo = _getPrivateDirectoryInfo(declSource.fullName);
    if (privateDirectoryInfo == null) return;

    final privateDir = privateDirectoryInfo.$1;
    final packageDir = privateDirectoryInfo.$2;

    // Check if the using file is at the same depth
    // The using file must have the same package directory (excluding private dirs)
    final allowed = _isAtSameDepth(useSource.fullName, packageDir);

    if (allowed) return;

    final name = rootElement.displayName.isEmpty
        ? 'this symbol'
        : rootElement.displayName;

    // Report using the specific diagnostic code
    rule.reportViolation(node, DirectoryPrivateRule._code, [name, privateDir]);
  }

  /// Returns (privateDir, packageDir) if the file is in a private directory.
  /// Returns null otherwise.
  (String, String)? _getPrivateDirectoryInfo(String filePath) {
    final normalizedPath = p.normalize(filePath);
    final parts = p.split(normalizedPath);

    // Find the first directory component that starts with underscore
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i].startsWith('_')) {
        // Found a private directory
        final privateDir = p.joinAll(parts.take(i + 1));
        final packageDir = i > 0 ? p.joinAll(parts.take(i)) : p.separator;
        return (privateDir, packageDir);
      }
    }
    return null;
  }

  /// Gets the package directory for a file path by removing any private directory components.
  /// For example:
  /// - lib/pages/page.dart -> lib/pages
  /// - lib/pages/_hooks/use_foo.dart -> lib/pages
  /// - lib/pages/profile/page.dart -> lib/pages/profile
  /// - lib/bar.dart -> lib
  String _getPackageDir(String filePath) {
    final normalizedPath = p.normalize(p.dirname(filePath));
    final parts = p.split(normalizedPath);

    // Remove any private directory components
    final nonPrivateParts = <String>[];
    for (final part in parts) {
      if (part.startsWith('_')) {
        // Stop at the first private directory
        break;
      }
      nonPrivateParts.add(part);
    }

    return nonPrivateParts.isEmpty ? p.separator : p.joinAll(nonPrivateParts);
  }

  /// Checks if the usage directory is at the same depth as the package directory.
  /// This means the usage file's package directory (excluding private dirs)
  /// must match the declared file's package directory.
  bool _isAtSameDepth(String useFilePath, String packageDir) {
    final usePackageDir = _getPackageDir(useFilePath);
    final normalizedUsePackageDir = p.normalize(usePackageDir);
    final normalizedPackageDir = p.normalize(packageDir);

    return normalizedUsePackageDir == normalizedPackageDir;
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
