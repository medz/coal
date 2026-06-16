import 'dart:convert';

import 'package:coal/keypass.dart';
import 'package:test/test.dart';

void main() {
  group('key binding normalization', () {
    test('normalizes modifiers and aliases', () {
      expect(normalizeKeyBinding('Shift + Ctrl + A'), 'ctrl+shift+a');
      expect(normalizeKeyBinding('alt + Enter'), 'meta+enter');
      expect(normalizeKeyBinding('spacebar'), 'space');
      expect(normalizeKeyBinding('ArrowUp'), 'up');
      expect(normalizeKeyBinding('cmd + pgdown'), 'meta+pagedown');
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

  group('key sequence decoder', () {
    test('decodes text separately from control keys', () {
      expect(KeyDecoder.decodeSequence('coal'), const TextInput('coal'));
      expect(KeyDecoder.decodeSequence('\u0003'), KeyEvent('c', ctrl: true));
      expect(KeyDecoder.decodeSequence('\t'), KeyEvent('tab'));
      expect(KeyDecoder.decodeSequence('\r'), KeyEvent('enter'));
      expect(KeyDecoder.decodeSequence('\u007f'), KeyEvent('backspace'));
    });

    test('decodes ansi keys and modifiers', () {
      expect(KeyDecoder.decodeSequence('\u001b[A'), KeyEvent('up'));
      expect(
        KeyDecoder.decodeSequence('\u001b[1;6A'),
        KeyEvent('up', ctrl: true, shift: true),
      );
      expect(
        KeyDecoder.decodeSequence('\u001b[Z'),
        KeyEvent('tab', shift: true),
      );
      expect(KeyDecoder.decodeSequence('\u001b[3~'), KeyEvent('delete'));
      expect(KeyDecoder.decodeSequence('\u001bOP'), KeyEvent('f1'));
      expect(KeyDecoder.decodeSequence('\u001ba'), KeyEvent('a', meta: true));
    });
  });

  group('key parser', () {
    test('buffers partial escape sequences', () {
      final parser = KeyParser();

      expect(parser.addString('\u001b['), isEmpty);
      expect(parser.addString('A'), <KeyInput>[KeyEvent('up')]);
    });

    test('splits compound escape and text chunks', () {
      final parser = KeyParser();

      expect(parser.addString('\u001b[Aa'), <KeyInput>[
        KeyEvent('up'),
        const TextInput('a'),
      ]);
    });

    test('streams split utf8 text bytes', () {
      final parser = KeyParser();
      final bytes = utf8.encode('你a');

      expect(parser.addBytes(bytes.sublist(0, 1)), isEmpty);
      expect(parser.addBytes(bytes.sublist(1, 2)), isEmpty);
      expect(parser.addBytes(bytes.sublist(2)), <KeyInput>[
        const TextInput('你a'),
      ]);
    });

    test('flushes a pending escape key', () {
      final parser = KeyParser();

      expect(parser.addString('\u001b'), isEmpty);
      expect(parser.flush(), <KeyInput>[KeyEvent('escape')]);
    });
  });

  group('key dispatcher', () {
    test('binds and dispatches handlers', () {
      final triggered = <String>[];
      final dispatcher = KeyDispatcher()
        ..bind('ctrl+c', (event) => triggered.add(event.binding))
        ..bind('shift+up', (event) => triggered.add(event.binding));

      expect(dispatcher.dispatch(KeyEvent('c', ctrl: true)), isTrue);
      expect(dispatcher.dispatch(KeyEvent('up', shift: true)), isTrue);
      expect(dispatcher.dispatch(KeyEvent('down')), isFalse);
      expect(triggered, <String>['ctrl+c', 'shift+up']);
    });

    test('replaces and removes handlers', () {
      final values = <int>[];
      final dispatcher = KeyDispatcher();

      void first(KeyEvent _) => values.add(1);
      void second(KeyEvent _) => values.add(2);

      dispatcher
        ..bind('tab', first)
        ..bind('tab', second)
        ..dispatch(KeyEvent('tab'));
      expect(values, <int>[1, 2]);

      dispatcher
        ..bind('tab', second, replace: true)
        ..dispatch(KeyEvent('tab'));
      expect(values, <int>[1, 2, 2]);

      expect(dispatcher.unbind('tab', second), isTrue);
      expect(dispatcher.isBound('tab'), isFalse);
    });
  });

  group('keypass facade', () {
    test('dispatches parsed key events and returns all inputs', () {
      final triggered = <String>[];
      final keypass = Keypass()
        ..bind('ctrl+c', (event) => triggered.add(event.binding))
        ..bind('up', (event) => triggered.add(event.binding));

      final inputs = keypass.addString('\u0003\u001b[Aok');

      expect(inputs, <KeyInput>[
        KeyEvent('c', ctrl: true),
        KeyEvent('up'),
        const TextInput('ok'),
      ]);
      expect(triggered, <String>['ctrl+c', 'up']);
    });
  });
}
