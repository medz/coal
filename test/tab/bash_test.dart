import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('bash shell completion', () {
    test('should generate a valid bash completion script', () {
      final script = bash(name, exec);

      expect(script, contains('requestComp="$exec complete --'));
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.error})) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.noSpace})) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.keepOrder})) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.noFileCompletion})) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.filterFileExtension})) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & ${ShellCompleteDirective.filterDirectory})) -ne 0 ]]',
        ),
      );
    });

    test('should handle special characters in the name', () {
      final script = bash(specialName, exec);
      expect(script, contains('${escapedName}_debug()'));
      expect(script, contains('${escapedName}_complete()'));
      expect(
        script,
        contains('complete -F ${escapedName}_complete $specialName'),
      );
    });
  });
}
