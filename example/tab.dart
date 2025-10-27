import 'dart:io';

import 'package:coal/tab.dart';

void main(List<String> input) {
  final tab = Tab();

  final dev = tab.command('dev', 'Start development server');
  dev.option('port', 'Port number', (complete, _) {
    complete('3000', 'Development port');
    complete('8080', 'Production port');
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
