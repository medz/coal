import 'command.dart';
import 'flags.dart';
import 'scripts/bash.dart';
import 'scripts/fish.dart';
import 'scripts/powershell.dart';
import 'scripts/zsh.dart';
import 'shell.dart';
import 'tab.dart';

// Static Dart SDK command metadata used by the `coal tab dart` executable.
// Keep this file internal: the Dart SDK command set can drift between SDK
// releases, while Coal's public TAB API should stay generic.

/// Builds completion definitions for the Dart SDK command-line tool.
Tab dartCliTab() {
  final tab = Tab(emptyCompletionDirective: ShellCompDirective.none);

  _addRootOptions(tab);
  _addCommands(tab, _dartCommands);
  _addCommands(tab, _dartHelpCommands, prefix: 'help');
  _addCommands(tab, _compileCommands, prefix: 'help compile');
  _addCommands(tab, _buildCommands, prefix: 'help build');
  _addCommands(tab, _infoCommands, prefix: 'help info');
  _addCommands(tab, _pubCommands, prefix: 'help pub');
  _addCommands(tab, _pubCacheCommands, prefix: 'help pub cache');
  _addCommands(tab, _pubGlobalCommands, prefix: 'help pub global');
  _addCommands(tab, _pubTokenCommands, prefix: 'help pub token');
  _addCommands(tab, _pubWorkspaceCommands, prefix: 'help pub workspace');
  _addCommands(tab, _compileCommands, prefix: 'compile');
  _addCommands(tab, _buildCommands, prefix: 'build');
  _addCommands(tab, _infoCommands, prefix: 'info');
  _addCommands(tab, _pubCommands, prefix: 'pub');
  _addCommands(tab, _pubCacheCommands, prefix: 'pub cache');
  _addCommands(tab, _pubGlobalCommands, prefix: 'pub global');
  _addCommands(tab, _pubTokenCommands, prefix: 'pub token');
  _addCommands(tab, _pubWorkspaceCommands, prefix: 'pub workspace');

  _flag(
    _command(tab, 'compile', 'Compile Dart to various formats'),
    'help',
    'Print this usage information',
    alias: 'h',
  );
  final create = _command(tab, 'create', 'Create a new Dart project');
  _flag(create, 'help', 'Print this usage information', alias: 'h');
  _values(
    create,
    'template',
    'The project template to use',
    _createTemplates,
    alias: 't',
  );
  _flag(create, 'pub', "Run 'pub get' after project creation");
  _flag(create, 'no-pub', "Do not run 'pub get' after project creation");
  _flag(create, 'force', 'Force project generation');

  final pub = _command(tab, 'pub', 'Work with packages');
  _flag(pub, 'help', 'Print this usage information', alias: 'h');
  _flag(pub, 'verbose', 'Print detailed logging', alias: 'v');
  _flag(pub, 'color', 'Use colors in terminal output');
  _flag(pub, 'no-color', 'Do not use colors in terminal output');
  _value(pub, 'directory', 'Run the subcommand in a directory', alias: 'C');

  _flag(
    _command(tab, 'analyze', 'Analyze Dart code in a directory'),
    'help',
    'Print this usage information',
    alias: 'h',
  );
  final doc = _command(
    tab,
    'doc',
    'Generate API documentation for Dart projects',
  );
  _flag(doc, 'help', 'Print this usage information', alias: 'h');
  _value(doc, 'output', 'Configure the output directory', alias: 'o');
  _flag(doc, 'validate-links', 'Display warnings for broken links');
  _flag(doc, 'dry-run', 'Try to generate docs without saving them');

  final fix = _command(tab, 'fix', 'Apply automated fixes to Dart source code');
  _flag(fix, 'help', 'Print this usage information', alias: 'h');
  _flag(fix, 'dry-run', 'Preview fixes without changing files', alias: 'n');
  _flag(fix, 'apply', 'Apply proposed fixes');
  _value(fix, 'code', 'Apply fixes for diagnostic codes');

  final format = _command(
    tab,
    'format',
    'Idiomatically format Dart source code',
  );
  _flag(format, 'help', 'Print this usage information', alias: 'h');
  _flag(format, 'verbose', 'Show all options and flags', alias: 'v');
  _values(
    format,
    'output',
    'Set where to write formatted output',
    _formatOutputs,
    alias: 'o',
  );
  _flag(
    format,
    'set-exit-if-changed',
    'Return exit code 1 if files need formatting',
  );

  return tab;
}

/// Generates a shell completion setup script for the `dart` command.
String dartCliCompletionScript(Shell shell, {String exec = 'coal tab dart'}) {
  return switch (shell) {
    Shell.bash => bashScript('dart', exec, enableDefaultCompletion: true),
    Shell.fish => fishScript('dart', exec, enableDefaultCompletion: true),
    Shell.powershell => powershellScript(
      'dart',
      exec,
      enableDefaultCompletion: true,
    ),
    Shell.zsh => zshScript('dart', exec, enableDefaultCompletion: true),
  };
}

void _addRootOptions(Command command) {
  _flag(command, 'verbose', 'Show additional command output', alias: 'v');
  _flag(command, 'version', 'Print the Dart SDK version');
  _flag(command, 'enable-analytics', 'Enable analytics');
  _flag(command, 'disable-analytics', 'Disable analytics');
  _flag(command, 'suppress-analytics', 'Disallow analytics for this dart run');
  _flag(command, 'help', 'Print this usage information', alias: 'h');
}

void _addCommands(Tab tab, List<(String, String)> commands, {String? prefix}) {
  for (final (name, description) in commands) {
    tab.command([if (prefix != null) prefix, name].join(' '), description);
  }
}

Command _command(Tab tab, String name, String description) {
  return tab.commands[name] ?? tab.command(name, description);
}

void _flag(Command command, String name, String description, {String? alias}) {
  command.option(name, description, null, alias: alias);
}

void _value(Command command, String name, String description, {String? alias}) {
  command.option(name, description, (_, _) {}, alias: alias);
}

void _values(
  Command command,
  String name,
  String description,
  List<(String, String)> values, {
  String? alias,
}) {
  command.option(name, description, (complete, _) {
    for (final (value, description) in values) {
      complete(value, description);
    }
  }, alias: alias);
}

const _dartCommands = <(String, String)>[
  ('help', 'Print help for a command'),
  ('install', 'Install or upgrade a Dart CLI tool for global use'),
  ('installed', 'List globally installed Dart CLI tools'),
  ('uninstall', 'Remove a globally installed Dart CLI tool'),
  ('build', 'Build a Dart application including code assets'),
  ('compile', 'Compile Dart to various formats'),
  ('create', 'Create a new Dart project'),
  ('pub', 'Work with packages'),
  ('run', 'Run a Dart program from a file or package'),
  ('test', 'Run tests for a project'),
  ('analyze', 'Analyze Dart code in a directory'),
  ('doc', 'Generate API documentation for Dart projects'),
  ('fix', 'Apply automated fixes to Dart source code'),
  ('format', 'Idiomatically format Dart source code'),
  ('devtools', 'Open DevTools'),
  ('info', 'Show diagnostic information'),
];

const _dartHelpCommands = <(String, String)>[
  ('install', 'Install or upgrade a Dart CLI tool for global use'),
  ('installed', 'List globally installed Dart CLI tools'),
  ('uninstall', 'Remove a globally installed Dart CLI tool'),
  ('build', 'Build a Dart application including code assets'),
  ('compile', 'Compile Dart to various formats'),
  ('create', 'Create a new Dart project'),
  ('pub', 'Work with packages'),
  ('run', 'Run a Dart program from a file or package'),
  ('test', 'Run tests for a project'),
  ('analyze', 'Analyze Dart code in a directory'),
  ('doc', 'Generate API documentation for Dart projects'),
  ('fix', 'Apply automated fixes to Dart source code'),
  ('format', 'Idiomatically format Dart source code'),
  ('devtools', 'Open DevTools'),
  ('info', 'Show diagnostic information'),
];

const _buildCommands = <(String, String)>[
  ('cli', 'Build a Dart command-line application'),
];

const _compileCommands = <(String, String)>[
  ('js', 'Compile Dart to JavaScript'),
  ('jit-snapshot', 'Compile Dart to a JIT snapshot'),
  ('kernel', 'Compile Dart to a kernel snapshot'),
  ('exe', 'Compile Dart to a self-contained executable'),
  ('aot-snapshot', 'Compile Dart to an AOT snapshot'),
  ('wasm', 'Compile Dart to a WebAssembly module'),
];

const _infoCommands = <(String, String)>[
  ('dump', 'Show diagnostic information'),
  ('record-performance', 'Record performance data'),
];

const _pubCommands = <(String, String)>[
  ('add', 'Add dependencies to pubspec.yaml'),
  ('bump', 'Increase the current package version'),
  ('cache', 'Work with the system cache'),
  ('deps', 'Print package dependencies'),
  ('downgrade', 'Downgrade dependencies'),
  ('global', 'Work with global packages'),
  ('get', 'Get package dependencies'),
  ('publish', 'Publish the current package to pub.dev'),
  ('outdated', 'Analyze dependency upgrades'),
  ('remove', 'Remove dependencies from pubspec.yaml'),
  ('unpack', 'Download and unpack a package'),
  ('upgrade', 'Upgrade dependencies'),
  ('login', 'Log into pub.dev'),
  ('logout', 'Log out of pub.dev'),
  ('token', 'Manage hosted repository tokens'),
  ('workspace', 'Work with the pub workspace'),
];

const _pubCacheCommands = <(String, String)>[
  ('add', 'Install a package'),
  ('clean', 'Clear the global PUB_CACHE'),
  ('repair', 'Reinstall cached packages'),
  ('gc', 'Prune unused packages from the system cache'),
];

const _pubGlobalCommands = <(String, String)>[
  ('activate', 'Make package executables globally available'),
  ('deactivate', 'Remove a globally activated package'),
  ('list', 'List globally activated packages'),
  ('run', 'Run an executable from a globally activated package'),
];

const _pubTokenCommands = <(String, String)>[
  ('list', 'List servers with stored tokens'),
  ('add', 'Add an authentication token'),
  ('remove', 'Remove an authentication token'),
];

const _pubWorkspaceCommands = <(String, String)>[
  ('list', 'List packages in the workspace'),
];

const _createTemplates = <(String, String)>[
  ('cli', 'Command-line application with argument parsing'),
  ('console', 'Console application'),
  ('package', 'Shared Dart package'),
  ('server-shelf', 'Server app using package:shelf'),
  ('web', 'Web app using core Dart libraries'),
];

const _formatOutputs = <(String, String)>[
  ('write', 'Overwrite formatted files on disk'),
  ('show', 'Print code to terminal'),
  ('json', 'Print code and selection as JSON'),
  ('none', 'Discard output'),
];
