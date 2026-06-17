@Tags(['script-runtime'])
library;

import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

import 'script_runtime_helpers.dart';

void main() {
  final runtime = ScriptRuntime();
  final runBash = runtime.runBash;

  group('bash tab script runtime', () {
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
    }, skip: !runBash);

    test('bash script executes completion flow end-to-end', () async {
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
  eval "$wordsvar=(\"\${COMP_WORDS[@]}\")"
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
    }, skip: !runBash);

    test('bash script supports exec command prefixes with arguments', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-bash-exec-prefix-',
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
        '${tmp.path}/coaltest.bash',
        Shell.bash.generate('coaltest', '/usr/bin/env bash ${backend.path}'),
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
      expect(result.stdout, contains('--name'));
    }, skip: !runBash);

    test(
      'bash script treats executable paths as data, not shell code',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-bash-exec-injection-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final pwned = File('${tmp.path}/pwned');
        final dangerDir = Directory('${tmp.path}/\$(touch pwned)');
        await dangerDir.create();
        final backend = await writeScript(
          '${dangerDir.path}/mock_complete.sh',
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
          '${tmp.path}/coaltest.bash',
          Shell.bash.generate('coaltest', shellQuote(backend.path)),
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
          workingDirectory: tmp.path,
        );

        expect(
          result.exitCode,
          0,
          reason: 'bash runtime failed: ${result.stderr}',
        );
        expect(result.stdout, contains('--name'));
        expect(await pwned.exists(), isFalse);
      },
      skip: !runBash || Platform.isWindows,
    );

    test(
      'bash script treats completion words as data, not shell code',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-bash-injection-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final pwned = File('${tmp.path}/pwned');
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
  eval "$wordsvar=(\"\${COMP_WORDS[@]}\")"
  printf -v "$cwordvar" '%s' "$COMP_CWORD"
}

source "$COMPLETION_FILE"
COMP_WORDS=(coaltest '$(touch "$PWNED")' --na)
COMP_CWORD=2
__coaltest_complete
printf '%s\n' "${COMPREPLY[@]}"
''';

        final result = await Process.run(
          'bash',
          ['-lc', harness],
          environment: {'COMPLETION_FILE': script.path, 'PWNED': pwned.path},
        );

        expect(
          result.exitCode,
          0,
          reason: 'bash runtime failed: ${result.stderr}',
        );
        expect(await pwned.exists(), isFalse);
      },
      skip: !runBash,
    );

    test(
      'bash script executes compiled binary from a path with spaces',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-runtime path-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final binary = await compileExample(
          'example/args_example.dart',
          '${tmp.path}/coal_args_example',
        );
        final scriptResult = await Process.run(binary, ['complete', 'bash']);
        expect(
          scriptResult.exitCode,
          0,
          reason: 'completion setup failed: ${scriptResult.stderr}',
        );

        final script = await writeScript(
          '${tmp.path}/coal_args_example.bash',
          scriptResult.stdout as String,
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
  eval "$wordsvar=(\"\${COMP_WORDS[@]}\")"
  printf -v "$cwordvar" '%s' "$COMP_CWORD"
}

source "$COMPLETION_FILE"
COMP_WORDS=(coal_args_example dev --e)
COMP_CWORD=2
__coal__args__example_complete
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
        expect(output, contains('--env'));
      },
      skip: !runBash || Platform.isWindows,
    );

    test(
      'compiled binary with dart suffix can generate completion setup',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-dart-suffix-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final binary = await compileExample(
          'example/args_example.dart',
          '${tmp.path}/coal_args_example.dart',
        );
        final result = await Process.run(binary, ['complete', 'bash']);

        expect(
          result.exitCode,
          0,
          reason: 'completion setup failed: ${result.stdout}\n${result.stderr}',
        );
        expect(result.stdout, contains('__coal__args__example_x2e_dart_'));
        expect(result.stdout, contains(binary));
      },
      skip: !runBash || Platform.isWindows,
    );

    test('source-mode args adapter refuses shell setup', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'example/args_example.dart',
        'complete',
        'bash',
      ]);

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}',
        contains('Shell completion setup requires a compiled executable'),
      );
    }, skip: !runBash);

    test('source-mode tab example refuses shell setup', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'example/tab.dart',
        'complete',
        'bash',
      ]);

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}',
        contains('Shell completion setup requires a compiled executable'),
      );
    }, skip: !runBash);

    test(
      'compiled binary with unsupported command name refuses shell setup',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-command-name-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        for (final name in const ['args example', '-foo']) {
          final binary = await compileExample(
            'example/args_example.dart',
            '${tmp.path}/$name',
          );
          final result = await Process.run(binary, ['complete', 'bash']);

          expect(result.exitCode, isNot(0), reason: name);
          expect(
            '${result.stdout}${result.stderr}',
            contains('Compile to a shell-safe output name'),
            reason: name,
          );
        }
      },
      skip: !runBash || Platform.isWindows,
    );

    test(
      'bash scripts for similar command names do not collide',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-collision-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final tabBinary = await compileExample(
          'example/tab.dart',
          '${tmp.path}/foo.bar',
        );
        final argsBinary = await compileExample(
          'example/args_example.dart',
          '${tmp.path}/foo_bar_cb942ef4',
        );

        final tabScriptResult = await Process.run(tabBinary, [
          'complete',
          'bash',
        ]);
        final argsScriptResult = await Process.run(argsBinary, [
          'complete',
          'bash',
        ]);
        expect(tabScriptResult.exitCode, 0);
        expect(argsScriptResult.exitCode, 0);

        final tabScript = await writeScript(
          '${tmp.path}/foo-dot.bash',
          tabScriptResult.stdout as String,
        );
        final argsScript = await writeScript(
          '${tmp.path}/foo-under.bash',
          argsScriptResult.stdout as String,
        );

        final result = await Process.run(
          'bash',
          [
            '-lc',
            'source "\$TAB_SCRIPT"; source "\$ARGS_SCRIPT"; complete -p foo.bar; complete -p foo_bar_cb942ef4',
          ],
          environment: {
            'TAB_SCRIPT': tabScript.path,
            'ARGS_SCRIPT': argsScript.path,
          },
        );

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final output = result.stdout as String;
        expect(output, contains('complete -F __foo_x2e_bar_complete foo.bar'));
        expect(
          output,
          contains(
            'complete -F __foo__bar__cb942ef4_complete foo_bar_cb942ef4',
          ),
        );
        expect(
          output,
          isNot(contains('complete -F __foo__bar__cb942ef4_complete foo.bar')),
        );
      },
      skip: !runBash || Platform.isWindows,
    );

    test(
      'multiple bash scripts can be sourced under errexit',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-multi-source-',
        );
        addTearDown(() => tmp.delete(recursive: true));

        final tabBinary = await compileExample(
          'example/tab.dart',
          '${tmp.path}/tab',
        );
        final argsBinary = await compileExample(
          'example/args_example.dart',
          '${tmp.path}/args_example',
        );

        final tabScriptResult = await Process.run(tabBinary, [
          'complete',
          'bash',
        ]);
        final argsScriptResult = await Process.run(argsBinary, [
          'complete',
          'bash',
        ]);
        expect(tabScriptResult.exitCode, 0);
        expect(argsScriptResult.exitCode, 0);

        final tabScript = await writeScript(
          '${tmp.path}/tab.bash',
          tabScriptResult.stdout as String,
        );
        final argsScript = await writeScript(
          '${tmp.path}/args.bash',
          argsScriptResult.stdout as String,
        );

        final result = await Process.run(
          'bash',
          [
            '-lc',
            'set -e; source "\$TAB_SCRIPT"; source "\$ARGS_SCRIPT"; echo ok',
          ],
          environment: {
            'TAB_SCRIPT': tabScript.path,
            'ARGS_SCRIPT': argsScript.path,
          },
        );

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(result.stdout, contains('ok'));
      },
      skip: !runBash || Platform.isWindows,
    );
  });
}
