import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('directory private path logic', () {
    test('getPrivateDirectoryInfo extracts correct directories', () {
      final filePath =
          '/Users/hari/proj/example/lib/pages/_components/button.dart';
      final result = _getPrivateDirectoryInfo(filePath);

      expect(result, isNotNull);
      expect(result!.$1, contains('_components'));
      expect(result.$2, '/Users/hari/proj/example/lib/pages');
    });

    test('getPackageDir removes private directory components', () {
      expect(
        _getPackageDir('/Users/hari/proj/example/lib/pages/page.dart'),
        '/Users/hari/proj/example/lib/pages',
      );

      expect(
        _getPackageDir(
          '/Users/hari/proj/example/lib/pages/_hooks/use_foo.dart',
        ),
        '/Users/hari/proj/example/lib/pages',
      );

      expect(
        _getPackageDir('/Users/hari/proj/example/lib/bar.dart'),
        '/Users/hari/proj/example/lib',
      );

      expect(
        _getPackageDir('/Users/hari/proj/example/lib/pages/profile/page.dart'),
        '/Users/hari/proj/example/lib/pages/profile',
      );
    });

    test('isAtSameDepth correctly identifies allowed usages', () {
      const declFile =
          '/Users/hari/proj/example/lib/pages/_components/button.dart';
      const packageDir = '/Users/hari/proj/example/lib/pages';

      // Allowed: same package directory
      expect(
        _isAtSameDepth(
          '/Users/hari/proj/example/lib/pages/page.dart',
          packageDir,
        ),
        isTrue,
      );

      // Allowed: same package directory (inside another private dir)
      expect(
        _isAtSameDepth(
          '/Users/hari/proj/example/lib/pages/_hooks/use_foo.dart',
          packageDir,
        ),
        isTrue,
      );

      // Not allowed: different package directory (parent)
      expect(
        _isAtSameDepth('/Users/hari/proj/example/lib/bar.dart', packageDir),
        isFalse,
      );

      // Not allowed: different package directory (child)
      expect(
        _isAtSameDepth(
          '/Users/hari/proj/example/lib/pages/profile/page.dart',
          packageDir,
        ),
        isFalse,
      );
    });
  });
}

// Copy of the implementation from directory_private_rule.dart
(String, String)? _getPrivateDirectoryInfo(String filePath) {
  final normalizedPath = p.normalize(filePath);
  final parts = p.split(normalizedPath);

  for (var i = parts.length - 1; i >= 0; i--) {
    if (parts[i].startsWith('_')) {
      final privateDir = p.joinAll(parts.take(i + 1));
      final packageDir = i > 0 ? p.joinAll(parts.take(i)) : p.separator;
      return (privateDir, packageDir);
    }
  }
  return null;
}

String _getPackageDir(String filePath) {
  final normalizedPath = p.normalize(p.dirname(filePath));
  final parts = p.split(normalizedPath);

  final nonPrivateParts = <String>[];
  for (final part in parts) {
    if (part.startsWith('_')) {
      break;
    }
    nonPrivateParts.add(part);
  }

  return nonPrivateParts.isEmpty ? p.separator : p.joinAll(nonPrivateParts);
}

bool _isAtSameDepth(String useFilePath, String packageDir) {
  final usePackageDir = _getPackageDir(useFilePath);
  final normalizedUsePackageDir = p.normalize(usePackageDir);
  final normalizedPackageDir = p.normalize(packageDir);

  return normalizedUsePackageDir == normalizedPackageDir;
}
