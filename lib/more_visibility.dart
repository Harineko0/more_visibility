library;

export 'annotations.dart';

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/plugin.dart';

/// Entrypoint for the custom_lint plugin.
PluginBase createPlugin() => MoreVisibilityPlugin();
