import 'package:test/test.dart';

import 'script_contract_cases.dart';

void main() {
  group('fish shell completion', () {
    for (final contractCase in scriptContractCasesFor(ContractShell.fish)) {
      test(contractCase.description, () {
        final script = ContractShell.fish.generate(
          contractCase.commandName,
          contractCase.execCommand,
        );
        final expectations = contractCase.expectationsFor(ContractShell.fish);

        for (final fragment in expectations.contains) {
          expect(
            script,
            contains(fragment),
            reason:
                'missing expected fish fragment from ${contractCase.key}: $fragment',
          );
        }
        for (final fragment in expectations.absent) {
          expect(
            script,
            isNot(contains(fragment)),
            reason:
                'unexpected fish fragment from ${contractCase.key}: $fragment',
          );
        }
      });
    }
  });
}
