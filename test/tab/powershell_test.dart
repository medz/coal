import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('powershell completion', () {
    test('should include language mode fallback for completion results', () {
      final script = Shell.powershell.generate(name, exec);

      expect(
        script,
        contains(
          '\$ExecutionContext.SessionState.LanguageMode -eq "FullLanguage"',
        ),
      );
      expect(
        script,
        contains(
          '\$CompletionText = \$(\$comp.Name | __${name}_escapeStringWithSpecialChars) + \$Space',
        ),
      );
      expect(
        script,
        contains('\$CompletionText = "\$(\$comp.Name)\$Description"'),
      );
    });
  });
}
