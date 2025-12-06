# Visibility rules

- The rule applies to **top-level** declarations (classes, functions, typedefs, variables) and to library-level annotations.
- Scope is calculated from the declaring file’s directory.

## @mprotected
- Allowed: same directory as the declaration.
- Allowed: any subdirectory under the declaring directory.
- Forbidden: parent directories or sibling directories.

## @mdefault
- Allowed: only the declaring directory.
- Forbidden: any other directory (including subdirectories).

## File-level defaults
- An annotation placed on the library directive (or the first directive in the file) becomes the default for every top-level declaration inside that file.
- A declaration-level annotation overrides the file-level default.

## What is not enforced
- Members inside a class/enum/extension are not individually checked; the rule is evaluated at the top-level declaration that encloses the member.
- Private identifiers (`_foo`) continue to follow Dart’s library-privacy rules; this lint does not alter them.
