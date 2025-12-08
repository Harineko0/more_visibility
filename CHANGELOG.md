## 0.1.8

- Add `directory_private` rule: directories with underscore prefix (e.g., `_components`, `_hooks`) are only accessible from files at the same package depth.
  - Files in `lib/pages/_components/` can only be imported by files in `lib/pages/` or other `lib/pages/_*/` directories.
  - Files in parent directories (e.g., `lib/`) or child directories (e.g., `lib/pages/profile/`) cannot access private directories.
  - Default severity is `error`.

## 0.1.0

- Introduce `@mprotected` and `@mdefault` annotations.
- Add custom lint to enforce directory-scoped visibility.
- Add post-process builder to auto-annotate generated files.
- Provide example project and end-to-end tests.
