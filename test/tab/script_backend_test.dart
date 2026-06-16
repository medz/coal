import 'package:coal/tab.dart';
import 'package:test/test.dart';

void main() {
  group('shell completion command', () {
    test('uses the default complete command', () {
      expect(
        Shell.bash.generate('coal', 'coal'),
        contains('requestComp="coal complete --'),
      );
    });

    test('supports a custom completion command', () {
      final scripts = <String>[
        Shell.bash.generate(
          'dart',
          'coal dart-complete',
          completionCommand: '--',
        ),
        Shell.zsh.generate(
          'dart',
          'coal dart-complete',
          completionCommand: '--',
        ),
        Shell.fish.generate(
          'dart',
          'coal dart-complete',
          completionCommand: '--',
        ),
        Shell.powershell.generate(
          'dart',
          'coal dart-complete',
          completionCommand: '--',
        ),
      ];

      for (final script in scripts) {
        expect(script, contains('coal dart-complete --'));
        expect(script, isNot(contains('coal dart-complete complete --')));
      }
    });
  });
}
