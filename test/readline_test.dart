import 'dart:convert';
import 'dart:io';

import 'package:coal/readline.dart';
import 'package:test/test.dart';

void main() {
  group('readline', () {
    test('stdio shortcut uses process stdio defaults', () {
      final readline = Readline.stdio();
      expect(readline.encoding, systemEncoding);
    });

    test('stdio shortcut allows overriding encoding', () {
      final readline = Readline.stdio(encoding: utf8);
      expect(readline.encoding, utf8);
    });

    test('prints prompt and trims input by default', () {
      final writes = <Object?>[];
      final readline = Readline(
        writer: writes.add,
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) {
          expect(encoding, utf8);
          expect(retainNewlines, isFalse);
          return '  value  ';
        },
        encoding: utf8,
      );

      final value = readline.read(prompt: 'name: ');

      expect(value, 'value');
      expect(writes, <Object?>['name: ']);
    });

    test('can keep surrounding spaces when trim is disabled', () {
      final readline = Readline(
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) =>
            '  value  ',
      );

      final value = readline.read(trim: false);

      expect(value, '  value  ');
    });

    test('returns null when stdin is closed', () {
      final readline = Readline(
        writer: (_) {},
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) =>
            null,
      );

      final value = readline.read(prompt: '> ');

      expect(value, isNull);
    });

    test('readRequired retries until non-empty input is provided', () {
      final writes = <Object?>[];
      final queue = <String?>['', '  ', 'coal'];
      final readline = Readline(
        writer: writes.add,
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) {
          return queue.removeAt(0);
        },
      );

      final value = readline.readRequired(
        prompt: 'first: ',
        retryPrompt: 'again: ',
      );

      expect(value, 'coal');
      expect(writes, <Object?>['first: ', 'again: ', 'again: ']);
    });

    test('readRequired throws when stdin closes before a valid value', () {
      final readline = Readline(
        writer: (_) {},
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) =>
            null,
      );

      expect(
        () => readline.readRequired(prompt: 'value: '),
        throwsA(isA<StateError>()),
      );
    });

    test('readRequired can allow empty values', () {
      final readline = Readline(
        reader: ({Encoding encoding = utf8, bool retainNewlines = false}) => '',
      );

      final value = readline.readRequired(allowEmpty: true);

      expect(value, '');
    });
  });
}
