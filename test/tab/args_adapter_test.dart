import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:coal/tab/args.dart' as coal;
import 'package:test/test.dart';

List<String> captureOutput(void Function() fn) {
  final lines = <String>[];
  runZoned(
    fn,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => lines.add(line),
    ),
  );
  return lines;
}

class ServeCommand extends Command<void> {
  ServeCommand() {
    argParser.addFlag('watch', abbr: 'w', help: 'Watch for changes');
  }

  @override
  String get name => 'serve';

  @override
  String get description => 'Run dev server';
}

class ProjectCommand extends Command<void> {
  ProjectCommand() {
    addSubcommand(TaskCommand());
  }

  @override
  String get name => 'project';

  @override
  String get description => 'Project operations';
}

class TaskCommand extends Command<void> {
  TaskCommand() {
    addSubcommand(RunCommand());
  }

  @override
  String get name => 'task';

  @override
  String get description => 'Task operations';
}

class RunCommand extends Command<void> {
  @override
  String get name => 'run';

  @override
  String get description => 'Run task';
}

void main() {
  group('tab args adapter', () {
    test('does not leak subcommand flags into root completion', () {
      final runner = CommandRunner<void>('coal', 'test');
      runner.addCommand(ServeCommand());

      final tab = coal.tab(runner);
      final rootOutput = captureOutput(() => tab.parse(['--wa']));
      final serveOutput = captureOutput(() => tab.parse(['serve', '--wa']));

      expect(rootOutput.any((line) => line.startsWith('--watch\t')), isFalse);
      expect(
        serveOutput.any(
          (line) => line.startsWith('--watch\tWatch for changes'),
        ),
        isTrue,
      );
    });

    test('completes nested subcommands with full command path', () {
      final runner = CommandRunner<void>('coal', 'test');
      runner.addCommand(ProjectCommand());

      final tab = coal.tab(runner);
      final output = captureOutput(() => tab.parse(['project', 'task', '']));

      expect(output.any((line) => line.startsWith('run\tRun task')), isTrue);
      expect(output.last, ':4');
    });
  });
}
