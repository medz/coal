import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('bash shell completion', () {
    test('should generate a valid bash completion script', () {
      final script = Shell.bash.generate(name, exec);

      expect(script, contains('requestComp="$exec complete --'));
      expect(
        script,
        contains('if [[ \$((directive & \$ShellCompDirectiveError)) -ne 0 ]]'),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & \$ShellCompDirectiveNoSpace)) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & \$ShellCompDirectiveKeepOrder)) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & \$ShellCompDirectiveNoFileComp)) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & \$ShellCompDirectiveFilterFileExt)) -ne 0 ]]',
        ),
      );
      expect(
        script,
        contains(
          'if [[ \$((directive & \$ShellCompDirectiveFilterDirs)) -ne 0 ]]',
        ),
      );
      expect(script, contains('if [[ "\$directive" == "\$out" ]]; then'));
      expect(script, contains('if [[ "\$cur" == -*=* ]]; then'));
      expect(script, contains('if [[ \$(type -t compopt) == builtin ]]; then'));
      expect(script, contains('\${BASH_VERSINFO[0]} -gt 4'));
    });

    test('should handle special characters in the name', () {
      final script = Shell.bash.generate(specialName, exec);
      expect(script, contains('__${escapedName}_debug()'));
      expect(script, contains('__${escapedName}_complete()'));
      expect(
        script,
        contains('complete -F __${escapedName}_complete $specialName'),
      );
    });
  });
}
