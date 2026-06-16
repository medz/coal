import 'dart:io';

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

void main() {
  group('tab examples', () {
    test(
      'source tab example generates valid bash completion',
      () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'example/tab.dart',
          'complete',
          'bash',
        ]);

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );

        final tmp = await Directory.systemTemp.createTemp(
          'coal-tab-example-smoke-',
        );
        addTearDown(() => tmp.delete(recursive: true));
        final script = File('${tmp.path}/tab.bash');
        await script.writeAsString(result.stdout as String);

        final check = await Process.run('bash', ['-n', script.path]);

        expect(check.exitCode, 0, reason: check.stderr);
      },
      skip: !hasCommand('bash'),
    );
  });
}
