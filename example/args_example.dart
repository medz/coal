import 'package:args/command_runner.dart';
import 'package:coal/tab/args.dart';

class DevCommand extends Command {
  DevCommand() {
    argParser.addOption('port', abbr: 'p');
    argParser.addOption('env', abbr: 'e', allowed: ['dev', 'prod']);
  }

  @override
  String get description => 'Local development';

  @override
  String get name => 'dev';
}

class BuildCommand extends Command {
  BuildCommand() {
    argParser.addOption('output', abbr: 'o');
    argParser.addFlag('watch', abbr: 'w');
  }

  @override
  String get description => 'Build the application';

  @override
  String get name => 'build';
}

void main(List<String> args) {
  final runner = CommandRunner('Demo', '');
  runner.addCommand(DevCommand());
  runner.addCommand(BuildCommand());

  tab(runner);
  runner.run(args);
}
