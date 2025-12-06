import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/more_visibility_rule.dart';

/// Entrypoint for the analysis_server_plugin.
/// This top-level variable is required by the analysis server.
final plugin = MoreVisibilityPlugin();

class MoreVisibilityPlugin extends Plugin {
  @override
  String get name => 'more_visibility';

  @override
  void register(PluginRegistry registry) {
    // Register the visibility rule as a warning (enabled by default)
    registry.registerWarningRule(MoreVisibilityRule());
  }
}
