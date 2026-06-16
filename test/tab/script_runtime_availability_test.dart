@Tags(['script-runtime'])
library;

import 'package:test/test.dart';

import 'script_runtime_helpers.dart';

void main() {
  final runtime = ScriptRuntime();

  test('required shells are available when configured', () {
    for (final shell in runtime.requiredShells) {
      expect(
        runtime.availability[shell] == true,
        isTrue,
        reason: '$shell is required by COAL_REQUIRED_SHELLS but not available',
      );
    }
  });
}
