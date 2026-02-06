import 'dart:async';

import 'package:coal/utils.dart';
import 'package:test/test.dart';

List<String> captureOutput(void Function() fn) {
  final lines = <String>[];
  runZoned(
    fn,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  test('styleText does not print debug output for nested reset codes', () {
    final output = captureOutput(
      () => styleText('\x1b[22mhello', [TextStyle.bold]),
    );

    expect(output, isEmpty);
  });
}
