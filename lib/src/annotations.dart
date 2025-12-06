/// Marks a file or declaration as protected: visible within its directory and
/// any subdirectories.
class Protected {
  const Protected();
}

/// Marks a file or declaration as package-private: visible only within its
/// defining directory.
class PackagePrivate {
  const PackagePrivate();
}

/// Annotation to mark declarations protected to their directory subtree.
const protected = Protected();

/// Annotation to mark declarations private to their defining directory.
const packagePrivate = PackagePrivate();
