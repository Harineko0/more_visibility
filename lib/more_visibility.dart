library more_visibility;

export 'package:more_visibility_annotation/more_visibility_annotation.dart';

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/plugin.dart';

/// Entrypoint for the custom_lint plugin.
PluginBase createPlugin() => MoreVisibilityPlugin();
