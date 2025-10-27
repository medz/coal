import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('zsh shell completion', () {
    test('should handle special characters in the name', () {
      final script = Shell.zsh.generate(specialName, exec);
      expect(script, contains('#compdef $specialName'));
      expect(script, contains('compdef ${escapedName}_complete $specialName'));
      expect(script, contains('${escapedName}_debug()'));
      expect(script, contains('${escapedName}_complete()'));
    });
  });
}
