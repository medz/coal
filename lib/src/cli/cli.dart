import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:coal/tab.dart' as coal;

import 'dart_completion.dart';

CommandRunner buildCoalCommandRunner({
  StringSink? out,
  bool Function(String command)? hasCommand,
}) {
  final runner =
      CommandRunner(
          'coal',
          'Utilities for building polished Dart command-line apps.',
        )
        ..addCommand(CoalCompleteCommand(out: out))
        ..addCommand(DartCompleteCommand(out: out))
        ..addCommand(DoctorCommand(out: out, hasCommand: hasCommand));
  return runner;
}

Future<int> runCoal(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  bool Function(String command)? hasCommand,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  final runner = buildCoalCommandRunner(
    out: stdoutSink,
    hasCommand: hasCommand,
  );

  return runZoned(
    () async {
      try {
        final result = await runner.run(args);
        return result is int ? result : 0;
      } on UsageException catch (error) {
        stderrSink.writeln(error);
        return 64;
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => stdoutSink.writeln(line),
    ),
  );
}

coal.Tab buildCoalCompletion() {
  final tab = coal.Tab();

  tab.command('doctor', 'Check local shell support used by Coal');
  tab
      .command('dart-complete', 'Generate completion for the Dart CLI')
      .argument('shell', _completeShells);
  tab
      .command('complete', 'Generate completion for the Coal CLI')
      .argument('shell', _completeShells);

  return tab;
}

void _completeShells(coal.Complete complete, Map<String, coal.Option> options) {
  for (final shell in coal.Shell.values) {
    complete(shell.name, 'Generate ${shell.name} completion');
  }
}

class CoalCompleteCommand extends Command {
  CoalCompleteCommand({StringSink? out}) : _out = out ?? stdout;

  final StringSink _out;

  @override
  String get name => 'complete';

  @override
  String get description => 'Generate completion for the Coal CLI.';

  @override
  String get invocation =>
      'coal complete <${coal.Shell.values.map((shell) => shell.name).join('|')}>';

  @override
  int run() {
    final args = argResults?.arguments ?? const <String>[];
    if (args.firstOrNull == '--') {
      buildCoalCompletion().parse(args.skip(1));
      return 0;
    }

    final shellName = args.firstOrNull;
    if (shellName == null) {
      throw UsageException('Missing shell name.', usage);
    }

    final shell = coal.Shell.values.firstWhere(
      (shell) => shell.name == shellName.trim().toLowerCase(),
      orElse: () =>
          throw UsageException('Unsupported shell: $shellName', usage),
    );
    _out.writeln(shell.generate('coal', 'coal'));
    return 0;
  }
}

class DartCompleteCommand extends Command {
  DartCompleteCommand({StringSink? out}) : _out = out ?? stdout;

  final StringSink _out;

  @override
  String get name => 'dart-complete';

  @override
  String get description => 'Generate completion for the Dart CLI.';

  @override
  String get invocation =>
      'coal dart-complete <${coal.Shell.values.map((shell) => shell.name).join('|')}>';

  @override
  int run() {
    final args = argResults?.arguments ?? const <String>[];
    if (args.firstOrNull == '--') {
      buildDartCompletion().parse(args.skip(1));
      return 0;
    }

    final shellName = args.firstOrNull;
    if (shellName == null) {
      throw UsageException('Missing shell name.', usage);
    }

    final shell = coal.Shell.values.firstWhere(
      (shell) => shell.name == shellName.trim().toLowerCase(),
      orElse: () =>
          throw UsageException('Unsupported shell: $shellName', usage),
    );
    _out.writeln(
      shell.generate('dart', 'coal dart-complete', completionCommand: '--'),
    );
    return 0;
  }
}

class DoctorCommand extends Command {
  DoctorCommand({StringSink? out, bool Function(String command)? hasCommand})
    : _out = out ?? stdout,
      _hasCommand = hasCommand ?? _defaultHasCommand;

  final StringSink _out;
  final bool Function(String command) _hasCommand;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check local shell support used by Coal.';

  @override
  int run() {
    final shells = <String>['bash', 'zsh', 'fish', 'pwsh'];
    for (final shell in shells) {
      final status = _hasCommand(shell) ? 'ok' : 'missing';
      _out.writeln('$shell: $status');
    }
    return 0;
  }
}

bool _defaultHasCommand(String command) {
  final lookup = Platform.isWindows ? 'where' : 'which';
  final result = Process.runSync(lookup, [command]);
  return result.exitCode == 0;
}
