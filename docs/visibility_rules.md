# Visibility rules

This package enforces three types of visibility rules:

## directory_private (automatic)

Files in underscore-prefixed directories are only accessible from files at the same package depth.

- **No annotations required** — the rule automatically applies to any directory starting with `_`.
- **Application code only** — this rule only enforces restrictions on your project's code (`lib/`, `test/`, etc.). Dependencies (files in `.pub-cache` or `.dart-tool`) are excluded from enforcement.
- **Scope**: determined by the "package directory" (path before any `_*` component).
- **Allowed**: files whose package directory matches the declaring file's package directory.
- **Forbidden**: files at different package depths (parent or child directories).

### Examples

Given `lib/pages/_components/button.dart`:
- ✅ Allowed: `lib/pages/page.dart` (same depth: `lib/pages`)
- ✅ Allowed: `lib/pages/_hooks/use_foo.dart` (same depth: `lib/pages`)
- ❌ Forbidden: `lib/bar.dart` (different depth: `lib`)
- ❌ Forbidden: `lib/pages/profile/page.dart` (different depth: `lib/pages/profile`)

### Severity
- Default: **error**
- Configure in `analysis_options.yaml`: `directory_private: warning|info|ignore`

---

## @mprotected (annotation-based)

- The rule applies to **top-level** declarations (classes, functions, typedefs, variables) and to library-level annotations.
- Scope is calculated from the declaring file's directory.
- **Allowed**: same directory as the declaration.
- **Allowed**: any subdirectory under the declaring directory.
- **Forbidden**: parent directories or sibling directories.

## @mdefault (annotation-based)

- **Allowed**: only the declaring directory.
- **Forbidden**: any other directory (including subdirectories).

## File-level defaults
- An annotation placed on the library directive (or the first directive in the file) becomes the default for every top-level declaration inside that file.
- A declaration-level annotation overrides the file-level default.

## What is not enforced
- Members inside a class/enum/extension are not individually checked; the rule is evaluated at the top-level declaration that encloses the member.
- Private identifiers (`_foo`) continue to follow Dart's library-privacy rules; this lint does not alter them.
- The `directory_private` rule only checks imports of files in `_*` directories; it does not apply to annotation-based visibility.
- The `directory_private` rule does not check dependency code (files in `.pub-cache` or `.dart-tool`); it only enforces restrictions on application code.
