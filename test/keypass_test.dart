import 'package:coal/keypass.dart';
import 'package:test/test.dart';

void main() {
  group('key event decoding', () {
    test('decodes printable and control keys', () {
      expect(KeyEvent.fromSequence('a').binding, 'a');
      expect(KeyEvent.fromSequence('A').binding, 'shift+a');
      expect(KeyEvent.fromSequence('+').binding, 'plus');
      expect(KeyEvent.fromSequence(' ').binding, 'space');
      expect(KeyEvent.fromSequence('\x03').binding, 'ctrl+c');
    });

    test('decodes named control keys', () {
      expect(KeyEvent.fromSequence('\t').binding, 'tab');
      expect(KeyEvent.fromSequence('\r').binding, 'enter');
      expect(KeyEvent.fromSequence('\n').binding, 'enter');
      expect(KeyEvent.fromSequence('\x1b').binding, 'escape');
      expect(KeyEvent.fromSequence('\x7f').binding, 'backspace');
    });

    test('decodes terminal escape sequences', () {
      expect(KeyEvent.fromSequence('\x1b[A').binding, 'up');
      expect(KeyEvent.fromSequence('\x1b[B').binding, 'down');
      expect(KeyEvent.fromSequence('\x1b[Z').binding, 'shift+tab');
      expect(KeyEvent.fromSequence('\x1b[1;6A').binding, 'ctrl+shift+up');
      expect(KeyEvent.fromSequence('\x1b[3~').binding, 'delete');
      expect(KeyEvent.fromSequence('\x1bOP').binding, 'f1');
    });

    test('decodes meta modified keys', () {
      expect(KeyEvent.fromSequence('\x1ba').binding, 'meta+a');
      expect(KeyEvent.fromSequence('\x1b[').binding, 'meta+[');
      expect(KeyEvent.fromSequence('\x1bO').binding, 'meta+shift+o');
      expect(KeyEvent.fromSequence('\x1b\r').binding, 'meta+enter');
    });

    test('throws for unsupported sequences', () {
      expect(() => KeyEvent.fromSequence(''), throwsFormatException);
      expect(() => KeyEvent.fromSequence('ab'), throwsFormatException);
      expect(() => KeyEvent.fromSequence('\x1b[999x'), throwsFormatException);
      expect(() => KeyEvent.fromSequence('\x1b[1;9A'), throwsFormatException);
    });

    test('is a value object', () {
      const first = KeyEvent(sequence: '\x03', key: 'c', ctrl: true);
      const second = KeyEvent(sequence: '\x03', key: 'c', ctrl: true);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.toString(), contains('ctrl+c'));
    });
  });

  group('keypass dispatch', () {
    test('normalizes binding aliases', () {
      final keypass = Keypass();
      final events = <String>[];

      keypass.bind('Shift + Ctrl + ArrowUp', (event) {
        events.add(event.binding);
      });
      keypass.bind('alt + Enter', (event) {
        events.add(event.binding);
      });
      keypass.bind('spacebar', (event) {
        events.add(event.binding);
      });
      keypass.bind('ctrl++', (event) {
        events.add(event.binding);
      });
      keypass.bind('plus', (event) {
        events.add(event.binding);
      });

      expect(keypass.handleSequence('\x1b[1;6A'), isTrue);
      expect(keypass.handleSequence('\x1b\r'), isTrue);
      expect(keypass.handleSequence(' '), isTrue);
      expect(keypass.handleSequence('+'), isTrue);
      expect(
        keypass.dispatch(
          const KeyEvent(sequence: '+', key: 'plus', ctrl: true),
        ),
        isTrue,
      );

      expect(events, <String>[
        'ctrl+shift+up',
        'meta+enter',
        'space',
        'plus',
        'ctrl+plus',
      ]);
    });

    test('returns false for misses', () {
      final keypass = Keypass()..bind('ctrl+c', (_) {});

      expect(keypass.handleSequence('a'), isFalse);
      expect(
        keypass.dispatch(const KeyEvent(sequence: 'b', key: 'b')),
        isFalse,
      );
    });

    test('runs handlers in registration order', () {
      final keypass = Keypass();
      final calls = <int>[];

      keypass.bind('tab', (_) => calls.add(1));
      keypass.bind('tab', (_) => calls.add(2));

      expect(keypass.handleSequence('\t'), isTrue);
      expect(calls, <int>[1, 2]);
    });

    test('unbinds and clears bindings', () {
      final keypass = Keypass()
        ..bind('escape', (_) {})
        ..bind('tab', (_) {});

      expect(keypass.unbind('esc'), isTrue);
      expect(keypass.handleSequence('\x1b'), isFalse);
      expect(keypass.handleSequence('\t'), isTrue);

      keypass.clear();
      expect(keypass.handleSequence('\t'), isFalse);
    });

    test('allows handlers to mutate bindings during dispatch', () {
      final keypass = Keypass();
      final calls = <String>[];

      keypass.bind('a', (_) {
        calls.add('first');
        keypass.unbind('a');
      });
      keypass.bind('a', (_) => calls.add('second'));

      expect(keypass.handleSequence('a'), isTrue);
      expect(calls, <String>['first', 'second']);
      expect(keypass.handleSequence('a'), isFalse);
    });

    test('rejects invalid bindings', () {
      final keypass = Keypass();

      expect(() => keypass.bind('', (_) {}), throwsFormatException);
      expect(() => keypass.bind('ctrl+meta', (_) {}), throwsFormatException);
      expect(() => keypass.bind('ctrl+a+b', (_) {}), throwsFormatException);
      expect(() => keypass.bind('unknown-key', (_) {}), throwsFormatException);
      expect(() => keypass.bind('ctrl+', (_) {}), throwsFormatException);
    });
  });
}
