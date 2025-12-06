<div align="center">
<img src="https://img.shields.io/pub/v/more_visibility_annotation?label=pub&logo=dart&logoColor=white" alt="Pub">
<img src="https://github.com/Harineko0/more_visibility_annotation/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI">
<img src="https://img.shields.io/badge/dart-%E2%89%A53.0-blue" alt="Dart SDK">
<img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</div>

more_visibility_annotation
==========================

Standalone annotations used by the `more_visibility` lint package.

What’s inside
-------------
- `@mprotected`: declaration/file usable from the same directory and any subdirectories.
- `@mdefault`: declaration/file usable only from the same directory.

Usage
-----
1. Add dependency:
   ```yaml
   dependencies:
     more_visibility_annotation: ^0.1.0
   ```
2. Import and annotate:
   ```dart
   import 'package:more_visibility_annotation/more_visibility_annotation.dart';

   @mprotected
   class Shared {}

   @mdefault
   final local = 0;
   ```
3. Enable the analyzer plugin in your main project (dev dependency on `more_visibility`):
   ```yaml
   include: package:more_visibility/more_visibility.yaml
   ```

Links
-----
- Lints + builder: https://pub.dev/packages/more_visibility
