import 'package:coal/tab.dart';

Tab buildDartCompletion() {
  final tab = Tab();

  tab
    ..option('help', 'Print usage information', null, alias: 'h')
    ..option('verbose', 'Show additional command output', null, alias: 'v')
    ..option('version', 'Print the Dart SDK version', null)
    ..option('enable-analytics', 'Enable analytics', null)
    ..option('disable-analytics', 'Disable analytics', null)
    ..option('suppress-analytics', 'Disable analytics for this run', null);

  for (final command in _commands) {
    final def = tab.command(command.name, command.description);
    for (final option in command.options) {
      def.option(option.name, option.description, null);
    }

    for (final value in command.values) {
      tab.command('${command.name} $value', value);
    }
  }

  return tab;
}

class _DartCommandSpec {
  const _DartCommandSpec(
    this.name,
    this.description, {
    this.options = const <_DartOptionSpec>[],
    this.values = const <String>[],
  });

  final String name;
  final String description;
  final List<_DartOptionSpec> options;
  final List<String> values;
}

class _DartOptionSpec {
  const _DartOptionSpec(this.name, this.description);

  final String name;
  final String description;
}

const _commands = <_DartCommandSpec>[
  _DartCommandSpec('install', 'Install or upgrade a global Dart CLI tool'),
  _DartCommandSpec('installed', 'List globally installed Dart CLI tools'),
  _DartCommandSpec('uninstall', 'Remove a globally installed Dart CLI tool'),
  _DartCommandSpec('build', 'Build a Dart application'),
  _DartCommandSpec(
    'compile',
    'Compile Dart to self-contained outputs',
    values: <String>['exe', 'aot-snapshot', 'jit-snapshot', 'js', 'kernel'],
  ),
  _DartCommandSpec('create', 'Create a new Dart project'),
  _DartCommandSpec(
    'pub',
    'Work with packages',
    values: <String>[
      'add',
      'cache',
      'deps',
      'downgrade',
      'get',
      'global',
      'login',
      'logout',
      'outdated',
      'publish',
      'remove',
      'token',
      'unpack',
      'upgrade',
    ],
  ),
  _DartCommandSpec(
    'run',
    'Run a Dart program',
    options: <_DartOptionSpec>[
      _DartOptionSpec('observe', 'Enable observatory'),
      _DartOptionSpec('enable-asserts', 'Enable assert statements'),
    ],
  ),
  _DartCommandSpec('test', 'Run tests for a project'),
  _DartCommandSpec('analyze', 'Analyze Dart code'),
  _DartCommandSpec('doc', 'Generate API documentation'),
  _DartCommandSpec('fix', 'Apply automated fixes'),
  _DartCommandSpec('format', 'Format Dart source code'),
  _DartCommandSpec('devtools', 'Open Dart DevTools'),
  _DartCommandSpec('info', 'Show Dart diagnostic information'),
];
