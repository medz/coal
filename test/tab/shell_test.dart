import 'package:coal/tab.dart';
import 'package:test/test.dart';

void main() {
  group('shell script generation', () {
    test('rejects unsafe command names for every shell', () {
      const unsafeNames = [
        'bad name',
        '-bad',
        r'$(touch pwned)',
        'bad;touch-pwned',
        "bad'name",
      ];

      for (final shell in Shell.values) {
        for (final name in unsafeNames) {
          expect(
            () => shell.generate(name, '/tmp/coal'),
            throwsA(isA<UnsupportedError>()),
            reason: '${shell.name} accepted unsafe command name $name',
          );
        }
      }
    });

    test('allows shell-safe command names for every shell', () {
      const safeNames = ['coal', 'coal-test:app', 'coal.test_app'];

      for (final shell in Shell.values) {
        for (final name in safeNames) {
          expect(shell.generate(name, '/tmp/coal'), contains(name));
        }
      }
    });

    test('uses collision-resistant generated function names', () {
      final dotted = Shell.bash.generate('foo.bar', '/tmp/coal');
      final crafted = Shell.bash.generate('foo_bar_cb942ef4', '/tmp/coal');

      expect(dotted, contains('__foo_x2e_bar_complete'));
      expect(crafted, contains('__foo__bar__cb942ef4_complete'));
      expect(crafted, isNot(contains('__foo_x2e_bar_complete')));
    });

    test('normalizes exec command prefixes into shell argument lists', () {
      final bash = Shell.bash.generate(
        'coaltest',
        "/usr/bin/env 'path with spaces/tool'",
      );
      final powershell = Shell.powershell.generate(
        'coaltest',
        r"'C:\Program Files\coal.exe'",
      );

      expect(
        bash,
        contains("requestComp=('/usr/bin/env' 'path with spaces/tool'"),
      );
      expect(bash, isNot(contains('eval "\$requestComp"')));
      expect(
        powershell,
        contains(r"$RequestComp = @('C:\Program Files\coal.exe'"),
      );
      expect(powershell, isNot(contains('Invoke-Expression')));
    });

    test('preserves literal backslashes inside double quoted prefixes', () {
      final bash = Shell.bash.generate(
        'coaltest',
        r'"C:\Program Files\tool.exe"',
      );
      final zsh = Shell.zsh.generate(
        'coaltest',
        r'"C:\Program Files\tool.exe"',
      );
      final fish = Shell.fish.generate(
        'coaltest',
        r'"C:\Program Files\tool.exe"',
      );

      expect(bash, contains(r"requestComp=('C:\Program Files\tool.exe'"));
      expect(zsh, contains(r"requestComp=('C:\Program Files\tool.exe'"));
      expect(
        fish,
        contains(r"set -l requestComp 'C:\\Program Files\\tool.exe'"),
      );
    });
  });
}
