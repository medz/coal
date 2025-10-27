// ignore: depend_on_referenced_packages
import 'package:args/args.dart';
// ignore: depend_on_referenced_packages
import 'package:args/command_runner.dart';
import 'package:coal/tab.dart' hide Command;

class GenerateShellScriptCommand extends Command {
  GenerateShellScriptCommand(this.shell);

  final Shell shell;

  @override
  String get name => shell.name;

  @override
  String get description => switch (shell) {
    Shell.bash => 'Generate a bash shell script',
    Shell.zsh => 'Generate a zsh shell script',
    Shell.fish => 'Generate a fish shell script',
    Shell.powershell => 'Generate a powershell shell script',
  };

  @override
  void run() {}
}

class SetupCommand extends Command {
  SetupCommand(CommandRunner runner) {
    for (final shell in Shell.values) {
      addSubcommand(GenerateShellScriptCommand(shell));
    }
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Setip';

  @override
  void run() {
    print('Setup command completion');
  }
}

class CompateCommand extends Command {
  CompateCommand() {
    addSubcommand(SetupCommand(runner));
  }

  @override
  final CommandRunner runner;

  @override
  String get name => 'compate';

  @override
  String get description => '${runner.executableName} command completion';

  @override
  void run() {
    print('Setup command completion');
  }
}

void tab(ArgParser argParser, Iterable<String> input) {
  final command = CompateCommand();
  argParser.addCommand(command.name, command.argParser);
}
