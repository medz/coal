import 'dart:async';

import 'package:coal/keypass.dart';
import 'package:test/test.dart';

void main() {
  group('key binding normalization', () {
    test('normalizes modifiers and aliases', () {
      expect(normalizeKeyBinding('Shift + Ctrl + A'), 'ctrl+shift+a');
      expect(normalizeKeyBinding('alt + Enter'), 'meta+enter');
      expect(normalizeKeyBinding('spacebar'), 'space');
      expect(normalizeKeyBinding('ArrowUp'), 'up');
    });

    test('throws for invalid bindings', () {
      expect(() => normalizeKeyBinding(''), throwsFormatException);
      expect(() => normalizeKeyBinding('ctrl+meta'), throwsFormatException);
      expect(
        () => normalizeKeyBinding('ctrl+a+b'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('key event decode', () {
    test('decodes control and printable keys', () {
      expect(KeyEvent.fromSequence('\u0003').binding, 'ctrl+c');
      expect(KeyEvent.fromSequence('A').binding, 'shift+a');
      expect(KeyEvent.fromSequence(' ').binding, 'space');
      expect(KeyEvent.fromSequence('+').binding, 'plus');
    });

    test('decodes ansi special keys', () {
      expect(KeyEvent.fromSequence('\u001b[A').binding, 'up');
      expect(KeyEvent.fromSequence('\u001b[1;6A').binding, 'ctrl+shift+up');
      expect(KeyEvent.fromSequence('\u001b[Z').binding, 'shift+tab');
      expect(KeyEvent.fromSequence('\u001bOP').binding, 'f1');
      expect(KeyEvent.fromSequence('\u001ba').binding, 'meta+a');
    });

    test('throws for unsupported multi-rune sequence', () {
      expect(
        () => KeyEvent.fromSequence('coal'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('keypass dispatch', () {
    test('binds and dispatches handlers', () {
      final triggered = <String>[];
      final keypass = Keypass();
      keypass.bind('ctrl+c', (event) => triggered.add(event.binding));
      keypass.bind('up', (event) => triggered.add(event.binding));

      expect(keypass.handleSequence('\u0003'), isTrue);
      expect(keypass.handleSequence('\u001b[A'), isTrue);
      expect(keypass.handleSequence('\u0004'), isFalse);
      expect(triggered, <String>['ctrl+c', 'up']);
    });

    test('supports replacing and removing handlers', () {
      final values = <int>[];
      final keypass = Keypass();

      void first(KeyEvent _) => values.add(1);
      void second(KeyEvent _) => values.add(2);

      keypass.bind('tab', first);
      keypass.bind('tab', second);
      keypass.handleSequence('\t');
      expect(values, <int>[1, 2]);

      keypass.bind('tab', second, replace: true);
      keypass.handleSequence('\t');
      expect(values, <int>[1, 2, 2]);

      expect(keypass.unbind('tab', second), isTrue);
      expect(keypass.isBound('tab'), isFalse);
      expect(keypass.handleSequence('\t'), isFalse);
    });

    test('dispatches from byte stream', () async {
      final events = <String>[];
      final keypass = Keypass();
      keypass.bind('ctrl+c', (event) => events.add(event.binding));
      keypass.bind('a', (event) => events.add(event.binding));
      keypass.bind('b', (event) => events.add(event.binding));

      final controller = StreamController<List<int>>();
      final subscription = keypass.listenBytes(controller.stream);
      final done = subscription.asFuture<void>();

      controller
        ..add(<int>[3])
        ..add('ab'.codeUnits);
      await controller.close();
      await done;

      expect(events, <String>['ctrl+c', 'a', 'b']);
    });
  });
}
