import 'package:test/test.dart';

import 'script_contract_cases.dart';

void main() {
  group('powershell completion', () {
    for (final contractCase in scriptContractCasesFor(
      ContractShell.powershell,
    )) {
      test(contractCase.description, () {
        final script = ContractShell.powershell.generate(
          contractCase.commandName,
          contractCase.execCommand,
        );
        final expectations = contractCase.expectationsFor(
          ContractShell.powershell,
        );

        for (final fragment in expectations.contains) {
          expect(
            script,
            contains(fragment),
            reason:
                'missing expected powershell fragment from ${contractCase.key}: $fragment',
          );
        }
      });
    }
  });
}
