import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('zsh shell completion', () {
    test('should handle special characters in the name', () {
      final script = Shell.zsh.generate(specialName, exec);
      expect(script, contains('#compdef $specialName'));
      expect(script, contains('compdef _$escapedName $specialName'));
      expect(script, contains('__${escapedName}_debug()'));
      expect(script, contains('_$escapedName()'));
    });

    test('should include latest no-file-completion fallback behavior', () {
      final script = Shell.zsh.generate(name, exec);
      expect(script, contains('return 1'));
      expect(
        script,
        contains(
          'if eval _describe \$keepOrder "completions" completions \${flagPrefix} \${noSpace}; then',
        ),
      );
      expect(
        script,
        contains(
          'completions from _describe; this allows other matching algorithms.',
        ),
      );
    });
  });
}
