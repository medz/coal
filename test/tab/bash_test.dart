import 'package:test/test.dart';

import 'script_contract_cases.dart';

void main() {
  group('bash shell completion', () {
    for (final contractCase in scriptContractCasesFor(ContractShell.bash)) {
      test(contractCase.description, () {
        final script = ContractShell.bash.generate(
          contractCase.commandName,
          contractCase.execCommand,
        );
        final expectations = contractCase.expectationsFor(ContractShell.bash);

        for (final fragment in expectations.contains) {
          expect(
            script,
            contains(fragment),
            reason:
                'missing expected bash fragment from ${contractCase.key}: $fragment',
          );
        }
        for (final fragment in expectations.absent) {
          expect(
            script,
            isNot(contains(fragment)),
            reason:
                'unexpected bash fragment from ${contractCase.key}: $fragment',
          );
        }
      });
    }
  });
}
