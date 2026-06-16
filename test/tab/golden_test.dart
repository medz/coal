import 'dart:async';
import 'dart:io';

import 'package:coal/tab.dart';
import 'package:test/test.dart';

import '_def.dart';

const _updateGoldensFlag = bool.fromEnvironment('update_goldens');
final _updateGoldensEnv = Platform.environment['COAL_UPDATE_GOLDENS'] == 'true';
final _updateGoldens = _updateGoldensFlag || _updateGoldensEnv;

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

String normalizeScript(String script) {
  return script
      .replaceAll('\r\n', '\n')
      .replaceFirst(
        RegExp(r'^# (Date|Data): .+$', multiLine: true),
        '# Date: <generated>',
      );
}

Future<void> expectGolden(String relativePath, String actual) async {
  final normalizedActual = actual.replaceAll('\r\n', '\n');
  final file = File('test/tab/goldens/$relativePath');

  if (_updateGoldens || !await file.exists()) {
    await file.parent.create(recursive: true);
    await file.writeAsString(normalizedActual);
  }

  final normalizedExpected = (await file.readAsString()).replaceAll(
    '\r\n',
    '\n',
  );
  expect(
    normalizedActual,
    normalizedExpected,
    reason:
        'golden mismatch: $relativePath\n'
        're-run with COAL_UPDATE_GOLDENS=true to update snapshots',
  );
}

Tab buildGoldenTab() {
  final tab = Tab();
  tab.option('mode', 'Execution mode', (complete, _) {
    complete('dev', 'Development mode');
    complete('prod', 'Production mode');
  }, alias: 'm');

  tab.command('project', 'Project operations');
  final deploy = tab.command('deploy', 'Deploy service');
  deploy.argument('environment', (complete, _) {
    complete('staging', 'Staging environment');
    complete('production', 'Production environment');
  });

  return tab;
}

String renderCompletionOutput(Tab tab, List<String> input) {
  final lines = captureOutput(() => tab.parse(input));
  return '${lines.join('\n')}\n';
}

void main() {
  group('tab script goldens', () {
    final scripts = <String, String>{
      'bash.golden': normalizeScript(Shell.bash.generate(name, exec)),
      'zsh.golden': normalizeScript(Shell.zsh.generate(name, exec)),
      'fish.golden': normalizeScript(Shell.fish.generate(name, exec)),
      'powershell.golden': normalizeScript(
        Shell.powershell.generate(name, exec),
      ),
    };

    for (final entry in scripts.entries) {
      test('matches ${entry.key}', () async {
        await expectGolden('scripts/${entry.key}', entry.value);
      });
    }
  });

  group('tab completion output goldens', () {
    final scenarios = <String, List<String>>{
      'root-command.golden': <String>['de'],
      'option-value.golden': <String>['--mode', 'd'],
      'positional-value.golden': <String>['deploy', 'st'],
      'no-result.golden': <String>['--unknown'],
    };

    for (final entry in scenarios.entries) {
      test('matches ${entry.key}', () async {
        final tab = buildGoldenTab();
        await expectGolden(
          'outputs/${entry.key}',
          renderCompletionOutput(tab, entry.value),
        );
      });
    }
  });
}
