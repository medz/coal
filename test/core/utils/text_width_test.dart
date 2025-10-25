import 'package:coal/coal.dart';
import 'package:oxy/oxy.dart';
import 'package:test/test.dart';

num getWidth(
  String input, {
  /*------------- Special Width ----------------*/
  num controlWidth = 0,
  num tabWidth = 8,
  /*------------- Other Width ----------------*/
  num emojiWidth = 2,
  num regularWidth = 1,
  num? wideWidth,
}) {
  final result = getTextTruncatedWidth(
    input,
    controlWidth: controlWidth,
    tabWidth: tabWidth,
    emojiWidth: emojiWidth,
    regularWidth: regularWidth,
    wideWidth: wideWidth,
  );

  return result.width;
}

String getTruncated(
  String input, {
  /*------------- Truncation ----------------*/
  double limit = double.infinity,
  String ellipsis = '',
  num? ellipsisWidth,
  /*------------- Special Width ----------------*/
  num controlWidth = 0,
  num tabWidth = 8,
  /*------------- Other Width ----------------*/
  num emojiWidth = 2,
  num regularWidth = 1,
  num? wideWidth,
}) {
  final result = getTextTruncatedWidth(
    input,
    limit: limit,
    ellipsis: ellipsis,
    ellipsisWidth: ellipsisWidth,
    controlWidth: controlWidth,
    tabWidth: tabWidth,
    emojiWidth: emojiWidth,
    regularWidth: regularWidth,
    wideWidth: wideWidth,
  );

  return '${input.substring(0, result.index)}${result.ellipsed ? ellipsis : ''}';
}

void main() {
  group('Text Width', () {
    group('calculating the raw result', () {
      test('supports strings that do not need to be truncated', () {
        final result = getTextTruncatedWidth('\x1b[31mhello', ellipsis: '.');
        expect(result.width, equals(5));
        expect(result.index, equals(10));
        expect(result.truncated, equals(false));
        expect(result.ellipsed, equals(false));
      });

      test('supports strings that do need to be truncated', () {
        final result = getTextTruncatedWidth(
          '\x1b[31mhello',
          limit: 3,
          ellipsis: '.',
        );
        expect(result.width, equals(2));
        expect(result.index, equals(7));
        expect(result.truncated, equals(true));
        expect(result.ellipsed, equals(true));
      });
    });

    group('calculating the width of a string', () {
      test('supports basic cases', () {
        expect(getWidth('hello'), 5);
        expect(getWidth('\x1b[31mhello'), 5);

        expect(getWidth('abcde'), 5);
        expect(getWidth('古池や'), 6);
        expect(getWidth('あいうabc'), 9);
        expect(getWidth('あいう★'), 7);
        expect(getWidth('±'), 1);
        expect(getWidth('ノード.js'), 9);
        expect(getWidth('你好'), 4);
        expect(getWidth('안녕하세요'), 10);
        expect(getWidth('A\uD83D\uDE00BC'), 5);
        expect(getWidth('\u001B[31m\u001B[39m'), 0);
        expect(getWidth('\u{231A}'), 2);
        expect(getWidth('\u{2194}\u{FE0F}'), 2);
        expect(getWidth('\u{1F469}'), 2);
        expect(getWidth('\u{1F469}\u{1F3FF}'), 2);
        expect(getWidth('\u{845B}\u{E0100}'), 2);
        expect(getWidth('ปฏัก'), 3);
        expect(getWidth('_\u0E34'), 1);
      });

      test('supports control characters', () {
        expect(getWidth(String.fromCharCode(0)), 0);
        expect(getWidth(String.fromCharCode(31)), 0);
        expect(getWidth(String.fromCharCode(127)), 0);
        expect(getWidth(String.fromCharCode(134)), 0);
        expect(getWidth(String.fromCharCode(159)), 0);
        expect(getWidth('\u001B'), 0);
      });

      test('supports tab characters', () {
        expect(getWidth('\t'), 8);
        expect(getWidth('\t\t\t'), 24);
        expect(getWidth('\x00\t\x00\t\x00\t\x00'), 24);
      });

      test('supports combining characters', () {
        expect(getWidth('x\u0300'), 1);
      });

      test('supports emoji characters', () {
        expect(getWidth('👶'), 2);
        expect(getWidth('👶🏽'), 2);
        expect(getWidth('👩‍👩‍👦‍👦'), 2);
        expect(getWidth('👨‍❤️‍💋‍👨'), 2);
        expect(getWidth('🏴‍☠️'), 2);
        expect(getWidth('🏴󠁧󠁢󠁷󠁬󠁳󠁿'), 2);
        expect(getWidth('🇸🇪'), 2);
        expect(getWidth('🇺🇳'), 2);

        expect(getWidth('👶' * 2), 4);
        expect(getWidth('👶🏽' * 2), 4);
        expect(getWidth('👩‍👩‍👦‍👦' * 2), 4);
        expect(getWidth('👨‍❤️‍💋‍👨' * 2), 4);
        expect(getWidth('🏴‍☠️' * 2), 4);
        expect(getWidth('🏴󠁧󠁢󠁷󠁬󠁳󠁿' * 2), 4);
        expect(getWidth('🇸🇪' * 2), 4);
        expect(getWidth('🇺🇳' * 2), 4);
      });

      test('supports all basic emojis', () async {
        final res = await oxy.get(
          'https://raw.githubusercontent.com/muan/unicode-emoji-json/refs/heads/main/data-by-emoji.json',
        );
        final data = await res.json();
        for (final String emoji in Map.from(data).keys) {
          expect(getWidth(emoji), 2);
        }
      });

      test('supports unicode characters', () {
        expect(getWidth('…'), 1);
        expect(getWidth('\u2770'), 1);
        expect(getWidth('\u2771'), 1);
        expect(getWidth('\u21a9'), 1);
        expect(getWidth('\u2193'), 1);
        expect(getWidth('\u21F5'), 1);
        expect(getWidth('\u2937'), 1);
        expect(getWidth('\u27A4'), 1);
        expect(getWidth('\u2190'), 1);
        expect(getWidth('\u21d0'), 1);
        expect(getWidth('\u2194'), 1);
        expect(getWidth('\u21d4'), 1);
        expect(getWidth('\u21ce'), 1);
        expect(getWidth('\u27f7'), 1);
        expect(getWidth('\u2192'), 1);
        expect(getWidth('\u21d2'), 1);
        expect(getWidth('\u21e8'), 1);
        expect(getWidth('\u2191'), 1);
        expect(getWidth('\u21C5'), 1);
        expect(getWidth('\u2197'), 1);
        expect(getWidth('\u21cb'), 1);
        expect(getWidth('\u21cc'), 1);
        expect(getWidth('\u21c6'), 1);
        expect(getWidth('\u21c4'), 1);
        expect(getWidth('\u2217'), 1);
        expect(getWidth('✔'), 1);
        expect(getWidth('\u2014'), 1);
        expect(getWidth('\u2022'), 1);
        expect(getWidth('\u2026'), 1);
        expect(getWidth('\u2013'), 1);
        expect(getWidth('\u2709'), 1);
        expect(getWidth('\u2261'), 1);
        expect(getWidth('\u2691'), 1);
        expect(getWidth('\u2690'), 1);
        expect(getWidth('\u22EF'), 1);
        expect(getWidth('\u226A'), 1);
        expect(getWidth('\u226B'), 1);
        expect(getWidth('\u270E'), 1);
        expect(getWidth('\u00a0'), 1);
        expect(getWidth('\u2009'), 1);
        expect(getWidth('\u200A'), 1);
        expect(getWidth('\u274F'), 1);
        expect(getWidth('\u2750'), 1);
        expect(getWidth('\u26a0'), 1);
        expect(getWidth('\u200b'), 1);
      });

      test('supports japanese half-width characters', () {
        expect(getWidth('ﾊﾞ'), 2);
        expect(getWidth('ﾊﾟ'), 2);
      });

      test('supports hyperlinks', () {
        expect(
          getWidth('\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007'),
          5,
        );
        expect(
          getWidth(
            'twelve chars\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007twelve chars',
          ),
          24 + 5,
        );
        expect(
          getWidth(
            '\u001B]8;;https://github.com\u001B\u005CClick\u001B]8;;\u001B\u005C',
          ),
          5,
        );
      });

      test('supports surrogate pairs', () {
        expect(getWidth('a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d'), 10);
      });
    });

    group('truncating a string', () {
      test('supports latin characters', () {
        expect(getTruncated('hello', limit: 10, ellipsis: '…'), 'hello');
        expect(getTruncated('hello', limit: 5, ellipsis: '…'), 'hello');
        expect(getTruncated('hello', limit: 4, ellipsis: '…'), 'hel…');
        expect(getTruncated('hello', limit: 3, ellipsis: '…'), 'he…');
        expect(getTruncated('hello', limit: 2, ellipsis: '…'), 'h…');
        expect(getTruncated('hello', limit: 1, ellipsis: '…'), '…');
        expect(getTruncated('hello', limit: 0, ellipsis: '…'), '');

        expect(getTruncated('hello', limit: 10, ellipsis: '..'), 'hello');
        expect(getTruncated('hello', limit: 5, ellipsis: '..'), 'hello');
        expect(getTruncated('hello', limit: 4, ellipsis: '..'), 'he..');
        expect(getTruncated('hello', limit: 3, ellipsis: '..'), 'h..');
        expect(getTruncated('hello', limit: 2, ellipsis: '..'), '..');
        expect(getTruncated('hello', limit: 1, ellipsis: '..'), '');
        expect(getTruncated('hello', limit: 0, ellipsis: '..'), '');
      });

      test('supports ansi characters', () {
        expect(
          getTruncated('\x1b[31mhello', limit: 10, ellipsis: '…'),
          '\x1b[31mhello',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 5, ellipsis: '…'),
          '\x1b[31mhello',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 4, ellipsis: '…'),
          '\x1b[31mhel…',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 3, ellipsis: '…'),
          '\x1b[31mhe…',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 2, ellipsis: '…'),
          '\x1b[31mh…',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 1, ellipsis: '…'),
          '\x1b[31m…',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 0, ellipsis: '…'),
          '\x1b[31m',
        );

        expect(
          getTruncated('\x1b[31mhello', limit: 10, ellipsis: '..'),
          '\x1b[31mhello',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 5, ellipsis: '..'),
          '\x1b[31mhello',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 4, ellipsis: '..'),
          '\x1b[31mhe..',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 3, ellipsis: '..'),
          '\x1b[31mh..',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 2, ellipsis: '..'),
          '\x1b[31m..',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 1, ellipsis: '..'),
          '\x1b[31m',
        );
        expect(
          getTruncated('\x1b[31mhello', limit: 0, ellipsis: '..'),
          '\x1b[31m',
        );
      });

      test('supports control characters', () {
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 10, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 4, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 3, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 2, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 1, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated('\x00\x01\x02\x03', limit: 0, ellipsis: '…'),
          '\x00\x01\x02\x03',
        );

        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 10,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 4,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '\x00\x01\x02\x03',
        );
        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 3,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '\x00\x01…',
        );
        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 2,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '\x00…',
        );
        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 1,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '…',
        );
        expect(
          getTruncated(
            '\x00\x01\x02\x03',
            limit: 0,
            ellipsis: '…',
            controlWidth: 1,
          ),
          '',
        );
      });

      test('supports CJK characters', () {
        expect(getTruncated('古池や', limit: 10, ellipsis: '…'), '古池や');
        expect(getTruncated('古池や', limit: 6, ellipsis: '…'), '古池や');
        expect(getTruncated('古池や', limit: 5, ellipsis: '…'), '古池…');
        expect(getTruncated('古池や', limit: 4, ellipsis: '…'), '古…');
        expect(getTruncated('古池や', limit: 3, ellipsis: '…'), '古…');
        expect(getTruncated('古池や', limit: 2, ellipsis: '…'), '…');
        expect(getTruncated('古池や', limit: 1, ellipsis: '…'), '…');
        expect(getTruncated('古池や', limit: 0, ellipsis: '…'), '');
      });

      test('supports emoji characters', () {
        expect(getTruncated('👶👶🏽', limit: 10, ellipsis: '…'), '👶👶🏽');
        expect(getTruncated('👶👶🏽', limit: 4, ellipsis: '…'), '👶👶🏽');
        expect(getTruncated('👶👶🏽', limit: 3, ellipsis: '…'), '👶…');
        expect(getTruncated('👶👶🏽', limit: 2, ellipsis: '…'), '…');
        expect(getTruncated('👶👶🏽', limit: 1, ellipsis: '…'), '…');
        expect(getTruncated('👶👶🏽', limit: 0, ellipsis: '…'), '');

        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 10, ellipsis: '…'),
          '👩‍👩‍👦‍👦👨‍❤️‍💋‍👨',
        );
        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 4, ellipsis: '…'),
          '👩‍👩‍👦‍👦👨‍❤️‍💋‍👨',
        );
        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 3, ellipsis: '…'),
          '👩‍👩‍👦‍👦…',
        );
        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 2, ellipsis: '…'),
          '…',
        );
        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 1, ellipsis: '…'),
          '…',
        );
        expect(
          getTruncated('👩‍👩‍👦‍👦👨‍❤️‍💋‍👨', limit: 0, ellipsis: '…'),
          '',
        );
      });

      test('supports hyperlinks', () {
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 5,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
        );
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 4,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007Cli…',
        );
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 3,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007Cl…',
        );
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 2,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007C…',
        );
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 1,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007…',
        );
        expect(
          getTruncated(
            '\u001B]8;;https://github.com\u0007Click\u001B]8;;\u0007',
            limit: 0,
            ellipsis: '…',
          ),
          '\u001B]8;;https://github.com\u0007',
        );
      });

      test('supports surrogate pairs', () {
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 10,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 9,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b\uD83C\uDE00c…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 8,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b\uD83C\uDE00c…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 7,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b\uD83C\uDE00…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 6,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 5,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00b…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 4,
            ellipsis: '…',
          ),
          'a\uD83C\uDE00…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 3,
            ellipsis: '…',
          ),
          'a…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 2,
            ellipsis: '…',
          ),
          'a…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 1,
            ellipsis: '…',
          ),
          '…',
        );
        expect(
          getTruncated(
            'a\uD83C\uDE00b\uD83C\uDE00c\uD83C\uDE00d',
            limit: 0,
            ellipsis: '…',
          ),
          '',
        );
      });
    });
  });

  test('Fast Text Width', () {
    expect(getTextWidth('hello'), 5);
    expect(getTextWidth('\x1b[31mhello'), 5);
    expect(getTextWidth('👨‍👩‍👧‍👦'), 2);
    expect(getTextWidth('hello👨‍👩‍👧‍👦'), 7);
    expect(getTextWidth('👶👶🏽', emojiWidth: 1.5), 3);
  });
}
