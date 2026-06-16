import 'package:test/test.dart';

import 'script_contract_cases.dart';

void main() {
  group('zsh shell completion', () {
    for (final contractCase in scriptContractCasesFor(ContractShell.zsh)) {
      test(contractCase.description, () {
        final script = ContractShell.zsh.generate(
          contractCase.commandName,
          contractCase.execCommand,
        );
        final expectations = contractCase.expectationsFor(ContractShell.zsh);

        for (final fragment in expectations.contains) {
          expect(
            script,
            contains(fragment),
            reason:
                'missing expected zsh fragment from ${contractCase.key}: $fragment',
          );
        }
        for (final fragment in expectations.absent) {
          expect(
            script,
            isNot(contains(fragment)),
            reason:
                'unexpected zsh fragment from ${contractCase.key}: $fragment',
          );
        }
      });
    }
  });
}
