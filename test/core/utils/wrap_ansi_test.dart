import 'package:coal/coal.dart';
import 'package:test/test.dart';

final fixture1 =
        'The quick brown ${styleText('fox jumped over ', [TextStyle.red])}the lazy ${styleText('dog and then ran away with the unicorn.', [TextStyle.green])}',
    fixture2 = '12345678\n901234567890',
    fixture3 = '12345678\n901234567890 12345',
    fixture4 = '12345678\n',
    fixture5 = '12345678\n ';

bool hasAnsi(String e) => stripVTControlCharacters(e) != e;

void main() {
  group('Wrap ANSI', () {
    test('wraps string at 20 characters', () {
      final result = wrapAnsi(fixture1, 20);
      expect(
        result,
        'The quick brown \u001B[31mfox\u001B[39m\n\u001B[31mjumped over \u001B[39mthe lazy\n\u001B[32mdog and then ran\u001B[39m\n\u001B[32maway with the\u001B[39m\n\u001B[32municorn.\u001B[39m',
      );
      expect(
        stripVTControlCharacters(
          result,
        ).split('\n').every((e) => e.length <= 20),
        true,
      );
    });

    test('wraps string at 30 characters', () {
      final result = wrapAnsi(fixture1, 30);
      expect(
        result,
        'The quick brown \u001B[31mfox jumped\u001B[39m\n\u001B[31mover \u001B[39mthe lazy \u001B[32mdog and then ran\u001B[39m\n\u001B[32maway with the unicorn.\u001B[39m',
      );
      expect(
        stripVTControlCharacters(
          result,
        ).split('\n').every((e) => e.length <= 30),
        true,
      );
    });

    test('does not break strings longer than "cols" characters', () {
      final result = wrapAnsi(fixture1, 5, hard: false);
      expect(
        result,
        'The\nquick\nbrown\n\u001B[31mfox\u001B[39m\n\u001B[31mjumped\u001B[39m\n\u001B[31mover\u001B[39m\n\u001B[31m\u001B[39mthe\nlazy\n\u001B[32mdog\u001B[39m\n\u001B[32mand\u001B[39m\n\u001B[32mthen\u001B[39m\n\u001B[32mran\u001B[39m\n\u001B[32maway\u001B[39m\n\u001B[32mwith\u001B[39m\n\u001B[32mthe\u001B[39m\n\u001B[32municorn.\u001B[39m',
      );
      expect(
        stripVTControlCharacters(
          result,
        ).split('\n').any((line) => line.length > 5),
        true,
      );
    });

    test('handles colored string that wraps on to multiple lines', () {
      final result = wrapAnsi(
        '${styleText('hello world', [TextStyle.green])} hey!',
        5,
        hard: false,
      );
      final lines = result.split('\n');
      expect(lines.length, equals(3));

      expect(hasAnsi(lines[0]), true);
      expect(hasAnsi(lines[1]), true);
      expect(hasAnsi(lines[2]), false);
    });

    test('does not prepend newline if first string is greater than "cols"', () {
      final result = wrapAnsi(
        '${styleText('hello', [TextStyle.green])}-world',
        5,
        hard: false,
      );
      expect(result.split('\n').length, 1);
    });

    test('breaks strings longer than "cols" characters', () {
      final result = wrapAnsi(fixture1, 5, hard: true);

      expect(
        result,
        'The\nquick\nbrown\n\u001B[31mfox j\u001B[39m\n\u001B[31mumped\u001B[39m\n\u001B[31mover\u001B[39m\n\u001B[31m\u001B[39mthe\nlazy\n\u001B[32mdog\u001B[39m\n\u001B[32mand\u001B[39m\n\u001B[32mthen\u001B[39m\n\u001B[32mran\u001B[39m\n\u001B[32maway\u001B[39m\n\u001B[32mwith\u001B[39m\n\u001B[32mthe\u001B[39m\n\u001B[32munico\u001B[39m\n\u001B[32mrn.\u001B[39m',
      );
      expect(
        stripVTControlCharacters(
          result,
        ).split('\n').every((line) => line.length <= 5),
        true,
      );
    });

    test('removes last row if it contained only ansi escape codes', () {
      final result = wrapAnsi(
        styleText('helloworld', [TextStyle.green]),
        2,
        hard: true,
      );
      expect(
        stripVTControlCharacters(
          result,
        ).split('\n').every((x) => x.length == 2),
        isTrue,
      );
    });

    test('does not prepend newline if first word is split', () {
      final result = wrapAnsi(
        '${styleText('hello', [TextStyle.green])}world',
        5,
        hard: true,
      );
      expect(result.split('\n').length, equals(2));
    });

    test('takes into account line returns inside input', () {
      expect(wrapAnsi(fixture2, 10, hard: true), '12345678\n9012345678\n90');
    });

    test('word wrapping', () {
      expect(wrapAnsi(fixture3, 15), '12345678\n901234567890\n12345');
    });

    test('no word-wrapping', () {
      final result = wrapAnsi(fixture3, 15, wordWrap: false);
      expect(result, '12345678\n901234567890 12\n345');

      final result2 = wrapAnsi(fixture3, 5, wordWrap: false);
      expect(result2, '12345\n678\n90123\n45678\n90 12\n345');

      final rsult3 = wrapAnsi(fixture5, 5, wordWrap: false);
      expect(rsult3, '12345\n678\n');

      final result4 = wrapAnsi(fixture1, 5, wordWrap: false);
      expect(
        result4,
        'The q\nuick\nbrown\n\u001B[31mfox j\u001B[39m\n\u001B[31mumped\u001B[39m\n\u001B[31mover\u001B[39m\n\u001B[31m\u001B[39mthe l\nazy \u001B[32md\u001B[39m\n\u001B[32mog an\u001B[39m\n\u001B[32md the\u001B[39m\n\u001B[32mn ran\u001B[39m\n\u001B[32maway\u001B[39m\n\u001B[32mwith\u001B[39m\n\u001B[32mthe u\u001B[39m\n\u001B[32mnicor\u001B[39m\n\u001B[32mn.\u001B[39m',
      );
    });

    test('supports fullwidth characters', () {
      expect(wrapAnsi('你好呀', 4, hard: true), '你好\n呀');
      expect(wrapAnsi('안녕하세', 4, hard: true), '안녕\n하세');
    });

    test('supports unicode surrogate pairs', () {
      expect(wrapAnsi('a\uD83C\uDE00bc', 2, hard: true), 'a\n\uD83C\uDE00\nbc');
      expect(
        wrapAnsi('a\uD83C\uDE00bc\uD83C\uDE00d\uD83C\uDE00', 2, hard: true),
        'a\n\uD83C\uDE00\nbc\n\uD83C\uDE00\nd\n\uD83C\uDE00',
      );
    });
  });
}
