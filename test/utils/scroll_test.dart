import 'package:coal/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Scroll', () {
    test('scrolls vertically', () {
      expect(scrollUp(), '\x1B[S');
      expect(scrollUp(2), '\x1B[S\x1B[S');
      expect(scrollDown(), '\x1B[T');
      expect(scrollDown(2), '\x1B[T\x1B[T');
    });

    test('scrolls horizontally', () {
      expect(scrollLeft(), '\x1B[ @');
      expect(scrollLeft(2), '\x1B[ @\x1B[ @');
      expect(scrollRight(), '\x1B[ A');
      expect(scrollRight(2), '\x1B[ A\x1B[ A');
    });
  });
}
