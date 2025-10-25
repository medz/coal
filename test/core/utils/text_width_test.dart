import 'package:coal/coal.dart';
import 'package:test/test.dart';

int getWidget(
  String input, {
  /*------------- Special Width ----------------*/
  int controlWidth = 0,
  int tabWidth = 8,
  /*------------- Other Width ----------------*/
  int emojiWidth = 2,
  int regularWidth = 1,
  int? wideWidth,
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
  int? ellipsisWidth,
  /*------------- Special Width ----------------*/
  int controlWidth = 0,
  int tabWidth = 8,
  /*------------- Other Width ----------------*/
  int emojiWidth = 2,
  int regularWidth = 1,
  int? wideWidth,
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
        final result = getTextTruncatedWidth('\x1b[31mhello', ellipsis: '...');
        expect(result.width, equals(5));
        expect(result.index, equals(10));
        expect(result.truncated, equals(false));
        expect(result.ellipsed, equals(false));
      });

      test('supports strings that do need to be truncated', () {
        final result = getTextTruncatedWidth(
          '\x1b[31mhello',
          limit: 3,
          ellipsis: '...',
        );
        print(result);
        expect(result.width, equals(2));
        expect(result.index, equals(7));
        expect(result.truncated, equals(true));
        expect(result.ellipsed, equals(true));
      });
    });
  });
}
