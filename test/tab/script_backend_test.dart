import 'package:coal/tab.dart';
import 'package:test/test.dart';

void main() {
  group('shell completion backend', () {
    test('uses the default complete backend', () {
      expect(
        Shell.bash.generate('coal', 'coal'),
        contains('requestComp="coal complete --'),
      );
    });

    test('supports a custom backend command', () {
      final scripts = <String>[
        Shell.bash.generate('dart', 'coal dart-complete', backend: '--'),
        Shell.zsh.generate('dart', 'coal dart-complete', backend: '--'),
        Shell.fish.generate('dart', 'coal dart-complete', backend: '--'),
        Shell.powershell.generate('dart', 'coal dart-complete', backend: '--'),
      ];

      for (final script in scripts) {
        expect(script, contains('coal dart-complete --'));
        expect(script, isNot(contains('coal dart-complete complete --')));
      }
    });
  });
}
