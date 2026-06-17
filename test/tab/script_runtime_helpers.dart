import 'dart:io';

import 'package:test/test.dart';

final class ScriptRuntime {
  ScriptRuntime()
    : requiredShells = (Platform.environment['COAL_REQUIRED_SHELLS'] ?? '')
          .split(',')
          .map((shell) => shell.trim().toLowerCase())
          .where((shell) => shell.isNotEmpty)
          .toSet() {
    availability = {
      'bash': hasCommand('bash'),
      'zsh': hasCommand('zsh'),
      'fish': hasCommand('fish'),
      'pwsh': hasCommand('pwsh'),
    };
  }

  final Set<String> requiredShells;
  late final Map<String, bool> availability;

  bool canRun(String shell) {
    final isAvailable = availability[shell] == true;
    if (requiredShells.isEmpty) return isAvailable;
    return requiredShells.contains(shell) && isAvailable;
  }

  bool get runBash => canRun('bash');
  bool get runZsh => canRun('zsh');
  bool get runFish => canRun('fish');
  bool get runPwsh => canRun('pwsh');
}

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
    final chmodResult = await Process.run('chmod', ['+x', file.path]);
    if (chmodResult.exitCode != 0) {
      throw ProcessException(
        'chmod',
        ['+x', file.path],
        '${chmodResult.stdout}\n${chmodResult.stderr}',
        chmodResult.exitCode,
      );
    }
  }
  return file;
}

Future<String> compileExample(String source, String output) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'exe',
    source,
    '--output',
    output,
  ]);

  expect(
    result.exitCode,
    0,
    reason: 'compile failed: ${result.stdout}\n${result.stderr}',
  );

  return output;
}

String shellQuote(String value) {
  return "'${value.replaceAll("'", r"'\''")}'";
}

String powershellQuote(String value) {
  return "'${value.replaceAll("'", "''")}'";
}
