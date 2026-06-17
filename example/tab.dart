import 'dart:io';
import 'package:coal/tab.dart';

final _supportedCommandName = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.:-]*$');

void main(List<String> input) {
  final tab = Tab();

  final dev = tab.command('dev', 'Start development server');
  dev.option('port', 'Port number', (complete, _) {
    complete('0', 'Any port');
    complete('80', 'HTTP port');
    complete('443', 'HTTPS port');
    complete('3000', 'Development port');
  });

  final complete = tab.command('complete', '<TAB> autocompletion');
  complete.argument('shell', (complete, _) {
    complete('bash', 'Setup bash shell completion');
    complete('zsh', 'Setup zsh shell completion');
    complete('fish', 'Setup fish shell completion');
    complete('powershell', 'Setup powershell shell completion');
  });

  if (input.firstOrNull == 'complete') {
    final shell = input.elementAtOrNull(1);
    if (shell == '--') {
      final args = input.skip(2);
      return tab.parse(args);
    } else {
      final targetShell = resolveShell(shell);
      final (name, exec) = resolveExecInfo(targetShell);
      print(targetShell.generate(name, exec));
      return;
    }
  }

  print(input);
}

Shell resolveShell(String? shellName) {
  shellName = shellName?.trim().toLowerCase();
  return Shell.values.firstWhere(
    (shell) => shell.name == shellName,
    orElse: () => throw UnsupportedError('Unsupported shell'),
  );
}

(String, String) resolveExecInfo(Shell shell) {
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
  if (_supportedCommandName.hasMatch(name)) return;

  throw UnsupportedError(
    'Shell completion setup requires an executable name containing only '
    'letters, numbers, dot, underscore, hyphen, or colon, and starting '
    'with a letter, number, or underscore. '
    'Compile to a shell-safe output name.',
  );
}

String quotePath(String path, Shell shell) {
  return switch (shell) {
    Shell.powershell => "'${path.replaceAll("'", "''")}'",
    _ => "'${path.replaceAll("'", r"'\''")}'",
  };
}
