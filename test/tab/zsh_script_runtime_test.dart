@Tags(['script-runtime'])
library;

import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

import 'script_runtime_helpers.dart';

void main() {
  final runtime = ScriptRuntime();
  final runZsh = runtime.runZsh;

  group('zsh tab script runtime', () {
    test('zsh script passes syntax check', () async {
      final tmp = await Directory.systemTemp.createTemp('coal-tab-zsh-syntax-');
      addTearDown(() => tmp.delete(recursive: true));

      final script = await writeScript(
        '${tmp.path}/_coaltest',
        Shell.zsh.generate('coaltest', '/tmp/mock-complete'),
      );
      final result = await Process.run('zsh', ['-n', script.path]);

      expect(result.exitCode, 0, reason: 'zsh -n failed: ${result.stderr}');
    }, skip: !runZsh);

    test(
      'zsh script treats executable paths as data, not shell code',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-zsh-exec-injection-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final pwned = File('${tmp.path}/pwned');
        final called = File('${tmp.path}/called');
        final dangerDir = Directory('${tmp.path}/\$(touch pwned)');
        await dangerDir.create();
        final backend = await writeScript(
          '${dangerDir.path}/mock_complete.sh',
          '''#!/usr/bin/env bash
touch "\$CALLED"
if [[ "\$1" == "complete" && "\$2" == "--" ]]; then
  printf '%s\\n' 'value\\tValue option' ':4'
  exit 0
fi
exit 1
''',
          executable: true,
        );
        final script = await writeScript(
          '${tmp.path}/_coaltest',
          Shell.zsh.generate('coaltest', shellQuote(backend.path)),
        );

        final harness = r'''
autoload -Uz compinit
compinit -D
source "$COMPLETION_FILE"
words=(coaltest --port=)
CURRENT=2
BUFFER='coaltest --port='
CURSOR=${#BUFFER}
_coaltest >/dev/null 2>&1 || true
''';

        final result = await Process.run(
          'zsh',
          ['-fc', harness],
          environment: {'COMPLETION_FILE': script.path, 'CALLED': called.path},
          workingDirectory: tmp.path,
        );

        expect(result.exitCode, 0, reason: 'zsh failed: ${result.stderr}');
        expect(await called.exists(), isTrue);
        expect(await pwned.exists(), isFalse);
      },
      skip: !runZsh || Platform.isWindows,
    );

    test('zsh equal-sign flag prefix treats current token as data', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-zsh-injection-',
      );
      addTearDown(() => tmp.delete(recursive: true));

      final pwned = File('${tmp.path}/pwned');
      final backend = await writeScript(
        '${tmp.path}/mock_complete.sh',
        '''#!/usr/bin/env bash
if [[ "\$1" == "complete" && "\$2" == "--" ]]; then
  printf '%s\\n' 'value\\tValue option' ':4'
  exit 0
fi
exit 1
''',
        executable: true,
      );
      final script = await writeScript(
        '${tmp.path}/_coaltest',
        Shell.zsh.generate('coaltest', backend.path),
      );

      final harness = r'''
autoload -Uz compinit
compinit -D
source "$COMPLETION_FILE"
words=(coaltest '--port=$(touch "$PWNED")=')
CURRENT=2
BUFFER='coaltest --port=$(touch "$PWNED")='
CURSOR=${#BUFFER}
_coaltest >/dev/null 2>&1 || true
''';

      final result = await Process.run(
        'zsh',
        ['-fc', harness],
        environment: {'COMPLETION_FILE': script.path, 'PWNED': pwned.path},
      );

      expect(result.exitCode, 0, reason: 'zsh failed: ${result.stderr}');
      expect(await pwned.exists(), isFalse);
    }, skip: !runZsh);
  });
}
