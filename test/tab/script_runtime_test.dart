@Tags(['script-runtime'])
library;

import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

bool hasCommand(String command) {
  try {
    final lookup = Platform.isWindows ? 'where' : 'which';
    final result = Process.runSync(lookup, [command]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<File> writeScript(
  String path,
  String content, {
  bool executable = false,
}) async {
  final file = File(path);
  await file.writeAsString(content);
  if (executable && !Platform.isWindows) {
    await Process.run('chmod', ['+x', file.path]);
  }
  return file;
}

void main() {
  final hasBash = hasCommand('bash');
  final hasZsh = hasCommand('zsh');
  final hasFish = hasCommand('fish');
  final hasPwsh = hasCommand('pwsh');
  final requireAllShells =
      Platform.environment['COAL_REQUIRE_ALL_SHELLS'] == 'true';

  group('tab script runtime', () {
    test('required shells are available when strict mode is enabled', () {
      if (!requireAllShells) return;
      expect(
        hasBash,
        isTrue,
        reason: 'bash is required for strict runtime checks',
      );
      expect(
        hasZsh,
        isTrue,
        reason: 'zsh is required for strict runtime checks',
      );
      expect(
        hasFish,
        isTrue,
        reason: 'fish is required for strict runtime checks',
      );
      expect(
        hasPwsh,
        isTrue,
        reason: 'pwsh is required for strict runtime checks',
      );
    });

    test('bash script passes syntax check', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-bash-syntax-',
      );
      addTearDown(() => tmp.delete(recursive: true));

      final script = await writeScript(
        '${tmp.path}/coaltest.bash',
        Shell.bash.generate('coaltest', '/tmp/mock-complete'),
      );
      final result = await Process.run('bash', ['-n', script.path]);

      expect(result.exitCode, 0, reason: 'bash -n failed: ${result.stderr}');
    }, skip: !hasBash && !requireAllShells);

    test(
      'bash script executes completion flow end-to-end',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-bash-runtime-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final backend = await writeScript(
          '${tmp.path}/mock_complete.sh',
          '''#!/usr/bin/env bash
if [[ "\$1" == "complete" && "\$2" == "--" ]]; then
  printf '%s\n' '--name\tName option' ':0'
  exit 0
fi
exit 1
''',
          executable: true,
        );

        final script = await writeScript(
          '${tmp.path}/coaltest.bash',
          Shell.bash.generate('coaltest', backend.path),
        );

        final harness = r'''
set -euo pipefail

_get_comp_words_by_ref() {
  local OPTIND opt
  while getopts "n:" opt; do :; done
  shift $((OPTIND - 1))

  local curvar="$1" prevvar="$2" wordsvar="$3" cwordvar="$4"
  printf -v "$curvar" '%s' "${COMP_WORDS[COMP_CWORD]}"
  if (( COMP_CWORD > 0 )); then
    printf -v "$prevvar" '%s' "${COMP_WORDS[COMP_CWORD-1]}"
  else
    printf -v "$prevvar" ''
  fi
  eval "$wordsvar=(\"${COMP_WORDS[@]}\")"
  printf -v "$cwordvar" '%s' "$COMP_CWORD"
}

source "$COMPLETION_FILE"
COMP_WORDS=(coaltest --na)
COMP_CWORD=1
__coaltest_complete
printf '%s\n' "${COMPREPLY[@]}"
''';

        final result = await Process.run(
          'bash',
          ['-lc', harness],
          environment: {'COMPLETION_FILE': script.path},
        );

        expect(
          result.exitCode,
          0,
          reason: 'bash runtime failed: ${result.stderr}',
        );
        final output = (result.stdout as String)
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        expect(output, contains('--name'));
      },
      skip: !hasBash && !requireAllShells,
    );

    test('zsh script passes syntax check', () async {
      final tmp = await Directory.systemTemp.createTemp('coal-tab-zsh-syntax-');
      addTearDown(() => tmp.delete(recursive: true));

      final script = await writeScript(
        '${tmp.path}/_coaltest',
        Shell.zsh.generate('coaltest', '/tmp/mock-complete'),
      );
      final result = await Process.run('zsh', ['-n', script.path]);

      expect(result.exitCode, 0, reason: 'zsh -n failed: ${result.stderr}');
    }, skip: !hasZsh && !requireAllShells);

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
    }, skip: !hasFish && !requireAllShells);

    test(
      'powershell script loads without parser errors',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-pwsh-syntax-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final script = await writeScript(
          '${tmp.path}/coaltest.ps1',
          Shell.powershell.generate('coaltest', '/tmp/mock-complete'),
        );
        final result = await Process.run('pwsh', [
          '-NoProfile',
          '-NonInteractive',
          '-File',
          script.path,
        ]);

        expect(
          result.exitCode,
          0,
          reason: 'pwsh load failed: ${result.stderr}',
        );
      },
      skip: !hasPwsh && !requireAllShells,
    );
  });
}
