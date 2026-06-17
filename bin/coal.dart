import 'dart:io';

import 'package:coal/src/tab/dart_cli.dart';
import 'package:coal/tab.dart';

void main(List<String> args) {
  if (_wantsHelp(args)) return _printUsage();

  if (args.firstOrNull == 'tab') {
    return _tab(args.skip(1).toList());
  }

  _fail('Unknown command: ${args.first}');
}

void _tab(List<String> args) {
  if (_wantsHelp(args)) return _printTabUsage();

  if (args.firstOrNull == 'dart') {
    return _dartTab(args.skip(1).toList());
  }

  _fail('Unknown tab target: ${args.first}');
}

void _dartTab(List<String> args) {
  if (_wantsHelp(args)) return _printDartTabUsage();

  if (args.firstOrNull == 'complete') {
    if (args.length >= 2 && args[1] == '--') {
      return dartCliTab().parse(args.skip(2));
    }
    _fail('Usage: coal tab dart complete -- [args...]');
  }

  if (args.length != 1) {
    _fail('Usage: coal tab dart <bash|zsh|fish|powershell>');
  }

  final shell = _shell(args.single);
  stdout.write(dartCliCompletionScript(shell));
}

Shell _shell(String name) {
  final normalized = name.trim().toLowerCase();
  return Shell.values.firstWhere(
    (shell) => shell.name == normalized,
    orElse: () => _fail('Unsupported shell: $name'),
  );
}

bool _wantsHelp(List<String> args) {
  return args.isEmpty || args.first == '--help' || args.first == '-h';
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}

void _printUsage() {
  stdout.writeln('Usage: coal <command>');
  stdout.writeln();
  stdout.writeln('Commands:');
  stdout.writeln('  tab   Shell completion setup');
}

void _printTabUsage() {
  stdout.writeln('Usage: coal tab <target>');
  stdout.writeln();
  stdout.writeln('Targets:');
  stdout.writeln('  dart   Dart SDK command completion');
}

void _printDartTabUsage() {
  stdout.writeln('Usage: coal tab dart <shell>');
  stdout.writeln();
  stdout.writeln('Shells: bash, zsh, fish, powershell');
}
