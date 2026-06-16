import 'package:coal/src/cli/cli.dart';
import 'package:test/test.dart';

void main() {
  group('coal cli', () {
    test('reports shell support', () async {
      final output = StringBuffer();
      final code = await runCoal(
        <String>['doctor'],
        out: output,
        hasCommand: (command) => command == 'bash',
      );

      expect(code, 0);
      expect(output.toString(), contains('bash: ok'));
      expect(output.toString(), contains('zsh: missing'));
    });

    test('generates coal completion script', () async {
      final output = StringBuffer();
      final code = await runCoal(<String>['complete', 'bash'], out: output);

      expect(code, 0);
      expect(output.toString(), contains('complete -F __coal_complete coal'));
    });

    test('generates dart completion script', () async {
      final output = StringBuffer();
      final code = await runCoal(<String>[
        'dart-complete',
        'bash',
      ], out: output);

      expect(code, 0);
      expect(output.toString(), contains('complete -F __dart_complete dart'));
      expect(output.toString(), contains('coal dart-complete --'));
    });

    test('completes dart commands', () async {
      final output = StringBuffer();
      final code = await runCoal(<String>[
        'dart-complete',
        '--',
        'pu',
      ], out: output);

      expect(code, 0);
      expect(output.toString(), contains('pub\tWork with packages'));
    });

    test('returns usage error for unsupported dart completion shell', () async {
      final errors = StringBuffer();
      final code = await runCoal(
        <String>['dart-complete', 'unknown'],
        out: StringBuffer(),
        err: errors,
      );

      expect(code, 64);
      expect(errors.toString(), contains('Unsupported shell'));
    });
  });
}
