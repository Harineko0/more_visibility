<div align="center">

# more_visibility

**Fine-grained visibility control for Dart & Flutter projects**

[![Pub Version](https://img.shields.io/pub/v/more_visibility?label=pub&logo=dart&logoColor=white)](https://pub.dev/packages/more_visibility)
[![CI](https://github.com/Harineko0/more_visibility/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Harineko0/more_visibility/actions)
[![Dart SDK](https://img.shields.io/badge/dart-%E2%89%A53.10-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)

</div>

---

## Why more_visibility?

Dart's built-in visibility is limited to **library-private** (`_identifier`) and **public** (everything else). This works for small projects, but as codebases grow, you often need finer control:

- 🚫 Prevent accidental imports of internal utilities from parent directories
- 🔒 Keep implementation details scoped to feature modules
- 📁 Enforce architectural boundaries within your codebase

**more_visibility** brings Java-style visibility modifiers and automatic directory-private enforcement to Dart, making your codebase more maintainable and preventing architectural drift.

---

## ✨ Features

- 🎯 **Directory-private enforcement** — Underscore-prefixed directories (`_components`, `_hooks`) are automatically restricted to same-level imports. **Zero configuration.**
- 🛡️ **Java-style annotations** — `@mprotected` and `@mdefault` for fine-grained control over symbol visibility
- ⚡ **Real-time feedback** — Analysis server plugin catches violations in your IDE as you type
- 🔧 **Works with code generation** — Auto-annotates generated files from Freezed, Riverpod, JsonSerializable, etc.
- 🎨 **Configurable severity** — Set rules as errors, warnings, or info based on your needs

---

## 🚀 Quick Start

### 1. Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  more_visibility_annotation: ^0.1.0

dev_dependencies:
  more_visibility: ^0.1.10
```

### 2. Enable the plugin

In your `analysis_options.yaml`:

```yaml
include: package:more_visibility/more_visibility.yaml
```

That's it! The plugin is now active and will enforce visibility rules.

---

## 📖 Usage

### Directory-private (Automatic)

Simply prefix directories with `_` to make them private to their parent directory:

```
lib/
├── pages/
│   ├── page.dart              ✅ Can import _components/
│   ├── _components/
│   │   └── button.dart        🔒 Private to lib/pages/
│   └── profile/
│       └── profile_page.dart  ❌ Cannot import _components/
```

**Example:**

```dart
// ✅ lib/pages/page.dart
import '_components/button.dart'; // Same depth - OK

// ❌ lib/pages/profile/profile_page.dart
import '../_components/button.dart'; // Different depth - ERROR
```

> **Note:** Only applies to your application code. Dependencies are excluded to avoid false positives.

---

### Annotation-based visibility

Control individual declarations with annotations:

```dart
import 'package:more_visibility_annotation/more_visibility_annotation.dart';

// 🛡️ Protected: accessible from this directory and subdirectories
@mprotected
final sharedConfig = Config();

// 🔒 Module-default: accessible only within this directory
@mdefault
final localHelper = Helper();
```

**File-level annotations:**

```dart
@mprotected
library feature_auth;

// All declarations inherit @mprotected
class AuthService { }
final authToken = '';
```

---

## 🎨 Visual Examples

### Before more_visibility

```dart
// lib/utils/internal_helper.dart
String formatSecret(String secret) => '***$secret***';

// lib/features/auth/login.dart
import '../../utils/internal_helper.dart'; // ⚠️ Unintended coupling

// lib/main.dart
import 'utils/internal_helper.dart'; // ⚠️ Internal API exposed
```

**Problems:**
- No enforcement of architectural boundaries
- Internal utilities leak across module boundaries
- Difficult to refactor without breaking unknown dependents

### After more_visibility

```dart
// lib/utils/_internal/helper.dart (in private directory)
String formatSecret(String secret) => '***$secret***';

// lib/features/auth/login.dart
import '../../utils/_internal/helper.dart'; // ❌ Compile-time error!
// Error: `formatSecret` is in a private directory `/lib/utils/_internal`

// lib/utils/public_api.dart
import '_internal/helper.dart'; // ✅ Same depth - OK
export '_internal/helper.dart' show allowedFunction;
```

**Benefits:**
- ✅ Architectural boundaries enforced at compile-time
- ✅ Clear separation between public API and internal implementation
- ✅ Refactoring is safer with explicit visibility scopes

---

## 📚 Documentation

| Topic | Description |
|-------|-------------|
| [Visibility Rules](docs/visibility_rules.md) | Detailed explanation of all visibility rules |
| [Usage Guide](docs/usage.md) | Step-by-step usage instructions and patterns |
| [Auto-annotation](docs/auto_annotation.md) | Configuring builders for generated code |

---

## ⚙️ Configuration

### Adjusting severity

```yaml
analyzer:
  errors:
    directory_private: warning                  # Default: error
    more_visibility_protected: info             # Default: error
    more_visibility_module_default: ignore      # Disable completely
```

### Disabling rules

```yaml
plugins:
  more_visibility:
    diagnostics:
      directory_private: false              # Disable directory-private rule
      more_visibility_protected: false      # Disable @mprotected checks
```

### Ignoring specific violations

```dart
// ignore_for_file: directory_private

// ignore: more_visibility_protected
import '../protected_api.dart';
```

---

## 🔧 Auto-annotation for Generated Code

Works seamlessly with Freezed, Riverpod, JsonSerializable, and other code generators.

**build.yaml:**

```yaml
post_process_builders:
  more_visibility:auto_annotate:
    options:
      visibility: mprotected  # Default annotation for generated files
```

Generated files automatically inherit visibility from their source files:

```dart
// user.dart
@mprotected
@freezed
class User with _$User {
  // ...
}

// user.freezed.dart (generated)
@mprotected  // ← Automatically added
part of 'user.dart';
// ...
```

---

## 📦 Requirements

- **Dart SDK:** 3.10.0 or later
- **Flutter SDK:** 3.38.0 or later (if using Flutter)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Star History

If you find this package useful, please consider giving it a star on [GitHub](https://github.com/Harineko0/more_visibility)!

---

<div align="center">

**Made with ❤️ for the Dart & Flutter community**

[Documentation](docs/) • [Issues](https://github.com/Harineko0/more_visibility/issues) • [Pub.dev](https://pub.dev/packages/more_visibility)

</div>
