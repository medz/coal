import 'package:coal/utils.dart';
import 'package:test/test.dart';

void main() {
  group('ANSI control sequences', () {
    test('cursor helpers emit CSI sequences', () {
      expect(cursorLeft, '\x1b[G');
      expect(cursorUp(), '\x1b[1A');
      expect(cursorDown(2), '\x1b[2B');
      expect(cursorForward(3), '\x1b[3C');
      expect(cursorBackward(4), '\x1b[4D');
      expect(cursorTo(0), '\x1b[1G');
      expect(cursorTo(2, 3), '\x1b[4;3H');
      expect(cursorSave, '\x1b7');
      expect(cursorRestore, '\x1b8');
    });

    test('erase helpers match their public names', () {
      expect(eraseScreen, '\x1b[2J');
      expect(eraseLine, '\x1b[2K');
      expect(eraseLineStart, '\x1b[1K');
      expect(eraseLineEnd, '\x1b[K');
      expect(eraseUp(), '\x1b[1J');
      expect(eraseDown(), '\x1b[J');
    });

    test('scroll helpers emit vertical and horizontal scroll sequences', () {
      expect(scrollUp(), '\x1b[1S');
      expect(scrollDown(2), '\x1b[2T');
      expect(scrollLeft(3), '\x1b[3 @');
      expect(scrollRight(4), '\x1b[4 A');
    });

    test('scroll helpers treat non-positive counts as no-ops', () {
      expect(scrollUp(0), isEmpty);
      expect(scrollUp(-1), isEmpty);
      expect(scrollDown(0), isEmpty);
      expect(scrollDown(-1), isEmpty);
      expect(scrollLeft(0), isEmpty);
      expect(scrollLeft(-1), isEmpty);
      expect(scrollRight(0), isEmpty);
      expect(scrollRight(-1), isEmpty);
    });

    test('scroll helpers are zero-width VT control sequences', () {
      final input =
          '${scrollUp()}${scrollDown(2)}${scrollLeft(3)}${scrollRight(4)}abc';

      expect(stripVTControlCharacters(input), 'abc');
      expect(getTextWidth(input), 3);
    });

    test('cursor save and restore are zero-width VT control sequences', () {
      final input =
          '$cursorSave'
          'abc'
          '$cursorRestore';

      expect(stripVTControlCharacters(input), 'abc');
      expect(getTextWidth(input), 3);
    });
  });
}
