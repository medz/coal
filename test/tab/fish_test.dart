import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

void main() {
  group('fish shell completion', () {
    test('should include updated directive and request handling', () {
      final script = Shell.fish.generate(name, exec);

      expect(
        script,
        contains(
          'set -l requestComp "$exec complete -- \$args[2..-1] \$last_arg"',
        ),
      );
      expect(
        script,
        contains(
          r'if test (math "$directive_num & $ShellCompDirectiveError") -ne 0',
        ),
      );
      expect(
        script,
        contains(
          r'if test (math "$directive_num & $ShellCompDirectiveNoFileComp") -eq 0',
        ),
      );
      expect(
        script,
        contains(
          'set -l flag_prefix (string match -r -- \'-.*=\' "\$last_arg")',
        ),
      );
    });

    test('should handle special characters in the name', () {
      final script = Shell.fish.generate(specialName, exec);
      expect(script, contains('function __${escapedName}_debug'));
      expect(script, contains('function __${escapedName}_perform_completion'));
      expect(
        script,
        contains(
          'complete -c $specialName -f -a "(eval __${escapedName}_perform_completion)"',
        ),
      );
    });
  });
}
