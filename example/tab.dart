import 'dart:io';

import 'package:coal/tab.dart';

import 'a.dart';

void main(List<String> input) {
  // p();

  final tab = Tab();

  final dev = tab.command('dev', 'Start development server');
  final a = dev.option('port', 'Port number', (complete, _) {
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
      return tab.setup('tab', Platform.script.toFilePath(), shell);
    }
  }

  print(input);
}
