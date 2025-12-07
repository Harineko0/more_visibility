import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/more_visibility_module_default_rule.dart';
import 'src/rules/more_visibility_protected_rule.dart';

/// Entrypoint for the analysis_server_plugin.
/// This top-level variable is required by the analysis server.
final plugin = MoreVisibilityPlugin();

class MoreVisibilityPlugin extends Plugin {
  @override
  String get name => 'more_visibility';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(MoreVisibilityProtectedRule())
      ..registerLintRule(MoreVisibilityModuleDefaultRule());
  }
}
