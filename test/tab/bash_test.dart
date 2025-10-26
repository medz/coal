import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('bash shell completion', () {
    test('should generate a valid bash completion script', () {
      final script = bash(name, exec);

      expect(script, contains('# Coal bash completion for $name'));
      expect(script, contains('__coal_${name}_debug()'));

      // Check that the script contains the completion function
      expect(script, contains('__coal_${name}_complete()'));

      // Check that the script contains the completion registration
      expect(script, contains('complete -F __coal_${name}_complete $name'));

      // Check that the script uses the provided exec path
      expect(script, contains('requestComp="$exec complete --'));

      // Check that the script handles directives correctly
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
      expect(script, contains('__coal_${escapedName}_debug()'));
      expect(script, contains('__coal_${escapedName}_complete()'));
      expect(
        script,
        contains('complete -F __coal_${escapedName}_complete $specialName'),
      );
    });
  });
}
