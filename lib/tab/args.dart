// ignore: depend_on_referenced_packages
import 'package:args/command_runner.dart';
import 'package:coal/tab.dart' hide Command;

class CompleteCommand extends Command {
  CompleteCommand(this.runner);

  late final tab = Tab();

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
    return '$invocation <${Shell.values.map((e) => e.name).join('|')}>';
  }

  @override
  void run() {
    final shell = argResults?.arguments.firstOrNull;
    if (shell == '--') {
      final args = argResults?.arguments.skip(1) ?? const <String>[];
      return tab.parse(args);
    }

    // return tab.setup();
  }
}

Tab tab(CommandRunner runner) {
  final commend = CompleteCommand(runner);
  runner.addCommand(commend);

  // TODO register

  return commend.tab;
}

void main(List<String> input) {
  final runner = CommandRunner('tab', '');
  tab(runner);
  runner.run(input);
}
