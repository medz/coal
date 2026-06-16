import 'dart:io';
import 'package:coal/tab.dart';

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
      final (name, exec) = resolveExecInfo();
      return tab.setup(name, exec, shell);
    }
  }

  print(input);
}

(String, String) resolveExecInfo() {
  final script = Platform.script.toFilePath();
  final exec = Platform.resolvedExecutable;
  final scriptName = script.split(Platform.pathSeparator).last;
  final name = scriptName.endsWith('.dart')
      ? scriptName.substring(0, scriptName.length - '.dart'.length)
      : scriptName;

  if (script == exec) return (name, script);
  return (name, 'dart $script');
}
