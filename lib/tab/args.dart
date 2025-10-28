import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:args/args.dart';
// ignore: depend_on_referenced_packages
import 'package:args/command_runner.dart';
import 'package:coal/tab.dart' as coal;

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

    final (name, exec) = resolveExecInfo();
    tab.setup(name, exec, shell);
  }
}

extension on CompleteCommand {
  (String, String) resolveExecInfo() {
    final script = Platform.script.toFilePath();
    final exec = Platform.resolvedExecutable;
    // if (script.endsWith('.dart') && exec.endsWith('/dart')) {
    //   throw UnsupportedError('dart run <file> is not currently supported');
    // }

    final name = script.split(Platform.pathSeparator).last;
    if (script == exec) {
      return (name, script);
    }

    return (name, 'dart $script');
  }
}

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
      return tab.option(name, option.help ?? '', null, alias: option.abbr);
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
      final def = tab.command(key, value.description);
      optionCompletions(def, value.argParser);
      subCommandCompletions(def, value);
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
