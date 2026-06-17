import 'dart:async';
import 'dart:io';

import 'package:coal/src/tab/dart_cli.dart';
import 'package:coal/tab.dart';
import 'package:test/test.dart';

List<String> captureOutput(void Function() fn) {
  final lines = <String>[];
  runZoned(
    fn,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  group('dart cli completion', () {
    test('completes root dart commands', () {
      final output = captureOutput(() => dartCliTab().parse(['']));

      expect(output, contains('analyze\tAnalyze Dart code in a directory'));
      expect(output, contains('compile\tCompile Dart to various formats'));
      expect(output, contains('help\tPrint help for a command'));
      expect(output, contains('pub\tWork with packages'));
      expect(
        output,
        contains('run\tRun a Dart program from a file or package'),
      );
      expect(output, contains(':4'));
    });

    test('completes root dart command prefixes', () {
      final output = captureOutput(() => dartCliTab().parse(['pu']));

      expect(output, ['pub\tWork with packages', ':4']);
    });

    test('completes dart compile subcommands', () {
      final output = captureOutput(() => dartCliTab().parse(['compile', '']));

      expect(
        output,
        contains('exe\tCompile Dart to a self-contained executable'),
      );
      expect(output, contains('wasm\tCompile Dart to a WebAssembly module'));
      expect(output, contains(':4'));
    });

    test('completes dart pub subcommands', () {
      final output = captureOutput(() => dartCliTab().parse(['pub', 'g']));

      expect(output, [
        'global\tWork with global packages',
        'get\tGet package dependencies',
        ':4',
      ]);
    });

    test('completes dart help command topics', () {
      final output = captureOutput(() => dartCliTab().parse(['help', 'd']));

      expect(output, [
        'doc\tGenerate API documentation for Dart projects',
        'devtools\tOpen DevTools',
        ':4',
      ]);
    });

    test('completes dart help nested command topics', () {
      final output = captureOutput(
        () => dartCliTab().parse(['help', 'pub', 'g']),
      );

      expect(output, [
        'global\tWork with global packages',
        'get\tGet package dependencies',
        ':4',
      ]);
    });

    test('completes dart create template values', () {
      final output = captureOutput(
        () => dartCliTab().parse(['create', '--template', 'server']),
      );

      expect(output, ['server-shelf\tServer app using package:shelf', ':4']);
    });

    test(
      'allows shell file completion when there are no custom candidates',
      () {
        expect(captureOutput(() => dartCliTab().parse(['run', ''])), [':0']);
        expect(captureOutput(() => dartCliTab().parse(['analyze', ''])), [
          ':0',
        ]);
        expect(captureOutput(() => dartCliTab().parse(['unknown'])), [':0']);
      },
    );

    test('generates setup scripts for the dart command', () {
      final scripts = {
        Shell.bash: (
          dartCliCompletionScript(Shell.bash),
          "requestComp=('coal' 'tab' 'dart' complete --)",
          'complete -o default -F __dart_complete dart',
        ),
        Shell.zsh: (
          dartCliCompletionScript(Shell.zsh),
          "requestComp=('coal' 'tab' 'dart' complete --)",
          'compdef _dart dart',
        ),
        Shell.fish: (
          dartCliCompletionScript(Shell.fish),
          "set -l requestComp 'coal' 'tab' 'dart' complete --",
          'complete -c dart -f -a "(eval __dart_perform_completion)"',
        ),
        Shell.powershell: (
          dartCliCompletionScript(Shell.powershell),
          "\$RequestComp = @('coal', 'tab', 'dart', \"complete\", \"--\")",
          "Register-ArgumentCompleter -CommandName 'dart'",
        ),
      };

      for (final MapEntry(key: shell, value: expectations) in scripts.entries) {
        final (script, request, registration) = expectations;
        expect(
          script,
          contains(request),
          reason: '${shell.name} script uses the wrong backend request',
        );
        expect(
          script,
          contains(registration),
          reason: '${shell.name} script does not register dart',
        );
        expect(script, isNot(contains('tab.dart')));
      }
    });

    test('coal command prints dart cli completion candidates', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'bin/coal.dart',
        'tab',
        'dart',
        'complete',
        '--',
        'pu',
      ]);

      expect(
        result.exitCode,
        0,
        reason: 'coal cli failed: ${result.stdout}\n${result.stderr}',
      );
      expect((result.stdout as String).trim().split('\n'), [
        'pub\tWork with packages',
        ':4',
      ]);
    });

    test(
      'coal command lets file completion handle empty run positions',
      () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'bin/coal.dart',
          'tab',
          'dart',
          'complete',
          '--',
          'run',
          '',
        ]);

        expect(
          result.exitCode,
          0,
          reason: 'coal cli failed: ${result.stdout}\n${result.stderr}',
        );
        expect((result.stdout as String).trim(), ':0');
      },
    );

    test('coal command prints dart setup scripts', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'bin/coal.dart',
        'tab',
        'dart',
        'bash',
      ]);

      expect(
        result.exitCode,
        0,
        reason: 'coal cli failed: ${result.stdout}\n${result.stderr}',
      );
      expect(result.stdout, contains('# bash completion for dart'));
      expect(
        result.stdout,
        contains('complete -o default -F __dart_complete dart'),
      );
      expect(result.stdout, isNot(contains('tab.dart')));
    });
  });
}
