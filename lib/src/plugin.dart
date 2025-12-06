import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'rules/more_visibility_rule.dart';

class MoreVisibilityPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs _) => [MoreVisibilityRule()];
}
