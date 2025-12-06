/// Annotations used by the more_visibility custom lint package.
///
/// Apply [mprotected] or [mdefault] to a library (file-level) or to individual
/// top-level declarations to restrict their visibility to neighboring files.
library more_visibility.annotations;

/// Marks a declaration or a library as "module protected".
///
/// - `@mprotected` on a declaration: it can be referenced from files in the
///   same directory or any subdirectory.
/// - `@mprotected` on a library/file: applies to all top-level declarations in
///   that file unless they opt-out via [mdefault].
class MProtected {
  const MProtected();
}

/// Module protected marker.
const mprotected = MProtected();

/// Marks a declaration or library as "module default".
///
/// - `@mdefault` on a declaration: it can be referenced only from files in the
///   same directory.
/// - `@mdefault` on a library/file: applies to all top-level declarations in
///   that file.
class MDefault {
  const MDefault();
}

/// Module default marker.
const mdefault = MDefault();
