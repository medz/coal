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

    test('properly wraps whitespace with no trimming', () {
      expect(wrapAnsi('   ', 2, trim: false), '  \n ');
      expect(wrapAnsi('   ', 2, trim: false, hard: true), '  \n ');
    });

    test(
      'trims leading and trailing whitespace only on actual wrapped lines and only with trimming',
      () {
        expect(wrapAnsi('   foo   bar   ', 3), 'foo\nbar');
        expect(wrapAnsi('   foo   bar   ', 6), 'foo\nbar');
        expect(wrapAnsi('   foo   bar   ', 42), 'foo   bar');
        expect(wrapAnsi('   foo   bar   ', 42, trim: false), '   foo   bar   ');
      },
    );

    test(
      'trims leading and trailing whitespace inside a color block only on actual wrapped lines and only with trimming',
      () {
        expect(
          wrapAnsi(styleText('   foo   bar   ', [TextStyle.blue]), 6),
          '${styleText('foo', [TextStyle.blue])}\n${styleText('bar', [TextStyle.blue])}',
        );
        expect(
          wrapAnsi(styleText('   foo   bar   ', [TextStyle.blue]), 42),
          styleText('foo   bar', [TextStyle.blue]),
        );
        expect(
          wrapAnsi(
            styleText('   foo   bar   ', [TextStyle.blue]),
            42,
            trim: false,
          ),
          styleText('   foo   bar   ', [TextStyle.blue]),
        );
      },
    );

    test('properly wraps whitespace between words with no trimming', () {
      expect(wrapAnsi('foo bar', 3), 'foo\nbar');
      expect(wrapAnsi('foo bar', 3, hard: true), 'foo\nbar');
      expect(wrapAnsi('foo bar', 3, trim: false), 'foo\n \nbar');
      expect(wrapAnsi('foo bar', 3, trim: false, hard: true), 'foo\n \nbar');
    });

    test('does not multiplicate leading spaces with no trimming', () {
      expect(wrapAnsi(' a ', 10, trim: false), ' a ');
      expect(wrapAnsi('   a ', 10, trim: false), '   a ');
    });

    test(
      'does not remove spaces in line with ansi escapes when no trimming',
      () {
        expect(
          wrapAnsi(
            styleText(' ${styleText('OK', [TextStyle.black])} ', [
              TextStyle.bgGreen,
            ]),
            100,
            trim: false,
          ),
          styleText(' ${styleText('OK', [TextStyle.black])} ', [
            TextStyle.bgGreen,
          ]),
        );
        expect(
          wrapAnsi(
            styleText('  ${styleText('OK', [TextStyle.black])} ', [
              TextStyle.bgGreen,
            ]),
            100,
            trim: false,
          ),
          styleText('  ${styleText('OK', [TextStyle.black])} ', [
            TextStyle.bgGreen,
          ]),
        );
        expect(
          wrapAnsi(
            styleText(' hello ', [TextStyle.bgGreen]),
            10,
            hard: true,
            trim: false,
          ),
          styleText(' hello ', [TextStyle.bgGreen]),
        );
      },
    );

    test('wraps hyperlinks, preserving clickability in supporting terminals', () {
      final result1 = wrapAnsi(
        'Check out \u001B]8;;https://www.example.com\u0007my website\u001B]8;;\u0007, it is \u001B]8;;https://www.example.com\u0007supercalifragilisticexpialidocious\u001B]8;;\u0007.',
        16,
        hard: true,
      );
      expect(
        result1,
        'Check out \u001B]8;;https://www.example.com\u0007my\u001B]8;;\u0007\n\u001B]8;;https://www.example.com\u0007website\u001B]8;;\u0007, it is\n\u001B]8;;https://www.example.com\u0007supercalifragili\u001B]8;;\u0007\n\u001B]8;;https://www.example.com\u0007sticexpialidocio\u001B]8;;\u0007\n\u001B]8;;https://www.example.com\u0007us\u001B]8;;\u0007.',
      );

      final result2 = wrapAnsi(
        'Check out \u001B]8;;https://www.example.com\u0007my \uD83C\uDE00 ${styleText('website', [TextStyle.bgGreen])}\u001B]8;;\u0007, it ${styleText('is \u001B]8;;https://www.example.com\u0007super\uD83C\uDE00califragilisticexpialidocious\u001B]8;;\u0007', [TextStyle.bgRed])}.',
        16,
        hard: true,
      );
      expect(
        result2,
        'Check out \u001B]8;;https://www.example.com\u0007my 🈀\u001B]8;;\u0007\n\u001B]8;;https://www.example.com\u0007\u001B[42mwebsite\u001B[49m\u001B]8;;\u0007, it \u001B[41mis\u001B[49m\n\u001B[41m\u001B]8;;https://www.example.com\u0007super🈀califragi\u001B]8;;\u0007\u001B[49m\n\u001B[41m\u001B]8;;https://www.example.com\u0007listicexpialidoc\u001B]8;;\u0007\u001B[49m\n\u001B[41m\u001B]8;;https://www.example.com\u0007ious\u001B]8;;\u0007\u001B[49m.',
      );
    });
  });

  test('covers non-SGR/non-hyperlink ansi escapes', () {
    expect(wrapAnsi('Hello, \u001B[1D World!', 8), 'Hello,\u001B[1D\nWorld!');
    expect(
      wrapAnsi('Hello, \u001B[1D World!', 8, trim: false),
      'Hello, \u001B[1D \nWorld!',
    );
  });

  test('normalizes newlines', () {
    expect(
      wrapAnsi('foobar\r\nfoobar\r\nfoobar\nfoobar', 3, hard: true),
      'foo\nbar\nfoo\nbar\nfoo\nbar\nfoo\nbar',
    );
    expect(
      wrapAnsi('foo bar\r\nfoo bar\r\nfoo bar\nfoo bar', 3),
      'foo\nbar\nfoo\nbar\nfoo\nbar\nfoo\nbar',
    );
  });
}
