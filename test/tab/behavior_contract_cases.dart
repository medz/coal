import 'package:coal/tab.dart';

class ParseContractExpectations {
  const ParseContractExpectations({
    this.containsCompletions = const <String>[],
    this.notContainsCompletions = const <String>[],
    this.exactCompletions,
    this.completionCount,
    this.directive = ':${ShellCompDirective.noFileComp}',
  });

  final List<String> containsCompletions;
  final List<String> notContainsCompletions;
  final List<String>? exactCompletions;
  final int? completionCount;
  final String directive;
}

class ParseContractCase {
  const ParseContractCase({
    required this.key,
    required this.description,
    required this.input,
    required this.expectations,
  });

  final String key;
  final String description;
  final List<String> input;
  final ParseContractExpectations expectations;
}

Tab buildParseContractTab() {
  final tab = Tab();
  tab.option('mode', 'Execution mode', (complete, _) {
    complete('dev', 'Development mode');
    complete('prod', 'Production mode');
  }, alias: 'm');
  tab.option('verbose', 'Verbose logging', null, alias: 'v');
  tab.option('stage', 'Stage selector', (complete, _) {
    complete('alpha', 'Alpha stage');
    complete('alpha', 'Duplicate alpha stage');
    complete('beta', 'Beta stage');
  }, alias: 's');

  tab.command('project', 'Project operations');
  tab.command('project task', 'Task operations');
  tab.command('project task run', 'Run task');

  final deploy = tab.command('deploy', 'Deploy service');
  deploy.option('region', 'Deployment region', (complete, _) {
    complete('us', 'United States');
    complete('eu', 'Europe');
  }, alias: 'r');
  deploy.argument('environment', (complete, _) {
    complete('staging', 'Staging environment');
    complete('production', 'Production environment');
  });

  return tab;
}

final List<ParseContractCase> parseContractCases = <ParseContractCase>[
  ParseContractCase(
    key: 'long-flag-prefix',
    description: 'completes long flags by prefix',
    input: <String>['--mo'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['--mode\tExecution mode'],
    ),
  ),
  ParseContractCase(
    key: 'short-flag-prefix',
    description: 'completes short flag aliases by prefix',
    input: <String>['-v'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['-v\tVerbose logging'],
    ),
  ),
  ParseContractCase(
    key: 'option-value-after-flag',
    description: 'completes option values after non-bool option',
    input: <String>['--mode', 'd'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['dev\tDevelopment mode'],
    ),
  ),
  ParseContractCase(
    key: 'option-value-equals-flag',
    description: 'completes option values for equals-style flags',
    input: <String>['--mode=p'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['prod\tProduction mode'],
    ),
  ),
  ParseContractCase(
    key: 'boolean-option-does-not-consume-value',
    description: 'treats token after bool option as command completion input',
    input: <String>['--verbose', 'de'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['deploy\tDeploy service'],
    ),
  ),
  ParseContractCase(
    key: 'root-subcommand-completion',
    description: 'completes root command names',
    input: <String>['pro'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['project\tProject operations'],
    ),
  ),
  ParseContractCase(
    key: 'nested-subcommand-completion',
    description: 'completes nested subcommand names',
    input: <String>['project', 'ta'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['task\tTask operations'],
    ),
  ),
  ParseContractCase(
    key: 'deep-subcommand-completion',
    description: 'completes deep nested subcommand names',
    input: <String>['project', 'task', 'r'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['run\tRun task'],
    ),
  ),
  ParseContractCase(
    key: 'positional-completion',
    description: 'completes positional argument candidates',
    input: <String>['deploy', 'st'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['staging\tStaging environment'],
    ),
  ),
  ParseContractCase(
    key: 'subcommand-option-values',
    description: 'completes option values on matched subcommands',
    input: <String>['deploy', '--region', 'u'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['us\tUnited States'],
    ),
  ),
  ParseContractCase(
    key: 'no-result',
    description:
        'returns directive without completions when no candidate matches',
    input: <String>['--unknown'],
    expectations: ParseContractExpectations(completionCount: 0),
  ),
  ParseContractCase(
    key: 'deduplicate-values',
    description: 'deduplicates repeated completion values',
    input: <String>['--stage', 'a'],
    expectations: ParseContractExpectations(
      exactCompletions: <String>['alpha\tAlpha stage'],
    ),
  ),
];
