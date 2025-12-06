# Annotations

## @mprotected
- Allowed: same directory as the declaration.
- Allowed: any subdirectory.
- Forbidden: parent/sibling directories.

## @mdefault
- Allowed: only the declaring directory.
- Forbidden: any other directory.

Notes
- Designed to pair with the `more_visibility` custom lint.
- File-level annotations on a library apply to all top-level declarations in that file.
