import 'dart:async';

import 'package:coal/tab.dart';
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

void main() {
  group('tab parser', () {
    test('completes commands after non-boolean option values', () {
      final tab = Tab();
      tab.option('config', 'Configuration', (complete, _) {
        complete('prod', 'Production');
      });
      tab.command('deploy', 'Deploy project');

      final output = captureOutput(() => tab.parse(['--config', 'prod', 'de']));

      expect(output, contains('deploy\tDeploy project'));
      expect(output.last, ':4');
    });
  });
}
