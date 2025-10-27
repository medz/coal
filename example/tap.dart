import 'dart:io';

import 'package:coal/tab.dart';

void main(List<String> input) {
  final tab = Tab();
  final dev = tab.command('dev', 'Start development server');
  dev.option('port', 'Port number', (_, complete, _) {
    complete('3000', 'Development port');
    complete('8080', 'Production port');
  });

  if (input.firstOrNull == 'complete') {
    final shell = input.elementAtOrNull(1);
    if (shell == '--') {
      final args = input.skip(2);
      tab.parse(args);
    } else {
      tab.setup('tap', 'dart ${Platform.script}', shell);
    }
  }
}
