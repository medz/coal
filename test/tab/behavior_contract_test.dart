import 'dart:async';

import 'package:test/test.dart';

import 'behavior_contract_cases.dart';

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

void main() {
  group('tab parse behavior contract', () {
    for (final contractCase in parseContractCases) {
      test(contractCase.description, () {
        final tab = buildParseContractTab();
        final output = captureOutput(() => tab.parse(contractCase.input));

        expect(
          output,
          isNotEmpty,
          reason: 'case ${contractCase.key} produced no parse output',
        );

        final directive = output.last;
        final completions = output.sublist(0, output.length - 1);
        final expectations = contractCase.expectations;

        expect(
          directive,
          expectations.directive,
          reason: 'unexpected directive for case ${contractCase.key}',
        );

        if (expectations.exactCompletions != null) {
          expect(
            completions,
            expectations.exactCompletions,
            reason: 'unexpected completion set for case ${contractCase.key}',
          );
        }

        for (final line in expectations.containsCompletions) {
          expect(
            completions,
            contains(line),
            reason:
                'missing expected completion in case ${contractCase.key}: $line',
          );
        }

        for (final line in expectations.notContainsCompletions) {
          expect(
            completions,
            isNot(contains(line)),
            reason: 'unexpected completion in case ${contractCase.key}: $line',
          );
        }

        if (expectations.completionCount != null) {
          expect(
            completions.length,
            expectations.completionCount,
            reason: 'unexpected completion count for case ${contractCase.key}',
          );
        }
      });
    }
  });
}
