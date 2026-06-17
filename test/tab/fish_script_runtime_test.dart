@Tags(['script-runtime'])
library;

import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

import 'script_runtime_helpers.dart';

void main() {
  final runtime = ScriptRuntime();
  final runFish = runtime.runFish;

  group('fish tab script runtime', () {
    test('fish script passes syntax check', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-fish-syntax-',
      );
      addTearDown(() => tmp.delete(recursive: true));

      final script = await writeScript(
        '${tmp.path}/coaltest.fish',
        Shell.fish.generate('coaltest', '/tmp/mock-complete'),
      );
      final result = await Process.run('fish', ['--no-execute', script.path]);

      expect(
        result.exitCode,
        0,
        reason: 'fish --no-execute failed: ${result.stderr}',
      );
    }, skip: !runFish);

    test(
      'fish script executes completion flow end-to-end',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-fish-runtime-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final backend = await writeScript(
          '${tmp.path}/mock_complete.sh',
          '''#!/usr/bin/env bash
if [[ "\$1" == "complete" && "\$2" == "--" ]]; then
  printf '%s\\n' '--name\\tName option' ':0'
  exit 0
fi
exit 1
''',
          executable: true,
        );
        final script = await writeScript(
          '${tmp.path}/coaltest.fish',
          Shell.fish.generate('coaltest', '/usr/bin/env bash ${backend.path}'),
        );
        final result = await Process.run(
          'fish',
          ['-c', r'source "$COMPLETION_FILE"; complete -C "coaltest --na"'],
          environment: {'COMPLETION_FILE': script.path},
        );

        expect(
          result.exitCode,
          0,
          reason: 'fish completion failed: ${result.stderr}',
        );
        expect(result.stdout, contains('--name'));
      },
      skip: !runFish || Platform.isWindows,
    );
  });
}
