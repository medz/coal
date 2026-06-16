import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:coal/tab.dart' as coal;

import '../src/tab/shell_command_name.dart' as shell_names;

/// Adds a `complete` subcommand that prints shell completion scripts.
class CompleteCommand extends Command {
  CompleteCommand(this.runner);

  late final tab = coal.Tab();

  @override
  final CommandRunner runner;

  @override
  String get name => 'complete';

  @override
  String get description =>
      '${runner.executableName} Generate completion script';

  @override
  String get invocation {
    final parents = [name];
    for (Command? command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    final invocation = parents.reversed.join(' ');
    return '$invocation <${coal.Shell.values.map((e) => e.name).join('|')}>';
  }

  @override
  void run() {
    final shell = argResults?.arguments.firstOrNull;
    if (shell == '--') {
      final args = argResults?.arguments.skip(1) ?? const <String>[];
      return tab.parse(args);
    }

    final targetShell = resolveShell(shell);
    final (name, exec) = resolveExecInfo(targetShell);
    print(targetShell.generate(name, exec));
  }
}

extension on CompleteCommand {
  coal.Shell resolveShell(String? shellName) {
    shellName = shellName?.trim().toLowerCase();
    return coal.Shell.values.firstWhere(
      (shell) => shell.name == shellName,
      orElse: () => throw UnsupportedError('Unsupported shell'),
    );
  }

  (String, String) resolveExecInfo(coal.Shell shell) {
    final script = Platform.script.toFilePath();
    final name = script.split(Platform.pathSeparator).last;

    if (isDartSourceMode(script)) {
      throw UnsupportedError(
        'Shell completion setup requires a compiled executable. '
        'Run `dart compile exe` first, then call the compiled binary.',
      );
    }

    validateCommandName(name);

    return (name, quotePath(script, shell));
  }

  bool isDartSourceMode(String script) {
    if (!script.endsWith('.dart')) return false;

    final executableName = Platform.resolvedExecutable
        .split(Platform.pathSeparator)
        .last
        .toLowerCase();
    return executableName == (Platform.isWindows ? 'dart.exe' : 'dart');
  }

  void validateCommandName(String name) {
    shell_names.validateShellCommandName(
      name,
      context: 'Shell completion setup requires an executable name',
      suffix: '. Compile to a shell-safe output name.',
    );
  }

  String quotePath(String path, coal.Shell shell) {
    return switch (shell) {
      coal.Shell.powershell => "'${path.replaceAll("'", "''")}'",
      _ => "'${path.replaceAll("'", r"'\''")}'",
    };
  }
}

/// Registers tab completion definitions on a `CommandRunner`.
coal.Tab tab(CommandRunner runner) {
  final command = CompleteCommand(runner), tab = command.tab;
  runner.addCommand(command);

  void optionComplete(coal.Complete complete, Option option) {
    if (option.allowed != null) {
      for (final value in option.allowed!) {
        final description = option.allowedHelp?[value] ?? '';
        complete(value, description);
      }
    }
  }

  coal.Option createOption(coal.Command command, String name, Option option) {
    if (option.isFlag) {
      return command.option(name, option.help ?? '', null, alias: option.abbr);
    }

    return command.option(
      name,
      option.help ?? '',
      (complete, _) => optionComplete(complete, option),
      alias: option.abbr,
    );
  }

  void optionCompletions(coal.Command def, ArgParser parser) {
    for (final MapEntry(:key, :value) in parser.options.entries) {
      final option = createOption(def, key, value);
      for (final alias in value.aliases) {
        def.option(alias, option.description, option.handler);
      }
    }
  }

  void subCommandCompletions(coal.Command def, Command command) {
    for (final MapEntry(:key, :value) in command.subcommands.entries) {
      final path = [if (def.value.isNotEmpty) def.value, key].join(' ');
      final subDef = tab.command(path, value.description);
      optionCompletions(subDef, value.argParser);
      subCommandCompletions(subDef, value);
    }
  }

  optionCompletions(tab, runner.argParser);
  for (final MapEntry(:key, :value) in runner.commands.entries) {
    final command = tab.command(key, value.description);
    if (key == 'complete') {
      command.argument('shell', (complete, _) {
        complete('bash', 'Bash completion');
        complete('zsh', 'Zsh completion');
        complete('fish', 'Fish completion');
        complete('powershell', 'PowerShell completion');
      });
      continue;
    }

    optionCompletions(command, value.argParser);
    subCommandCompletions(command, value);
  }

  return tab;
}
