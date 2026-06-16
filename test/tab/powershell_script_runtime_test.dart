@Tags(['script-runtime'])
library;

import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

import 'script_runtime_helpers.dart';

void main() {
  final runtime = ScriptRuntime();
  final runPwsh = runtime.runPwsh;

  group('powershell tab script runtime', () {
    test('powershell script loads without parser errors', () async {
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

      expect(result.exitCode, 0, reason: 'pwsh load failed: ${result.stderr}');
    }, skip: !runPwsh);

    test('powershell script executes completion flow end-to-end', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-pwsh-runtime-',
      );
      addTearDown(() => tmp.delete(recursive: true));

      final backend = await writeScript('${tmp.path}/mock_complete.dart', r'''
void main(List<String> args) {
  if (args.length >= 2 && args[0] == 'complete' && args[1] == '--') {
    const expectedConfig = r'C:\tmp\has space.json';
    if (!args.contains(expectedConfig)) {
      throw StateError('missing quoted config arg: $args');
    }
    print('--name\tName option');
    print(':0');
    return;
  }
  throw StateError('unexpected args: $args');
}
''');
      final exec = [
        powershellQuote(Platform.resolvedExecutable),
        powershellQuote(backend.path),
      ].join(' ');
      final script = await writeScript(
        '${tmp.path}/coaltest.ps1',
        Shell.powershell.generate('coaltest', exec),
      );
      final harness = r'''
. $env:COMPLETION_FILE
$line = "coaltest --config 'C:\tmp\has space.json' --na"
$cursor = $line.Length
[System.Management.Automation.CommandCompletion]::CompleteInput($line, $cursor, $null).CompletionMatches | ForEach-Object { $_.CompletionText }
''';

      final result = await Process.run(
        'pwsh',
        ['-NoProfile', '-NonInteractive', '-Command', harness],
        environment: {'COMPLETION_FILE': script.path},
      );

      expect(
        result.exitCode,
        0,
        reason: 'pwsh completion failed: ${result.stderr}',
      );
      expect(result.stdout, contains('--name'));
    }, skip: !runPwsh);

    test('preserves trailing-space sentinel with legacy native args', () async {
      final tmp = await Directory.systemTemp.createTemp(
        'coal-tab-pwsh-legacy-empty-',
      );
      addTearDown(() => tmp.delete(recursive: true));

      final backend = await writeScript('${tmp.path}/mock_complete.dart', r'''
void main(List<String> args) {
  if (args.length >= 2 && args[0] == 'complete' && args[1] == '--') {
    if (args.length < 3 || args.last != '') {
      throw StateError('missing trailing empty arg: $args');
    }
    print('--next\tNext option');
    print(':0');
    return;
  }
  throw StateError('unexpected args: $args');
}
''');
      final exec = [
        powershellQuote(Platform.resolvedExecutable),
        powershellQuote(backend.path),
      ].join(' ');
      final script = await writeScript(
        '${tmp.path}/coaltest.ps1',
        Shell.powershell.generate('coaltest', exec),
      );
      final harness = r'''
. $env:COMPLETION_FILE
$NativeArgumentPassing = Get-Variable -Name PSNativeCommandArgumentPassing -ErrorAction SilentlyContinue
if ($NativeArgumentPassing) {
  $PSNativeCommandArgumentPassing = 'Legacy'
}
$line = "coaltest "
$cursor = $line.Length
[System.Management.Automation.CommandCompletion]::CompleteInput($line, $cursor, $null).CompletionMatches | ForEach-Object { $_.CompletionText }
''';

      final result = await Process.run(
        'pwsh',
        ['-NoProfile', '-NonInteractive', '-Command', harness],
        environment: {'COMPLETION_FILE': script.path},
      );

      expect(
        result.exitCode,
        0,
        reason: 'pwsh completion failed: ${result.stderr}',
      );
      expect(result.stdout, contains('--next'));
    }, skip: !runPwsh);
  });
}
